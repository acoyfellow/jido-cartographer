defmodule JidoCartographer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JidoCartographer.Jido,
      JidoCartographer.ResultStore,
      {Task.Supervisor, name: JidoCartographer.JobSupervisor}
    ]

    children =
      if Application.fetch_env!(:jido_cartographer, :start_server) do
        children ++
          [
            {Bandit,
             plug: JidoCartographer.API,
             scheme: :http,
             port: Application.fetch_env!(:jido_cartographer, :port)}
          ]
      else
        children
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: JidoCartographer.Supervisor)
  end
end
