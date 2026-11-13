defmodule SaladChatWeb.Layouts do
  @moduledoc """
  The root layout (`layouts/root.html.heex`) and the app layout every
  LiveView renders inside.
  """
  use SaladChatWeb, :html

  embed_templates "layouts/*"

  @doc """
  Wraps a page and mounts the SaladUI toaster. Flash messages are bridged into
  toasts by `toaster/1`'s `flash` attribute.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    {render_slot(@inner_block)}
    <.toaster
      id="toaster"
      flash={@flash}
      position="bottom-right"
      colors={%{error: "border-destructive/40 text-destructive"}}
    />
    """
  end
end
