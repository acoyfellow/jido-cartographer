[url, ref] = Enum.reject(System.argv(), &(&1 == "--"))

case JidoCartographer.Indexer.index(url, ref) do
  {:ok, result} ->
    receipt = %{
      measured_at: DateTime.utc_now(),
      elixir: System.version(),
      otp: System.otp_release(),
      architecture: :erlang.system_info(:system_architecture) |> List.to_string(),
      schedulers: System.schedulers_online(),
      repository: result.repository,
      summary: result.summary,
      timing: result.timing
    }

    IO.puts(Jason.encode!(receipt, pretty: true))

  {:error, reason} ->
    IO.puts(:stderr, reason)
    System.halt(1)
end
