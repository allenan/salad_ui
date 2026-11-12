defmodule SaladUI.Bubble do
  @moduledoc """
  Chat bubbles: the framed text of a message, with variants, start/end
  alignment, grouping and reactions.

  Parts: `bubble_group/1`, `bubble/1`, `bubble_content/1`, `bubble_reactions/1`.

  `bubble/1` is the positioning wrapper and owns the variant; the colored
  surface is `bubble_content/1`. Inside an `align="end"` `SaladUI.Message` a
  bubble aligns to the end on its own.

  ## Variants

  `default` (primary), `secondary`, `muted`, `tinted` (a soft tint derived from
  `--primary`), `outline`, `ghost` (no frame, full width; for assistant text and
  markdown) and `destructive`.

  ## Interactive bubbles

  shadcn's `<BubbleContent asChild><button>` is `as="button"` (or `as="a"`
  with an `href`). The bubble then gets hover and focus-visible styles:

      <.bubble variant="tinted" align="end">
        <.bubble_content as="button" phx-click="choose" phx-value-option="password">
          I forgot my password
        </.bubble_content>
      </.bubble>

  ## Collapsible content

  Long bubbles compose `SaladUI.Collapsible` inside `bubble_content/1`. The
  collapsible root carries `data-state="open|closed"`, so the preview and the
  toggle label can switch with `group-data-[state=open]/…` classes:

      <.bubble variant="muted" align="end">
        <.bubble_content>
          <.collapsible id="long-reply" class="group/bubble-collapsible">
            <div class="group-data-[state=open]/bubble-collapsible:hidden">{preview}</div>
            <.collapsible_content>{full_text}</.collapsible_content>
            <.collapsible_trigger as="button" class="text-muted-foreground">
              <span class="group-data-[state=open]/bubble-collapsible:hidden">Show more</span>
              <span class="hidden group-data-[state=open]/bubble-collapsible:inline">Show less</span>
            </.collapsible_trigger>
          </.collapsible>
        </.bubble_content>
      </.bubble>

  ## Examples:

      <.bubble align="end">
        <.bubble_content>Hey there! what's up?</.bubble_content>
      </.bubble>

      <.bubble_group>
        <.bubble variant="muted">
          <.bubble_content>Hey! Want to see chat bubbles?</.bubble_content>
        </.bubble>
        <.bubble variant="muted">
          <.bubble_content>I can group messages and switch sides.</.bubble_content>
          <.bubble_reactions role="img" aria-label="Reaction: thumbs up">
            <span>👍</span>
          </.bubble_reactions>
        </.bubble>
      </.bubble_group>
  """
  use SaladUI, :component

  @doc """
  Stacks consecutive bubbles from one sender with a tighter gap.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def bubble_group(assigns) do
    ~H"""
    <div data-slot="bubble-group" class={classes(["flex min-w-0 flex-col gap-2", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @variants %{
    variant: %{
      "default" =>
        "*:data-[slot=bubble-content]:bg-primary *:data-[slot=bubble-content]:text-primary-foreground [&>[data-slot=bubble-content]:is(button,a):hover]:bg-primary/80",
      "secondary" =>
        "*:data-[slot=bubble-content]:bg-secondary *:data-[slot=bubble-content]:text-secondary-foreground [&>[data-slot=bubble-content]:is(button,a):hover]:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)]",
      "muted" =>
        "*:data-[slot=bubble-content]:bg-muted [&>[data-slot=bubble-content]:is(button,a):hover]:bg-[color-mix(in_oklch,var(--muted),var(--foreground)_5%)]",
      "tinted" =>
        "*:data-[slot=bubble-content]:bg-[oklch(from_var(--primary)_0.93_calc(c*0.4)_h)] *:data-[slot=bubble-content]:text-foreground dark:*:data-[slot=bubble-content]:bg-[oklch(from_var(--primary)_0.3_calc(c*0.4)_h)] [&>[data-slot=bubble-content]:is(button,a):hover]:bg-[oklch(from_var(--primary)_0.88_calc(c*0.5)_h)] dark:[&>[data-slot=bubble-content]:is(button,a):hover]:bg-[oklch(from_var(--primary)_0.35_calc(c*0.5)_h)]",
      "outline" =>
        "*:data-[slot=bubble-content]:border-border *:data-[slot=bubble-content]:bg-background [&>[data-slot=bubble-content]:is(button,a):hover]:bg-muted [&>[data-slot=bubble-content]:is(button,a):hover]:text-foreground dark:[&>[data-slot=bubble-content]:is(button,a):hover]:bg-input/30",
      "ghost" =>
        "border-none *:data-[slot=bubble-content]:rounded-none *:data-[slot=bubble-content]:bg-transparent *:data-[slot=bubble-content]:p-0 [&>[data-slot=bubble-content]:is(button,a):hover]:bg-muted [&>[data-slot=bubble-content]:is(button,a):hover]:text-foreground dark:[&>[data-slot=bubble-content]:is(button,a):hover]:bg-muted/50",
      "destructive" =>
        "*:data-[slot=bubble-content]:bg-destructive/10 *:data-[slot=bubble-content]:text-destructive dark:*:data-[slot=bubble-content]:bg-destructive/20 [&>[data-slot=bubble-content]:is(button,a):hover]:bg-destructive/20 dark:[&>[data-slot=bubble-content]:is(button,a):hover]:bg-destructive/30"
    }
  }

  @doc """
  Renders a bubble wrapper. Put a `bubble_content/1` inside, and optionally a
  `bubble_reactions/1`.

  ## Options

  * `:variant` - `"default"`, `"secondary"`, `"muted"`, `"tinted"`,
    `"outline"`, `"ghost"` or `"destructive"`.
  * `:align` - `"start"` (default) or `"end"`.
  * `:class` - Additional CSS classes.
  """
  attr :variant, :string,
    values: ~w(default secondary muted tinted outline ghost destructive),
    default: "default",
    doc: "the bubble color variant"

  attr :align, :string, values: ~w(start end), default: "start", doc: "which side the bubble sits on"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def bubble(assigns) do
    assigns = assign(assigns, :variant_class, @variants.variant[assigns.variant])

    ~H"""
    <div
      data-slot="bubble"
      data-variant={@variant}
      data-align={@align}
      class={
        classes([
          "group/bubble relative flex w-fit max-w-[80%] min-w-0 flex-col gap-1 group-data-[align=end]/message:self-end data-[align=end]:self-end data-[variant=ghost]:max-w-full",
          @variant_class,
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
  The bubble's colored surface.

  ## Options

  * `:as` - The tag to render: `"div"` (default), `"button"` or `"a"`. A
    button or link gets hover and focus-visible styles (shadcn's `asChild`).
    A button defaults to `type="button"`.
  * `:class` - Additional CSS classes.
  """
  attr :as, :string, values: ~w(div button a), default: "div", doc: "the element to render"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href target rel type disabled name value download)
  slot :inner_block, required: true

  def bubble_content(assigns) do
    assigns =
      if assigns.as == "button" and is_nil(assigns.rest[:type]),
        do: assign(assigns, :rest, Map.put(assigns.rest, :type, "button")),
        else: assigns

    ~H"""
    <.dynamic_tag
      tag_name={@as}
      data-slot="bubble-content"
      class={
        classes([
          "w-fit max-w-full min-w-0 overflow-hidden rounded-xl border border-transparent px-3 py-2 text-sm leading-relaxed wrap-break-word group-data-[align=end]/bubble:self-end [button]:text-left [button,a]:transition-colors [button,a]:outline-none [button,a]:focus-visible:border-ring [button,a]:focus-visible:ring-3 [button,a]:focus-visible:ring-ring/50",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  @doc """
  A pill pinned to the bubble's edge for emoji reactions, a read receipt or a
  small action. Give it `role="img"` and an `aria-label` that spells the
  reactions out (e.g. `"Reactions: thumbs up, fire"`); when it holds buttons,
  label the buttons instead.

  ## Options

  * `:side` - `"bottom"` (default) or `"top"`.
  * `:align` - `"end"` (default) or `"start"`.
  * `:class` - Additional CSS classes.
  """
  attr :side, :string, values: ~w(top bottom), default: "bottom", doc: "which edge the reactions sit on"
  attr :align, :string, values: ~w(start end), default: "end", doc: "which corner the reactions sit in"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def bubble_reactions(assigns) do
    assigns =
      assign(assigns,
        side_class: %{"top" => "top-0 -translate-y-3/4", "bottom" => "bottom-0 translate-y-3/4"}[assigns.side],
        align_class: %{"start" => "left-3", "end" => "right-3"}[assigns.align]
      )

    ~H"""
    <div
      data-slot="bubble-reactions"
      data-align={@align}
      data-side={@side}
      class={
        classes([
          "absolute z-10 flex w-fit shrink-0 items-center justify-center gap-1 rounded-full bg-muted px-1.5 py-0.5 text-sm ring-3 ring-card has-[button]:p-0",
          @side_class,
          @align_class,
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
