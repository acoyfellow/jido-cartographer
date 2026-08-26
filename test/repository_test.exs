defmodule JidoCartographer.RepositoryTest do
  use ExUnit.Case, async: true

  alias JidoCartographer.Repository

  test "accepts a public GitHub repository and safe ref" do
    assert {:ok, repo} = Repository.parse("https://github.com/elixir-lang/elixir.git", "v1.20.3")
    assert repo.owner == "elixir-lang"
    assert repo.repo == "elixir"
    assert repo.ref == "v1.20.3"

    assert Repository.archive_url(repo) ==
             "https://codeload.github.com/elixir-lang/elixir/tar.gz/v1.20.3"
  end

  test "rejects credentials, non-GitHub hosts, local URLs, extra paths, and unsafe refs" do
    invalid = [
      "http://github.com/a/b",
      "https://token@github.com/a/b",
      "https://github.example/a/b",
      "https://127.0.0.1/a/b",
      "https://github.com/a/b/issues",
      "https://github.com/a/b?token=x"
    ]

    for url <- invalid do
      assert {:error, _} = Repository.parse(url)
    end

    assert {:error, _} = Repository.parse("https://github.com/a/b", "../../main")
    assert {:error, _} = Repository.parse("https://github.com/a/b", "/main")
  end
end
