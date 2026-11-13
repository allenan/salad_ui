defmodule SaladUI.Message do
  @moduledoc """
  Message lays out one chat message: an optional avatar beside a column of
  content (a header, one or more bubbles or attachments, and a footer).

  Parts: `message_group/1`, `message/1`, `message_avatar/1`,
  `message_content/1`, `message_header/1`, `message_footer/1`.

  Message only handles layout and alignment. Put the text in a
  `SaladUI.Bubble`, files in a `SaladUI.Attachment` and notes between turns in
  a `SaladUI.Marker`.

  ## Alignment

  `align="end"` reverses the row (avatar on the right) and pushes every direct
  child of `message_content/1` to the end, so bubbles inside it align without
  setting `align` on each one. Use it for the current user's messages.

  ## Examples:

      <.message align="end">
        <.message_avatar>
          <.avatar>
            <.avatar_image src="/avatars/me.png" alt="@me" />
            <.avatar_fallback>ME</.avatar_fallback>
          </.avatar>
        </.message_avatar>
        <.message_content>
          <.bubble>
            <.bubble_content>Deploying to prod real quick.</.bubble_content>
          </.bubble>
          <.message_footer>Delivered</.message_footer>
        </.message_content>
      </.message>

      <.message>
        <.message_content>
          <.message_header>Olivia</.message_header>
          <.bubble variant="muted">
            <.bubble_content>I already checked the logs.</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
  """
  use SaladUI, :component

  @doc """
  Stacks consecutive messages from the same sender with a tighter gap.

  ## Examples:

      <.message_group>
        <.message>...</.message>
        <.message>...</.message>
      </.message_group>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def message_group(assigns) do
    ~H"""
    <div data-slot="message-group" class={classes(["flex min-w-0 flex-col gap-2", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a single message row.

  ## Options

  * `:align` - `"start"` (default, incoming) or `"end"` (outgoing). With
    `"end"` the avatar moves to the right and the content aligns to the end.
  * `:class` - Additional CSS classes.
  """
  attr :align, :string, values: ~w(start end), default: "start", doc: "which side the message sits on"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def message(assigns) do
    ~H"""
    <div
      data-slot="message"
      data-align={@align}
      class={
        classes([
          "group/message relative flex w-full min-w-0 gap-2 text-sm data-[align=end]:flex-row-reverse",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The avatar column. Put an `avatar/1` inside, or leave it empty to keep the
  indent for a grouped message whose sender is already shown. It lifts itself
  above a `message_footer/1` so it lines up with the last bubble.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def message_avatar(assigns) do
    ~H"""
    <div
      data-slot="message-avatar"
      class={
        classes([
          "flex w-fit min-w-8 shrink-0 items-center justify-center self-end overflow-hidden rounded-full bg-muted group-has-data-[slot=message-footer]/message:-translate-y-8",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The content column: header, bubbles, attachments and footer, stacked.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def message_content(assigns) do
    ~H"""
    <div
      data-slot="message-content"
      class={
        classes([
          "flex w-full min-w-0 flex-col gap-2.5 wrap-break-word group-data-[align=end]/message:*:data-slot:self-end",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A small muted line above the bubbles, typically the sender's name.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def message_header(assigns) do
    ~H"""
    <div
      data-slot="message-header"
      class={
        classes([
          "flex max-w-full min-w-0 items-center px-3 text-xs font-medium text-muted-foreground group-has-data-[variant=ghost]/message:px-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A small muted line below the bubbles: delivery status, a timestamp, or
  action buttons (copy, like, retry). Aligns to the end in an `align="end"`
  message.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def message_footer(assigns) do
    ~H"""
    <div
      data-slot="message-footer"
      class={
        classes([
          "flex max-w-full min-w-0 items-center px-3 text-xs font-medium text-muted-foreground group-has-data-[variant=ghost]/message:px-0 group-data-[align=end]/message:justify-end",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
