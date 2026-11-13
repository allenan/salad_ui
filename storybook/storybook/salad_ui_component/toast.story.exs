defmodule Storybook.SaladUIComponents.Toast do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Button
  alias SaladUI.Toast

  def function, do: &Toast.toaster/1

  def imports, do: [{Button, [button: 1]}]

  def variations do
    [
      %Variation{
        id: :demo,
        description:
          "Toasts are pushed from the server with `SaladUI.Toast.toast/3`, or client-side with a " <>
            "`SaladUI.JS.dispatch_command/2` \"add\" command as here (no round trip).",
        template: """
        <.toaster id="toaster-demo" />
        <.button
          variant="outline"
          phx-click={
            SaladUI.JS.dispatch_command("add",
              to: "#toaster-demo",
              detail: %{
                title: "Event has been created",
                description: "Sunday, December 03, 2023 at 9:00 AM",
                action: %{label: "Undo"}
              }
            )
          }
        >
          Show Toast
        </.button>
        """
      },
      %Variation{
        id: :types,
        description:
          "Default, success, info, warning and error toasts, plus a promise toast: " <>
            "`toast_promise/3` shows a loading toast and `toast_resolve/4` (from `handle_async/3`) morphs " <>
            "the same card into success after 2s. See `SaladStorybookWeb.ToastPromiseButton`.",
        template: """
        <.toaster id="toaster-types" />
        <div class="flex flex-wrap gap-2">
          <.button
            variant="outline"
            phx-click={
              SaladUI.JS.dispatch_command("add",
                to: "#toaster-types",
                detail: %{title: "Event has been created"}
              )
            }
          >
            Default
          </.button>
          <.button
            variant="outline"
            phx-click={
              SaladUI.JS.dispatch_command("add",
                to: "#toaster-types",
                detail: %{variant: "success", title: "Event has been created"}
              )
            }
          >
            Success
          </.button>
          <.button
            variant="outline"
            phx-click={
              SaladUI.JS.dispatch_command("add",
                to: "#toaster-types",
                detail: %{variant: "info", title: "Be at the area 10 minutes before the event time"}
              )
            }
          >
            Info
          </.button>
          <.button
            variant="outline"
            phx-click={
              SaladUI.JS.dispatch_command("add",
                to: "#toaster-types",
                detail: %{variant: "warning", title: "Event start time cannot be earlier than 8am"}
              )
            }
          >
            Warning
          </.button>
          <.button
            variant="outline"
            phx-click={
              SaladUI.JS.dispatch_command("add",
                to: "#toaster-types",
                detail: %{variant: "error", title: "Event has not been created"}
              )
            }
          >
            Error
          </.button>
          <.live_component
            module={SaladStorybookWeb.ToastPromiseButton}
            id="toast-types-promise"
            toaster="toaster-types"
          />
        </div>
        """
      },
      %Variation{
        id: :description,
        template: """
        <.toaster id="toaster-description" />
        <.button
          variant="outline"
          class="w-fit"
          phx-click={
            SaladUI.JS.dispatch_command("add",
              to: "#toaster-description",
              detail: %{title: "Event has been created", description: "Monday, January 3rd at 6:00pm"}
            )
          }
        >
          Show Toast
        </.button>
        """
      },
      %Variation{
        id: :position,
        description:
          "Pass `position` per toast (or set it on the `<.toaster>`): " <>
            "top-left, top-center, top-right, bottom-left, bottom-center or bottom-right.",
        template: """
        <.toaster id="toaster-position" />
        <div class="flex flex-wrap justify-center gap-2">
          <.button
            :for={
              {label, position} <- [
                {"Top Left", "top-left"},
                {"Top Center", "top-center"},
                {"Top Right", "top-right"},
                {"Bottom Left", "bottom-left"},
                {"Bottom Center", "bottom-center"},
                {"Bottom Right", "bottom-right"}
              ]
            }
            variant="outline"
            phx-click={
              SaladUI.JS.dispatch_command("add",
                to: "#toaster-position",
                detail: %{title: "Event has been created", position: position}
              )
            }
          >
            {label}
          </.button>
        </div>
        """
      }
    ]
  end
end
