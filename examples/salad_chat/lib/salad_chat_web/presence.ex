defmodule SaladChatWeb.Presence do
  @moduledoc """
  Tracks who is online. Each connected chat LiveView tracks its user under
  the `"online"` topic, keyed by handle.
  """
  use Phoenix.Presence,
    otp_app: :salad_chat,
    pubsub_server: SaladChat.PubSub

  @topic "online"

  def topic, do: @topic

  def track_user(pid, handle) do
    track(pid, @topic, handle, %{online_at: System.system_time(:second)})
  end

  @doc "The set of handles with at least one open tab."
  def online_handles do
    @topic |> list() |> Map.keys() |> MapSet.new()
  end
end
