defmodule JidoCartographer.Languages do
  @languages %{
    ".ex" => "Elixir",
    ".exs" => "Elixir",
    ".erl" => "Erlang",
    ".hrl" => "Erlang",
    ".ts" => "TypeScript",
    ".tsx" => "TypeScript",
    ".js" => "JavaScript",
    ".jsx" => "JavaScript",
    ".mjs" => "JavaScript",
    ".cjs" => "JavaScript",
    ".py" => "Python",
    ".rb" => "Ruby",
    ".go" => "Go",
    ".rs" => "Rust",
    ".java" => "Java",
    ".kt" => "Kotlin",
    ".kts" => "Kotlin",
    ".swift" => "Swift",
    ".c" => "C",
    ".h" => "C",
    ".cc" => "C++",
    ".cpp" => "C++",
    ".hpp" => "C++",
    ".cs" => "C#",
    ".sh" => "Shell",
    ".bash" => "Shell",
    ".zsh" => "Shell"
  }

  def detect(path), do: Map.get(@languages, Path.extname(path) |> String.downcase())
  def supported?(path), do: detect(path) != nil
end
