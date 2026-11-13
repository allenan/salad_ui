defmodule SaladChat.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TwMerge.Cache,
      SaladChatWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:salad_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SaladChat.PubSub},
      SaladChatWeb.Presence,
      # In-memory chat data, seeded on boot
      SaladChat.Chat.Store,
      # Sprout, the AI assistant: reminders plus one responder per reply
      SaladChat.Sprout,
      {DynamicSupervisor, name: SaladChat.Sprout.Supervisor, strategy: :one_for_one},
      # Simulated people chatting, so the demo is alive (off in test)
      SaladChat.Activity,
      # Start to serve requests, typically the last entry
      SaladChatWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SaladChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SaladChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
