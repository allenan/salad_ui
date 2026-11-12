defmodule SaladStorybookWeb.ToastPromiseButton do
  @moduledoc """
  The "Promise" button from shadcn's `sonner-types` example, server-side.

  Sonner's `toast.promise` takes a JS promise; in LiveView the equivalent is
  `SaladUI.Toast.toast_promise/3` plus `start_async/3`, resolved from
  `handle_async/3` with `SaladUI.Toast.toast_resolve/4`. One card morphs from
  loading to success (or error).
  """
  use SaladStorybookWeb, :live_component

  import SaladUI.Button
  import SaladUI.Toast

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.button variant="outline" phx-click="promise" phx-target={@myself}>Promise</.button>
    </div>
    """
  end

  @impl true
  def handle_event("promise", _params, socket) do
    # No :id given, so toast_promise/3 generates one and assigns it as :toast_id.
    socket = toast_promise(socket, loading: "Loading...", toaster: socket.assigns.toaster)
    toast_id = socket.assigns.toast_id

    {:noreply,
     start_async(socket, {:promise, toast_id}, fn ->
       Process.sleep(2000)
       %{name: "Event"}
     end)}
  end

  @impl true
  def handle_async({:promise, toast_id}, result, socket) do
    {:noreply,
     toast_resolve(socket, toast_id, result,
       success: fn data -> "#{data.name} has been created" end,
       error: "Error",
       toaster: socket.assigns.toaster
     )}
  end
end
