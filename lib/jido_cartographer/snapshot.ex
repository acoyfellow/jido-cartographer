defmodule JidoCartographer.Snapshot do
  alias JidoCartographer.{Languages, Limits, Repository}

  @skipped_segments MapSet.new(
                      ~w(.git .github node_modules deps vendor _build build dist target coverage .next .cache __pycache__ venv .venv fixtures testdata)
                    )

  def fetch(repository, opts \\ []) do
    fetcher = Keyword.get(opts, :fetcher, &download/1)

    with {:ok, archive} <- fetcher.(Repository.archive_url(repository)),
         :ok <- ensure_archive_limit(archive),
         {:ok, entries} <- extract(archive),
         {:ok, files, stats} <- select(entries) do
      {:ok, files, stats}
    end
  end

  def select(entries) when is_list(entries) do
    entries
    |> Enum.reduce_while({[], 0, 0}, fn entry, {files, bytes, skipped} ->
      case normalize_entry(entry) do
        {:ok, path, content} ->
          next_bytes = bytes + byte_size(content)
          next_count = length(files) + 1

          cond do
            next_count > Limits.max_files() ->
              {:halt, {:error, "repository exceeds #{Limits.max_files()} supported files"}}

            next_bytes > Limits.expanded_bytes() ->
              {:halt, {:error, "repository exceeds expanded source byte limit"}}

            true ->
              {:cont, {[{path, content} | files], next_bytes, skipped}}
          end

        :skip ->
          {:cont, {files, bytes, skipped + 1}}
      end
    end)
    |> case do
      {:error, reason} ->
        {:error, reason}

      {files, bytes, skipped} ->
        {:ok, Enum.sort_by(files, &elem(&1, 0)), %{source_bytes: bytes, skipped_entries: skipped}}
    end
  end

  defp download(url) do
    into = fn {:data, data}, {request, response} ->
      size = Map.get(response.private, :jido_cartographer_bytes, 0) + byte_size(data)
      chunks = [data | Map.get(response.private, :jido_cartographer_chunks, [])]

      private =
        response.private
        |> Map.put(:jido_cartographer_bytes, size)
        |> Map.put(:jido_cartographer_chunks, chunks)

      response = %{response | private: private}

      if size > Limits.archive_bytes() do
        {:halt,
         {request, %{response | private: Map.put(private, :jido_cartographer_exceeded, true)}}}
      else
        {:cont, {request, response}}
      end
    end

    case Req.get(url,
           into: into,
           redirect: false,
           receive_timeout: Limits.fetch_timeout_ms(),
           connect_options: [timeout: 5_000],
           headers: [{"user-agent", "jido-cartographer/0.1"}]
         ) do
      {:ok, %{status: 200, private: private}} ->
        if private[:jido_cartographer_exceeded] do
          {:error, "archive exceeds #{Limits.archive_bytes()} bytes"}
        else
          {:ok, private[:jido_cartographer_chunks] |> Enum.reverse() |> IO.iodata_to_binary()}
        end

      {:ok, %{status: status}} ->
        {:error, "GitHub archive request returned HTTP #{status}"}

      {:error, error} ->
        {:error, "GitHub archive request failed: #{Exception.message(error)}"}
    end
  end

  defp ensure_archive_limit(archive) do
    if byte_size(archive) <= Limits.archive_bytes() do
      :ok
    else
      {:error, "archive exceeds #{Limits.archive_bytes()} bytes"}
    end
  end

  defp extract(archive) do
    with {:ok, table} <- :erl_tar.table({:binary, archive}, [:compressed, :verbose]),
         :ok <- preflight(table),
         {:ok, entries} <- :erl_tar.extract({:binary, archive}, [:compressed, :memory]) do
      {:ok, entries}
    else
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, reason} -> {:error, "invalid repository archive: #{inspect(reason)}"}
    end
  end

  def preflight(table) do
    regular_entries = Enum.filter(table, &(elem(&1, 1) == :regular))
    expanded_bytes = Enum.sum(Enum.map(regular_entries, &elem(&1, 2)))

    cond do
      length(regular_entries) > Limits.max_archive_entries() ->
        {:error, "archive exceeds #{Limits.max_archive_entries()} entries"}

      expanded_bytes > Limits.expanded_bytes() ->
        {:error, "archive exceeds expanded byte limit"}

      true ->
        :ok
    end
  end

  defp normalize_entry({name, content}) when is_list(name) and is_binary(content) do
    parts = name |> List.to_string() |> String.split("/", trim: true)

    with [_root | relative] when relative != [] <- parts,
         false <- Enum.any?(relative, &MapSet.member?(@skipped_segments, &1)),
         path <- Enum.join(relative, "/"),
         true <- safe_path?(relative),
         true <- Languages.supported?(path),
         true <- byte_size(content) <= Limits.file_bytes(),
         true <- String.valid?(content),
         false <- binary?(content) do
      {:ok, path, content}
    else
      _ -> :skip
    end
  end

  defp normalize_entry(_), do: :skip
  defp safe_path?(parts), do: Enum.all?(parts, &(&1 not in ["", ".", ".."]))
  defp binary?(content), do: :binary.match(content, <<0>>) != :nomatch
end
