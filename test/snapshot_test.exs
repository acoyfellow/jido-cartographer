defmodule JidoCartographer.SnapshotTest do
  use ExUnit.Case, async: true

  alias JidoCartographer.{Limits, Snapshot}

  test "keeps bounded source files and skips binaries, vendors, builds, and unsupported files" do
    entries = [
      {~c"repo-main/lib/a.ex", "defmodule A, do: nil\n"},
      {~c"repo-main/src/b.ts", "export const b = 1\n"},
      {~c"repo-main/node_modules/x.js", "export const x = 1\n"},
      {~c"repo-main/dist/y.js", "export const y = 1\n"},
      {~c"repo-main/image.js", <<0, 1, 2>>},
      {~c"repo-main/README.md", "text"},
      {~c"repo-main/large.py", String.duplicate("x", Limits.file_bytes() + 1)}
    ]

    assert {:ok, files, stats} = Snapshot.select(entries)
    assert Enum.map(files, &elem(&1, 0)) == ["lib/a.ex", "src/b.ts"]

    assert stats.source_bytes ==
             byte_size(elem(hd(files), 1)) + byte_size(elem(List.last(files), 1))

    assert stats.skipped_entries == 5
  end

  test "rejects an archive over the compressed byte limit before extraction" do
    repository = %{owner: "a", repo: "b", ref: "HEAD"}
    fetcher = fn _ -> {:ok, :binary.copy(<<0>>, Limits.archive_bytes() + 1)} end
    assert {:error, message} = Snapshot.fetch(repository, fetcher: fetcher)
    assert message =~ "archive exceeds"
  end

  test "rejects more than the supported source file count" do
    entries = for i <- 1..(Limits.max_files() + 1), do: {~c"repo/lib/#{i}.ex", "x"}
    assert {:error, message} = Snapshot.select(entries)
    assert message =~ "supported files"
  end

  test "preflights expanded bytes before extracting file contents" do
    table = [{~c"large.dat", :regular, Limits.expanded_bytes() + 1, 0, 0, 0, 0}]
    assert {:error, "archive exceeds expanded byte limit"} = Snapshot.preflight(table)
  end

  test "preflights the total archive entry count" do
    table =
      for i <- 1..(Limits.max_archive_entries() + 1),
          do: {~c"#{i}.txt", :regular, 0, 0, 0, 0, 0}

    assert {:error, message} = Snapshot.preflight(table)
    assert message =~ "entries"
  end
end
