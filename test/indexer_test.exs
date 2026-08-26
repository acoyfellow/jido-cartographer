defmodule JidoCartographer.IndexerTest do
  use ExUnit.Case, async: true

  alias JidoCartographer.Indexer

  test "runs one Jido file agent per source file and aggregates deterministically" do
    files =
      for i <- 1..100 do
        {"lib/module_#{i}.ex", "defmodule Module#{i} do\n  alias Shared.Store\nend\n"}
      end

    assert {:ok, facts, elapsed_us, concurrency} = Indexer.analyze(files, concurrency: 32)
    assert length(facts) == 100
    assert concurrency == 32
    assert elapsed_us > 0
    assert hd(facts).path == "lib/module_1.ex"
    assert Enum.all?(facts, &(length(&1.symbols) == 1))
    assert Enum.all?(facts, &(&1.imports == ["Shared.Store"]))
  end

  test "stops an index that exceeds its total timeout" do
    snapshotter = fn _repository, _opts ->
      Process.sleep(50)
      {:ok, [], %{source_bytes: 0, skipped_entries: 0}}
    end

    assert {:error, message} =
             Indexer.index_with_timeout("https://github.com/example/project", "main",
               snapshotter: snapshotter,
               timeout_ms: 10
             )

    assert message =~ "exceeded 10 ms"
  end

  test "indexes a supplied bounded snapshot and reports measured agent metrics" do
    files = [
      {"lib/a.ex", "defmodule A, do: nil\n"},
      {"src/b.js", "import './a.js'\nexport function b() {}\n"}
    ]

    snapshotter = fn _repository, _opts ->
      {:ok, files,
       %{source_bytes: Enum.sum(Enum.map(files, &byte_size(elem(&1, 1)))), skipped_entries: 0}}
    end

    assert {:ok, result} =
             Indexer.index("https://github.com/example/project", "main",
               snapshotter: snapshotter,
               concurrency: 8
             )

    assert result.summary.files == 2
    assert result.summary.symbols == 2
    assert result.timing.agents_spawned == 2
    assert result.timing.concurrency == 2
    assert length(result.edges) == 1
  end
end
