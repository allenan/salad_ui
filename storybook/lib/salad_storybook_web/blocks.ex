defmodule SaladStorybookWeb.Blocks do
  @moduledoc """
  Ports of shadcn/ui blocks, each a self-contained LiveView under
  `lib/salad_storybook_web/blocks/` served at `/blocks/<slug>`.

  The storybook's "Blocks" stories render `preview/1`: the block in an iframe
  (so it gets a real viewport for its `md:`/`lg:` breakpoints and fixed
  sidebars) followed by its source, ready to copy.
  """
  use Phoenix.Component

  import SaladUI.CodeBlock

  @blocks_dir Path.join(__DIR__, "blocks")

  @blocks [
    %{
      slug: "dashboard-01",
      file: "dashboard_01.ex",
      title: "Dashboard",
      description: "A dashboard with sidebar, charts and data table.",
      height: "h-[900px]"
    },
    %{
      slug: "sidebar-07",
      file: "sidebar_07.ex",
      title: "Sidebar",
      description: "A sidebar that collapses to icons.",
      height: "h-[720px]"
    },
    %{
      slug: "login-03",
      file: "login_03.ex",
      title: "Login",
      description: "A login page with a muted background color.",
      height: "h-[760px]"
    },
    %{
      slug: "signup-03",
      file: "signup_03.ex",
      title: "Signup",
      description: "A signup page with a muted background color.",
      height: "h-[760px]"
    },
    %{
      slug: "chat-01",
      file: "chat_01.ex",
      title: "Chat",
      description: "A chat card with a message scroller, a thinking marker, streamed replies and a prompt input.",
      height: "h-[720px]"
    }
  ]

  for %{file: file} <- @blocks do
    @external_resource Path.join(@blocks_dir, file)
  end

  @sources Map.new(@blocks, &{&1.slug, File.read!(Path.join(@blocks_dir, &1.file))})

  @doc "The blocks, in the order the storybook lists them."
  def blocks, do: @blocks

  @doc "The block's metadata (`slug`, `file`, `title`, `description`, `height`)."
  def block!(slug), do: Enum.find(@blocks, &(&1.slug == slug)) || raise(ArgumentError, "unknown block #{inspect(slug)}")

  @doc "The block's LiveView source, as shipped in the storybook."
  def source(slug), do: Map.fetch!(@sources, slug)

  @doc """
  Renders a block preview: an iframe of `/blocks/<slug>` and the block's
  source with a copy button.
  """
  attr :slug, :string, required: true

  def preview(assigns) do
    block = block!(assigns.slug)
    assigns = assign(assigns, block: block, url: "/blocks/" <> block.slug, source: source(block.slug))

    ~H"""
    <div class="flex w-full flex-col gap-6">
      <div class="flex flex-wrap items-center justify-between gap-2">
        <p class="text-sm text-muted-foreground">
          {@block.description}
          <code class="ml-1 rounded bg-muted px-1 py-0.5 font-mono text-xs">{@block.slug}</code>
        </p>
        <a
          href={@url}
          target="_blank"
          class="text-sm font-medium text-primary underline-offset-4 hover:underline"
        >
          Open in a new tab
        </a>
      </div>
      <div class="overflow-hidden rounded-lg border">
        <iframe src={@url} title={@block.title <> " block preview"} class={["w-full", @block.height]}></iframe>
      </div>
      <div class="flex flex-col gap-2">
        <h2 class="text-lg font-semibold">Code</h2>
        <p class="text-sm text-muted-foreground">
          A LiveView module. Paste it into your app, rename the module, and replace
          <code class="rounded bg-muted px-1 py-0.5 font-mono text-xs">use SaladStorybookWeb, :demo_view</code>
          with <code class="rounded bg-muted px-1 py-0.5 font-mono text-xs">use MyAppWeb, :live_view</code>.
          Icons come from the
          <code class="rounded bg-muted px-1 py-0.5 font-mono text-xs">lucide_icons</code>
          package.
        </p>
        <.code_block>
          <.code_block_header>
            <.code_block_title>{@block.file}</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id={"copy-" <> @block.slug} value={@source} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content code={@source} language="elixir" line_numbers class="max-h-[640px]" />
        </.code_block>
      </div>
    </div>
    """
  end
end
