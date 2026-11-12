defmodule SaladUI.Kbd do
  @moduledoc """
  Displays keyboard input: a single key with `kbd/1`, or a key combination with
  `kbd_group/1`.

  Inside a `tooltip_content` the keys switch to a translucent style that reads
  on the tooltip's inverted background.

  ## Examples

      <.kbd>Ctrl</.kbd>

      <.kbd_group>
        <.kbd>⌘</.kbd>
        <.kbd>K</.kbd>
      </.kbd_group>

      <.kbd_group>
        <.kbd>Ctrl</.kbd>
        <span>+</span>
        <.kbd>B</.kbd>
      </.kbd_group>

      <.button variant="outline" size="sm" class="pr-2">
        Accept <.kbd>⏎</.kbd>
      </.button>
  """
  use SaladUI, :component

  @doc """
  Renders a single keyboard key.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def kbd(assigns) do
    ~H"""
    <kbd
      data-slot="kbd"
      class={
        classes([
          "pointer-events-none inline-flex h-5 w-fit min-w-5 items-center justify-center gap-1 rounded-sm bg-muted px-1 font-sans text-xs font-medium text-muted-foreground select-none",
          "[&_svg:not([class*='size-'])]:size-3",
          "[[data-slot=tooltip-content]_&]:bg-background/20 [[data-slot=tooltip-content]_&]:text-background dark:[[data-slot=tooltip-content]_&]:bg-background/10",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </kbd>
    """
  end

  @doc """
  Groups keys into a combination, rendered as a nested `<kbd>`.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def kbd_group(assigns) do
    ~H"""
    <kbd data-slot="kbd-group" class={classes(["inline-flex items-center gap-1", @class])} {@rest}>
      {render_slot(@inner_block)}
    </kbd>
    """
  end
end
