defmodule SaladUI.Separator do
  @moduledoc """
  Implementation of a separator component for dividing content.

  Like Radix's Separator, it is decorative by default (`role="none"`, hidden
  from assistive technology). Pass `decorative={false}` when the separator
  carries meaning, to render `role="separator"` with `aria-orientation`.

  ## Examples:

      <.separator />
      <.separator orientation="vertical" />
      <.separator orientation="vertical" decorative={false} class="h-6" />

      <div class="flex h-5 items-center gap-4 text-sm">
        <div>Blog</div>
        <.separator orientation="vertical" />
        <div>Docs</div>
        <.separator orientation="vertical" />
        <div>Source</div>
      </div>
  """
  use SaladUI, :component

  @doc """
  Renders a separator.

  ## Options

  * `:orientation` - The orientation of the separator (`horizontal` or `vertical`). Defaults to `horizontal`.
    Rendered as `data-orientation`, which the `h-px`/`w-px` classes key off.
  * `:decorative` - When `true` (default) the separator is purely visual and gets `role="none"`.
    When `false` it gets `role="separator"` and, if vertical, `aria-orientation="vertical"`.
  * `:class` - Additional CSS classes
  """
  attr :orientation, :string, values: ~w(vertical horizontal), default: "horizontal"

  attr :decorative, :boolean,
    default: true,
    doc: "purely visual (role=none) when true; a semantic role=separator when false"

  attr :class, :any, default: nil
  attr :rest, :global

  def separator(assigns) do
    assigns = put_data_slot(assigns, "separator")

    ~H"""
    <div
      role={if @decorative, do: "none", else: "separator"}
      aria-orientation={!@decorative && @orientation == "vertical" && "vertical"}
      data-orientation={@orientation}
      class={
        classes([
          "shrink-0 bg-border data-[orientation=horizontal]:h-px data-[orientation=horizontal]:w-full data-[orientation=vertical]:h-full data-[orientation=vertical]:w-px",
          @class
        ])
      }
      {@rest}
    >
    </div>
    """
  end
end
