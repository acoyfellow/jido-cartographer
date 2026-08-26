import Config

config :jido_cartographer, JidoCartographer.Jido,
  max_tasks: 2_500,
  agent_pools: []

config :jido_cartographer,
  port: String.to_integer(System.get_env("PORT", "8080")),
  start_server: true

import_config "#{config_env()}.exs"
