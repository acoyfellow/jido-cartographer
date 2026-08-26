defmodule JidoCartographer.MixProject do
  use Mix.Project

  def project do
    [
      app: :jido_cartographer,
      version: "0.1.0",
      elixir: ">= 1.18.4",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl],
      mod: {JidoCartographer.Application, []}
    ]
  end

  defp deps do
    [
      {:jido, "~> 2.3"},
      {:bandit, "~> 1.8"},
      {:plug, "~> 1.18"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
