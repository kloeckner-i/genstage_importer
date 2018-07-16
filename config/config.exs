# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :genstage_importer,
  ecto_repos: [GenstageImporter.Repo]

# Configures the endpoint
config :genstage_importer, GenstageImporterWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "UdsAyKuKYnKTQuLE1IN2vnAMNGArYoMkBIiiM9PsVHI1qt/LimFn7vAaefBEdOVW",
  render_errors: [view: GenstageImporterWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: GenstageImporter.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
