defmodule JidoCartographer.Extractor do
  alias JidoCartographer.Languages

  def extract(path, content) do
    language = Languages.detect(path)

    %{
      path: path,
      language: language,
      lines: line_count(content),
      bytes: byte_size(content),
      imports: imports(language, content),
      symbols: symbols(language, content)
    }
  end

  defp line_count(""), do: 0
  defp line_count(content), do: length(:binary.split(content, "\n", [:global]))

  defp imports("Elixir", content),
    do: captures(content, ~r/^\s*(?:alias|import|require|use)\s+([A-Z][A-Za-z0-9_.]*)/m)

  defp imports("Erlang", content),
    do: captures(content, ~r/^-include(?:_lib)?\("([^"]+)"\)\.|^-behaviour\(([^)]+)\)\./m)

  defp imports(language, content) when language in ["TypeScript", "JavaScript"] do
    captures(content, ~r/(?:import\s+(?:[^"']+?\s+from\s+)?|require\s*\()?["']([^"']+)["']/m)
  end

  defp imports("Python", content),
    do: captures(content, ~r/^\s*(?:from\s+([A-Za-z0-9_.]+)\s+import|import\s+([A-Za-z0-9_.]+))/m)

  defp imports("Ruby", content),
    do: captures(content, ~r/^\s*require(?:_relative)?\s+["']([^"']+)["']/m)

  defp imports("Go", content), do: captures(content, ~r/^\s*"([^"]+)"\s*$/m)
  defp imports("Rust", content), do: captures(content, ~r/^\s*(?:use|mod)\s+([A-Za-z0-9_:]+)/m)

  defp imports(language, content) when language in ["Java", "Kotlin"],
    do: captures(content, ~r/^\s*import\s+([A-Za-z0-9_.*]+)/m)

  defp imports("Swift", content), do: captures(content, ~r/^\s*import\s+([A-Za-z0-9_.]+)/m)

  defp imports(language, content) when language in ["C", "C++"],
    do: captures(content, ~r/^\s*#include\s*[<"]([^>"]+)[>"]/m)

  defp imports(_, _), do: []

  defp symbols("Elixir", content),
    do:
      captures(
        content,
        ~r/^\s*def(?:module|protocol|impl|struct|exception|macro|p)?\s+([A-Za-z_][A-Za-z0-9_!?\.]*)/m
      )

  defp symbols("Erlang", content),
    do: captures(content, ~r/^-module\(([^)]+)\)\.|^([a-z][A-Za-z0-9_]*)\s*\(/m)

  defp symbols(language, content) when language in ["TypeScript", "JavaScript"] do
    captures(
      content,
      ~r/^\s*(?:export\s+)?(?:default\s+)?(?:async\s+)?(?:class|function|const|let|var|interface|type|enum)\s+([A-Za-z_$][A-Za-z0-9_$]*)/m
    )
  end

  defp symbols("Python", content),
    do: captures(content, ~r/^\s*(?:async\s+)?(?:def|class)\s+([A-Za-z_][A-Za-z0-9_]*)/m)

  defp symbols("Ruby", content),
    do: captures(content, ~r/^\s*(?:class|module|def)\s+(?:self\.)?([A-Za-z_][A-Za-z0-9_!?=]*)/m)

  defp symbols("Go", content),
    do:
      captures(
        content,
        ~r/^\s*(?:func|type|var|const)\s+(?:\([^)]*\)\s*)?([A-Za-z_][A-Za-z0-9_]*)/m
      )

  defp symbols("Rust", content),
    do:
      captures(
        content,
        ~r/^\s*(?:pub\s+)?(?:async\s+)?(?:fn|struct|enum|trait|type|const|static|mod)\s+([A-Za-z_][A-Za-z0-9_]*)/m
      )

  defp symbols(language, content) when language in ["Java", "Kotlin", "Swift", "C#"] do
    captures(
      content,
      ~r/^\s*(?:public\s+|private\s+|internal\s+|protected\s+|open\s+|final\s+)*(?:class|interface|enum|struct|protocol|func|fun|record)\s+([A-Za-z_][A-Za-z0-9_]*)/m
    )
  end

  defp symbols(_, _), do: []

  defp captures(content, regex) do
    Regex.scan(regex, content, capture: :all_but_first)
    |> Enum.flat_map(fn groups -> Enum.reject(groups, &(&1 in [nil, ""])) end)
    |> Enum.map(&String.trim/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
