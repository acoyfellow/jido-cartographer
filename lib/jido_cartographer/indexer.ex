defmodule JidoCartographer.Indexer do
  alias JidoCartographer.{FileAgent, Limits, Repository, Snapshot}

  def index(url, ref \\ nil, opts \\ []) do
    started = System.monotonic_time(:microsecond)
    snapshotter = Keyword.get(opts, :snapshotter, &Snapshot.fetch/2)

    with {:ok, repository} <- Repository.parse(url, ref),
         fetch_started <- System.monotonic_time(:microsecond),
         {:ok, files, snapshot_stats} <- snapshotter.(repository, opts),
         fetch_finished <- System.monotonic_time(:microsecond),
         {:ok, facts, analysis_us, concurrency} <- analyze(files, opts) do
      finished = System.monotonic_time(:microsecond)
      edges = edges(facts)

      {:ok,
       %{
         repository: repository,
         summary: summary(facts, edges),
         files: facts,
         edges: edges,
         errors: [],
         timing: %{
           agents_spawned: length(files),
           concurrency: concurrency,
           fetch_ms: elapsed_ms(fetch_started, fetch_finished),
           analysis_ms: div(analysis_us, 1_000),
           total_ms: elapsed_ms(started, finished),
           source_bytes: snapshot_stats.source_bytes,
           skipped_entries: snapshot_stats.skipped_entries
         }
       }}
    end
  end

  def index_with_timeout(url, ref, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, Limits.index_timeout_ms())
    task = Task.async(fn -> index(url, ref, opts) end)

    case Task.yield(task, timeout_ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      nil -> {:error, "indexing exceeded #{timeout_ms} ms"}
    end
  end

  def analyze(files, opts \\ []) do
    concurrency =
      opts
      |> Keyword.get(:concurrency, System.schedulers_online() * 8)
      |> min(Limits.max_concurrency())
      |> max(1)

    started = System.monotonic_time(:microsecond)

    results =
      Task.async_stream(files, fn {path, content} -> FileAgent.analyze(path, content) end,
        ordered: false,
        max_concurrency: concurrency,
        timeout: Limits.index_timeout_ms(),
        on_timeout: :kill_task
      )
      |> Enum.to_list()

    case Enum.find(results, fn result -> not match?({:ok, _}, result) end) do
      nil ->
        facts = results |> Enum.map(fn {:ok, fact} -> fact end) |> Enum.sort_by(& &1.path)

        {:ok, facts, System.monotonic_time(:microsecond) - started,
         min(concurrency, max(length(files), 1))}

      failure ->
        {:error, "file agent failed: #{inspect(failure)}"}
    end
  end

  defp edges(facts) do
    facts
    |> Enum.flat_map(fn fact -> Enum.map(fact.imports, &%{from: fact.path, to: &1}) end)
    |> Enum.sort_by(&{&1.from, &1.to})
  end

  defp summary(facts, edges) do
    languages =
      facts
      |> Enum.group_by(& &1.language)
      |> Enum.map(fn {language, items} ->
        %{
          language: language,
          files: length(items),
          lines: Enum.sum(Enum.map(items, & &1.lines)),
          bytes: Enum.sum(Enum.map(items, & &1.bytes))
        }
      end)
      |> Enum.sort_by(&{-&1.files, &1.language})

    %{
      files: length(facts),
      lines: Enum.sum(Enum.map(facts, & &1.lines)),
      bytes: Enum.sum(Enum.map(facts, & &1.bytes)),
      symbols: Enum.sum(Enum.map(facts, &length(&1.symbols))),
      dependencies: length(edges),
      languages: languages
    }
  end

  defp elapsed_ms(started, finished), do: div(finished - started, 1_000)
end
