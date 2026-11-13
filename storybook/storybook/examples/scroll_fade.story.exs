defmodule Storybook.Examples.ScrollFade do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  def doc do
    """
    shadcn's `scroll-fade` utilities (from `salad_ui.css`): a scroll-aware `mask-image` fade on the
    edges of a scroll container, driven by CSS scroll-driven animations with a static fallback.
    `scroll-fade`/`scroll-fade-y` (vertical), `scroll-fade-x` (inline, mirrors in RTL), the edge
    utilities `scroll-fade-{t,b,l,r,s,e}`, sizes `scroll-fade-<n>` / `scroll-fade-{t,b,s,e}-<n>`
    and `scroll-fade-none`.
    """
  end

  @tags ~w(Design Engineering Marketing Product Research Sales Support Operations Finance Legal People Security)
  @rtl_tags ~w(تصميم هندسة تسويق منتج أبحاث مبيعات دعم عمليات مالية قانوني)
  @items ["Inbox triage", "Design review", "API contract", "QA pass", "Launch notes", "Metrics follow-up"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, tags: @tags, rtl_tags: @rtl_tags, items: @items)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-10 py-6 sm:grid-cols-2">
      <.example title="Demo" class="scroll-fade">
        <div class="h-72 scroll-fade scrollbar-none overflow-y-auto">
          <.items count={12} />
        </div>
      </.example>

      <.example title="No overflow, no fade" class="scroll-fade">
        <div class="scroll-fade scrollbar-none overflow-y-auto">
          <.items count={3} />
        </div>
      </.example>

      <.example title="Vertical (alias of scroll-fade)" class="scroll-fade-y">
        <div class="h-48 scroll-fade-y scrollbar-none overflow-y-auto">
          <.items count={8} />
        </div>
      </.example>

      <.example title="Horizontal" class="scroll-fade-x">
        <div class="scroll-fade-x scrollbar-none overflow-x-auto">
          <.tags tags={@tags} />
        </div>
      </.example>

      <.example title="RTL" class="scroll-fade-x" dir="rtl">
        <div class="scroll-fade-x scrollbar-none overflow-x-auto">
          <.tags tags={@rtl_tags} />
        </div>
      </.example>

      <.example :for={edge <- ~w(scroll-fade-t scroll-fade-b)} title="Edge" class={edge}>
        <div class={["h-36 scrollbar-none overflow-y-auto", edge]}>
          <.items labels={@items} />
        </div>
      </.example>

      <.example
        :for={edge <- ~w(scroll-fade-l scroll-fade-r scroll-fade-s scroll-fade-e)}
        title="Edge"
        class={edge}
      >
        <div class={["scrollbar-none overflow-x-auto", edge]}>
          <.tags tags={Enum.take(@tags, 8)} />
        </div>
      </.example>

      <.example title="Size" class="scroll-fade-4">
        <div class="h-48 scroll-fade scrollbar-none overflow-y-auto scroll-fade-4">
          <.items count={8} />
        </div>
      </.example>

      <.example title="Size" class="scroll-fade-24">
        <div class="h-48 scroll-fade scrollbar-none overflow-y-auto scroll-fade-24">
          <.items count={8} />
        </div>
      </.example>

      <.example title="Per-edge size" class="scroll-fade-t-2 scroll-fade-b-16">
        <div class="h-48 scroll-fade scrollbar-none overflow-y-auto scroll-fade-t-2 scroll-fade-b-16">
          <.items count={8} />
        </div>
      </.example>

      <.example
        title="Arbitrary size, slower reveal"
        class="scroll-fade-[25%] [--scroll-fade-reveal:160px]"
      >
        <div class="h-48 scroll-fade scrollbar-none overflow-y-auto scroll-fade-[25%] [--scroll-fade-reveal:160px]">
          <.items count={8} />
        </div>
      </.example>

      <.example title="Disabled" class="scroll-fade scroll-fade-none">
        <div class="h-48 scroll-fade scrollbar-none overflow-y-auto scroll-fade-none">
          <.items count={8} />
        </div>
      </.example>

      <.example title="Responsive" class="scroll-fade md:scroll-fade-none">
        <div class="h-48 scroll-fade scrollbar-none overflow-y-auto md:scroll-fade-none">
          <.items count={8} />
        </div>
      </.example>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :class, :string, required: true
  attr :dir, :string, default: nil
  slot :inner_block, required: true

  defp example(assigns) do
    ~H"""
    <div class="mx-auto flex w-full max-w-xs min-w-0 flex-col gap-3">
      <div class="overflow-hidden rounded-2xl border" dir={@dir}>
        {render_slot(@inner_block)}
      </div>
      <p class="text-center font-mono text-xs text-muted-foreground">
        {@title}: {@class}
      </p>
    </div>
    """
  end

  attr :count, :integer, default: nil
  attr :labels, :list, default: nil

  defp items(assigns) do
    assigns = assign_new(assigns, :rows, fn -> assigns.labels || Enum.map(1..assigns.count, &"Item #{&1}") end)

    ~H"""
    <div class="flex flex-col gap-1.5 p-1.5">
      <div :for={row <- @rows} class="rounded-lg bg-muted px-3 py-2.5 text-sm">{row}</div>
    </div>
    """
  end

  attr :tags, :list, required: true

  defp tags(assigns) do
    ~H"""
    <div class="flex w-max gap-1.5 p-1.5">
      <div :for={tag <- @tags} class="shrink-0 rounded-lg bg-muted px-3 py-2.5 text-sm">{tag}</div>
    </div>
    """
  end
end
