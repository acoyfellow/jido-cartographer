defmodule JidoCartographer.ExtractorTest do
  use ExUnit.Case, async: true

  alias JidoCartographer.Extractor

  test "extracts deterministic Elixir facts" do
    source = """
    defmodule Demo.Worker do
      use GenServer
      alias Demo.Store
      def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
      defp hidden, do: :ok
    end
    """

    fact = Extractor.extract("lib/demo/worker.ex", source)
    assert fact.language == "Elixir"
    assert fact.bytes == byte_size(source)
    assert fact.lines == 7
    assert fact.imports == ["Demo.Store", "GenServer"]
    assert fact.symbols == ["Demo.Worker", "hidden", "start_link"]
  end

  test "extracts JavaScript imports and exports" do
    source = "import { x } from './x.js'\nexport function run() {}\nexport const answer = 42\n"
    fact = Extractor.extract("src/main.js", source)
    assert fact.imports == ["./x.js"]
    assert fact.symbols == ["answer", "run"]
  end
end
