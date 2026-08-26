defmodule JidoCartographer do
  defdelegate index(url, ref \\ nil), to: JidoCartographer.Indexer
end
