defmodule SaladChatWeb.Paths do
  @moduledoc "Paths into the chat. The current identity is part of every path."
  use SaladChatWeb, :verified_routes

  def channel_path(handle, channel_id), do: ~p"/as/#{handle}/c/#{channel_id}"

  def thread_path(handle, channel_id, message_id),
    do: ~p"/as/#{handle}/c/#{channel_id}/t/#{message_id}"
end
