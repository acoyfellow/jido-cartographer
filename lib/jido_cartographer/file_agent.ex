defmodule JidoCartographer.AnalyzeFileAction do
  use Jido.Action,
    name: "analyze_file",
    description: "Extract deterministic facts from one source file",
    schema: [
      path: [type: :string, required: true],
      content: [type: :string, required: true]
    ]

  def run(params, _context) do
    {:ok, %{fact: JidoCartographer.Extractor.extract(params.path, params.content)}}
  end
end

defmodule JidoCartographer.FileAgent do
  use Jido.Agent,
    name: "source_file_cartographer",
    description: "Maps one source file without an LLM",
    schema: [fact: [type: :map, default: %{}]]

  def analyze(path, content) do
    agent = new()

    {agent, []} =
      cmd(agent, {JidoCartographer.AnalyzeFileAction, %{path: path, content: content}})

    agent.state.fact
  end
end
