# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :salad_chat,
  generators: [timestamp_type: :utc_datetime]

# Simulated activity: seeded people post, react, reply and DM on their own.
# Disable at runtime with SALAD_CHAT_ACTIVITY=off (see runtime.exs).
config :salad_chat, SaladChat.Activity,
  enabled: true,
  # random pause between actions, and how long "typing…" shows first
  interval_ms: {6_000, 20_000},
  typing_ms: {1_500, 3_000},
  weights: [post: 50, react: 25, reply: 18, dm: 7],
  # simulated messages kept per conversation before the oldest are deleted
  max_per_channel: 200

# Configure the endpoint
config :salad_chat, SaladChatWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SaladChatWeb.ErrorHTML, json: SaladChatWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SaladChat.PubSub,
  live_view: [signing_salt: "8+R4quf7"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  salad_chat: [
    # salad_ui is a path dependency (the repo root); point esbuild straight at
    # its JS so the bundle doesn't depend on NODE_PATH or the checkout's name.
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.) ++
        ["--alias:salad_ui=#{Path.expand("../../../assets/salad_ui", __DIR__)}"],
    cd: Path.expand("../assets", __DIR__),
    env: %{
      "NODE_PATH" => [
        Path.expand("../deps", __DIR__),
        Path.expand("../assets/node_modules", __DIR__),
        Mix.Project.build_path()
      ]
    }
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.3",
  salad_chat: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
