defmodule Storybook.SaladUIComponents.CodeBlock do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.CodeBlock

  @router ~S"""
  defmodule MyAppWeb.Router do
    use MyAppWeb, :router

    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :protect_from_forgery
    end

    scope "/", MyAppWeb do
      pipe_through :browser

      live "/chat", ChatLive
    end
  end
  """

  @install_command "mix igniter.install salad_ui"

  @install_output """
  $ mix igniter.install salad_ui
  Resolving Hex dependencies...
  Resolution completed in 0.04s
  * creating lib/my_app_web/components/ui.ex
  Done in 2.8s\
  """

  @build_output """
  $ mix assets.deploy
  Rebuilding...
   ✓ tailwind  app.css  38.2 kB  in 182ms
   ✓ esbuild   app.js  121.4 kB  in 41ms
  Check your digested files at "priv/static"
  ┌ priv/static/assets/app-3f2a.css    38.2 kB
  ├ priv/static/assets/app-91bc.js    121.4 kB
  └ priv/static/cache_manifest.json     1.1 kB\
  """

  @lint_output """
  $ mix credo
  lib/my_app_web/live/chat_live.ex
    18:22  [W] ↗ There should be no calls to `IO.inspect/1`.  Credo.Check.Warning.IoInspect
    42:7   [R] ↘ Modules should have a @moduledoc tag.  Credo.Check.Readability.ModuleDoc

  2 issues (1 warning, 1 refactoring opportunity)\
  """

  @deps_output """
  $ mix deps.get
  Resolving Hex dependencies...
  New:
    makeup 1.2.1
    makeup_elixir 1.0.1
    salad_ui 1.0.0
  All dependencies are up to date\
  """

  @mix_exs """
  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.2"},
      {:salad_ui, "~> 1.0"}
    ]
  end\
  """

  @start_line_code """
    def handle_event("save", %{"project" => params}, socket) do
      case Projects.update(socket.assigns.project, params) do
        {:ok, project} ->
          {:noreply, assign(socket, :project, project)}

        {:error, changeset} ->
          {:noreply, assign(socket, :form, to_form(changeset))}
      end
    end
  end\
  """

  @long_error ~S|** (Mix) Could not compile dependency :salad_ui, "mix compile" failed. Errors may have been logged above. You can recompile this dependency with "mix deps.compile salad_ui --force", update it with "mix deps.update salad_ui" or clean it with "mix deps.clean salad_ui"|

  @config_code """
  config :my_app, MyAppWeb.Endpoint,
    url: [host: "localhost"],
    render_errors: [formats: [html: MyAppWeb.ErrorHTML], layout: false],
    pubsub_server: MyApp.PubSub,
    live_view: [signing_salt: "s3cr3t"]\
  """

  @patch """
   def greeting(assigns) do
     ~H\"\"\"
  -  <p>Hello, {@name}</p>
  +  <p class="text-sm text-muted-foreground">
  +    Hello, {@name}!
  +  </p>
     \"\"\"
   end\
  """

  @logs Enum.map_join(1..40, "\n", fn i ->
          "[#{String.pad_leading(Integer.to_string(i), 2, "0")}] GET /api/chat 200 in #{12 + rem(i * 7, 40)}ms"
        end)

  @chat_live ~S'''
  defmodule MyAppWeb.ChatLive do
    use MyAppWeb, :live_view

    def mount(_params, _session, socket) do
      {:ok, socket |> assign(:input, "") |> stream(:messages, [])}
    end

    def handle_event("send", %{"text" => text}, socket) do
      message = %{id: System.unique_integer([:positive]), text: text}
      {:noreply, socket |> assign(:input, "") |> stream_insert(:messages, message)}
    end

    def render(assigns) do
      ~H"""
      <div class="flex flex-col gap-4">
        <div id="messages" phx-update="stream">
          <p :for={{id, message} <- @streams.messages} id={id}>{message.text}</p>
        </div>
        <.form for={%{}} phx-submit="send">
          <.input name="text" value={@input} />
          <.button>Send</.button>
        </.form>
      </div>
      """
    end
  end
  '''

  @node_output """
  $ elixir --version
  Erlang/OTP 28 [erts-16.0] [source] [64-bit]

  Elixir 1.19.0 (compiled with Erlang/OTP 28)\
  """

  @server_error """
  $ mix phx.server
  ** (RuntimeError) could not start Cowboy2 adapter, the port 4000 is already in use
      (phoenix 1.8.1) lib/phoenix/endpoint/cowboy2_adapter.ex:111: Phoenix.Endpoint.Cowboy2Adapter.start_link/3\
  """

  @compile_error """
  ** (CompileError) lib/my_app_web/live/chat_live.ex:18: undefined variable "messages"
      (elixir 1.19.0) lib/kernel/parallel_compiler.ex:461: Kernel.ParallelCompiler.require_file/2
      (mix 1.19.0) lib/mix/tasks/compile.elixir.ex:188: Mix.Tasks.Compile.Elixir.run/1\
  """

  @greeter ~S|def greet(name), do: "Hello, #{name}!"|

  @heex """
  <.code_block>
    <.code_block_content code={@code} language="elixir" />
  </.code_block>\
  """

  @ansi_output ~s{$ mix test\n\e[32m.\e[39m\e[32m.\e[39m\e[31mF\e[39m\e[32m.\e[39m\n\n  1) test greets the user (MyApp.GreeterTest)\n     \e[31mAssertion with == failed\e[39m\n     \e[36mcode:  \e[39massert greet("hello") == "hello world"\n\nFinished in 0.04 seconds \e[2m(0.00s async, 0.04s sync)\e[22m\n\e[31m4 tests, 1 failure\e[39m}

  def function, do: &CodeBlock.code_block/1

  def layout, do: :one_column

  def imports,
    do: [
      {CodeBlock,
       [
         code_block_header: 1,
         code_block_title: 1,
         code_block_actions: 1,
         code_block_copy_button: 1,
         code_block_content: 1,
         code_block_line: 1,
         code_block_footer: 1
       ]},
      {SaladUI.Button, [button: 1]},
      {SaladUI.Collapsible, [collapsible: 1, collapsible_trigger: 1, collapsible_content: 1]},
      {SaladUI.Tabs, [tabs: 1, tabs_list: 1, tabs_trigger: 1, tabs_content: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        description: "Header with title and actions, line numbers, highlighted lines and Makeup syntax highlighting.",
        template: """
        <div class="w-full max-w-lg">
          <.code_block>
            <.code_block_header>
              <.code_block_title>
                <Lucideicons.file_code /> lib/my_app_web/router.ex
              </.code_block_title>
              <.code_block_actions>
                <.button
                  variant="ghost"
                  size="icon-xs"
                  aria-label="Wrap lines"
                  aria-pressed="false"
                  class="aria-pressed:text-foreground"
                  phx-click={JS.toggle_attribute({"data-wrap", ""}, to: "#demo-content") |> JS.toggle_attribute({"aria-pressed", "true", "false"})}
                >
                  <Lucideicons.wrap_text />
                </.button>
                <.button
                  variant="ghost"
                  size="icon-xs"
                  aria-label="Download"
                  href={{:data, "text/plain;charset=utf-8," <> URI.encode(#{inspect(@router)})}}
                  download="router.ex"
                >
                  <Lucideicons.download />
                </.button>
                <.code_block_copy_button id="demo-copy" value={#{inspect(@router)}} />
              </.code_block_actions>
            </.code_block_header>
            <.code_block_content
              id="demo-content"
              code={#{inspect(@router)}}
              language="elixir"
              line_numbers
              highlight={[6, 7, 8, 9, 10]}
            />
          </.code_block>
        </div>
        """,
        slots: []
      },
      %Variation{
        id: :basic,
        description: "Pass a string as `code`. It renders as one text node.",
        attributes: %{class: "w-full max-w-md"},
        slots: [~s|<.code_block_content code={#{inspect(@build_output)}} />|]
      },
      %Variation{
        id: :header,
        description: "A header with a title and a copy button. The button copies its `value`.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title><Lucideicons.terminal /> Terminal</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id="header-copy" value={#{inspect(@install_command)}} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content code={#{inspect(@install_output)}} />
          """
        ]
      },
      %Variation{
        id: :linked_title,
        description: "To link the title to a file, wrap the title in an anchor. A long title truncates.",
        attributes: %{class: "w-full max-w-xs"},
        slots: [
          """
          <.code_block_header>
            <a href="#" class="hover:underline">
              <.code_block_title>lib/my_app_web/components/layouts/root.html.heex</.code_block_title>
            </a>
          </.code_block_header>
          <.code_block_content code="<.live_title>{@page_title}</.live_title>" />
          """
        ]
      },
      %Variation{
        id: :actions,
        description:
          "Any number of buttons. The wrap toggle flips `data-wrap` on the content with `JS.toggle_attribute/2`.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title><Lucideicons.terminal /> Terminal</.code_block_title>
            <.code_block_actions>
              <.button
                variant="ghost"
                size="icon-xs"
                aria-label="Wrap lines"
                aria-pressed="true"
                class="aria-pressed:text-foreground"
                phx-click={JS.toggle_attribute({"data-wrap", ""}, to: "#actions-content") |> JS.toggle_attribute({"aria-pressed", "true", "false"})}
              >
                <Lucideicons.wrap_text />
              </.button>
              <.button
                variant="ghost"
                size="icon-xs"
                aria-label="Download"
                href={{:data, "text/plain;charset=utf-8," <> URI.encode(#{inspect(@lint_output)})}}
                download="credo.log"
              >
                <Lucideicons.download />
              </.button>
              <.code_block_copy_button id="actions-copy" value={#{inspect(@lint_output)}} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content id="actions-content" code={#{inspect(@lint_output)}} wrap />
          """
        ]
      },
      %Variation{
        id: :floating_actions,
        description: "Without a header, the actions float and show on hover or focus.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_actions>
            <.code_block_copy_button id="floating-copy" />
          </.code_block_actions>
          <.code_block_content code={#{inspect(@deps_output)}} />
          """
        ]
      },
      %Variation{
        id: :line_numbers,
        description: "`line_numbers` splits the string into lines. Numbers are not copied with a selection.",
        attributes: %{class: "w-full max-w-md"},
        slots: [~s|<.code_block_content code={#{inspect(@mix_exs)}} line_numbers />|]
      },
      %Variation{
        id: :start_line,
        description: "`start_line` numbers from a given line. The gutter grows to fit.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title>lib/my_app_web/live/project_live/edit.ex</.code_block_title>
          </.code_block_header>
          <.code_block_content code={#{inspect(@start_line_code)}} language="elixir" line_numbers start_line={995} />
          """
        ]
      },
      %Variation{
        id: :wrap,
        description: "Long lines scroll by default; `wrap` wraps them.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-4">
          <.code_block><.code_block_content code={#{inspect(@long_error)}} /></.code_block>
          <.code_block><.code_block_content code={#{inspect(@long_error)}} wrap /></.code_block>
        </div>
        """,
        slots: []
      },
      %Variation{
        id: :highlighted_lines,
        description: "`highlight` takes the line numbers to call out (or set `variant` on `code_block_line`).",
        attributes: %{class: "w-full max-w-md"},
        slots: [~s|<.code_block_content code={#{inspect(@config_code)}} line_numbers highlight={[2, 3]} />|]
      },
      %Variation{
        id: :lines,
        description: "Render each line as a `code_block_line` to set its variant yourself.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_content line_numbers>
            <.code_block_line>config :logger, :console,</.code_block_line>
            <.code_block_line variant="highlighted">  format: "$time $metadata[$level] $message\\n",</.code_block_line>
            <.code_block_line>  metadata: [:request_id]</.code_block_line>
            <.code_block_line />
            <.code_block_line variant="removed">config :phoenix, :json_library, Poison</.code_block_line>
            <.code_block_line variant="added">config :phoenix, :json_library, Jason</.code_block_line>
          </.code_block_content>
          """
        ]
      },
      %Variation{
        id: :diff,
        description: "`diff` marks `+` lines as added and `-` lines as removed, with a marker as well as a tint.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title>lib/my_app_web/components/greeting.ex</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id="diff-copy" value={#{inspect(@patch)}} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content code={#{inspect(@patch)}} diff />
          """
        ]
      },
      %Variation{
        id: :height,
        description:
          "Cap the height with a `max-h-*` class; the content scrolls inside the block and `scroll-fade-y` fades its top and bottom edges.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title>Logs</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id="height-copy" value={#{inspect(@logs)}} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content code={#{inspect(@logs)}} class="max-h-48 scroll-fade-y" />
          """
        ]
      },
      %Variation{
        id: :show_more,
        description:
          "Cap the content while collapsed (`max-h-64 scroll-fade-y overflow-y-hidden`) and toggle the cap from a footer button.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title>lib/my_app_web/live/chat_live.ex</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id="show-more-copy" value={#{inspect(@chat_live)}} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content
            id="show-more-content"
            code={#{inspect(@chat_live)}}
            language="elixir"
            line_numbers
            class="max-h-64 scroll-fade-y overflow-y-hidden"
          />
          <.code_block_footer class="justify-center">
            <.button
              variant="ghost"
              size="xs"
              aria-expanded="false"
              aria-controls="show-more-content"
              phx-click={JS.toggle_class("max-h-64 scroll-fade-y overflow-y-hidden", to: "#show-more-content") |> JS.toggle_attribute({"aria-expanded", "true", "false"})}
            >
              <Lucideicons.chevron_down class="transition-transform in-aria-expanded:rotate-180" />
              <span class="in-aria-expanded:hidden">Show more</span>
              <span class="hidden in-aria-expanded:inline">Show less</span>
            </.button>
          </.code_block_footer>
          """
        ]
      },
      %Variation{
        id: :show_more_max_height,
        description:
          "Raise the cap instead of removing it, so a long block still scrolls (and fades with `scroll-fade-y`) when expanded.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title>lib/my_app_web/live/chat_live.ex</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id="show-more-scroll-copy" value={#{inspect(@chat_live)}} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content
            id="show-more-scroll-content"
            code={#{inspect(@chat_live)}}
            language="elixir"
            line_numbers
            class="max-h-64 scroll-fade-y overflow-y-hidden"
          />
          <.code_block_footer class="justify-center">
            <.button
              variant="ghost"
              size="xs"
              aria-expanded="false"
              aria-controls="show-more-scroll-content"
              phx-click={JS.toggle_class("max-h-64 max-h-96 overflow-y-hidden", to: "#show-more-scroll-content") |> JS.toggle_attribute({"aria-expanded", "true", "false"})}
            >
              <Lucideicons.chevron_down class="transition-transform in-aria-expanded:rotate-180" />
              <span class="in-aria-expanded:hidden">Show more</span>
              <span class="hidden in-aria-expanded:inline">Show less</span>
            </.button>
          </.code_block_footer>
          """
        ]
      },
      %Variation{
        id: :size,
        description: "`size=\"sm\"` has tighter padding and `text-xs` code, for tool output.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-4">
          <.code_block size="default">
            <.code_block_header>
              <.code_block_title><Lucideicons.terminal /> Terminal</.code_block_title>
              <.code_block_actions>
                <.code_block_copy_button id="size-default-copy" />
              </.code_block_actions>
            </.code_block_header>
            <.code_block_content code={#{inspect(@install_output)}} wrap />
          </.code_block>
          <.code_block size="sm">
            <.code_block_header>
              <.code_block_title><Lucideicons.terminal /> Terminal</.code_block_title>
              <.code_block_actions>
                <.code_block_copy_button id="size-sm-copy" />
              </.code_block_actions>
            </.code_block_header>
            <.code_block_content code={#{inspect(@install_output)}} wrap />
          </.code_block>
        </div>
        """,
        slots: []
      },
      %Variation{
        id: :destructive,
        description: "`variant=\"destructive\"` for errors and failed output.",
        attributes: %{variant: "destructive", class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title>Error</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id="destructive-copy" value={#{inspect(@compile_error)}} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content code={#{inspect(@compile_error)}} wrap />
          """
        ]
      },
      %Variation{
        id: :trace,
        description: "Small blocks inside collapsible tool output (SaladUI has no Trace component).",
        template: """
        <div class="flex w-full max-w-md flex-col gap-2 text-sm">
          <.collapsible id="trace-ok" open>
            <.collapsible_trigger>
              <button type="button" class="flex items-center gap-2 text-muted-foreground">
                <Lucideicons.terminal class="size-4" /> Ran elixir --version
              </button>
            </.collapsible_trigger>
            <.collapsible_content class="pt-2">
              <.code_block size="sm">
                <.code_block_content code={#{inspect(@node_output)}} wrap class="max-h-64" />
              </.code_block>
            </.collapsible_content>
          </.collapsible>
          <.collapsible id="trace-error" open>
            <.collapsible_trigger>
              <button type="button" class="flex items-center gap-2 text-destructive">
                <Lucideicons.terminal class="size-4" /> Failed to run mix phx.server
              </button>
            </.collapsible_trigger>
            <.collapsible_content class="pt-2">
              <.code_block size="sm" variant="destructive">
                <.code_block_content code={#{inspect(@server_error)}} wrap class="max-h-64" />
              </.code_block>
            </.collapsible_content>
          </.collapsible>
        </div>
        """,
        slots: []
      },
      %Variation{
        id: :tabs,
        description: "Several files in Tabs, one code block per tab.",
        template: """
        <.tabs id="code-block-tabs" default="router" class="w-full max-w-md">
          <.tabs_list>
            <.tabs_trigger value="router">router.ex</.tabs_trigger>
            <.tabs_trigger value="mix">mix.exs</.tabs_trigger>
            <.tabs_trigger value="env">.env</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="router">
            <.code_block>
              <.code_block_header>
                <.code_block_title>lib/my_app_web/router.ex</.code_block_title>
                <.code_block_actions><.code_block_copy_button id="tabs-router-copy" /></.code_block_actions>
              </.code_block_header>
              <.code_block_content code={#{inspect(@router)}} language="elixir" line_numbers />
            </.code_block>
          </.tabs_content>
          <.tabs_content value="mix">
            <.code_block>
              <.code_block_header>
                <.code_block_title>mix.exs</.code_block_title>
                <.code_block_actions><.code_block_copy_button id="tabs-mix-copy" /></.code_block_actions>
              </.code_block_header>
              <.code_block_content code={#{inspect(@mix_exs)}} language="elixir" line_numbers />
            </.code_block>
          </.tabs_content>
          <.tabs_content value="env">
            <.code_block>
              <.code_block_header>
                <.code_block_title>.env</.code_block_title>
                <.code_block_actions><.code_block_copy_button id="tabs-env-copy" /></.code_block_actions>
              </.code_block_header>
              <.code_block_content code="SECRET_KEY_BASE=your-secret" line_numbers />
            </.code_block>
          </.tabs_content>
        </.tabs>
        """,
        slots: []
      },
      %Variation{
        id: :message,
        description: "A code block between paragraphs of a chat message.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-4 text-sm">
          <div class="self-end rounded-lg bg-muted px-3 py-2">How do I add a LiveView route?</div>
          <div class="flex flex-col gap-3">
            <p>Add a <code>live</code> route inside a browser scope:</p>
            <.code_block>
              <.code_block_header>
                <.code_block_title>lib/my_app_web/router.ex</.code_block_title>
                <.code_block_actions><.code_block_copy_button id="message-copy" /></.code_block_actions>
              </.code_block_header>
              <.code_block_content code={#{inspect(@router)}} language="elixir" />
            </.code_block>
            <p>Then create the <code>ChatLive</code> module.</p>
          </div>
        </div>
        """,
        slots: []
      },
      %Variation{
        id: :typeset,
        description:
          "Inside a `typeset` container (the opt-in `typeset.css`), the block keeps its own styles and gets the same space above as a paragraph.",
        template: """
        <div class="typeset w-full max-w-md">
          <h3>Stream a response</h3>
          <p>
            Add a <code>live</code> route, then stream the reply into the LiveView with
            <code>stream_insert/3</code>.
          </p>
          <.code_block>
            <.code_block_header>
              <.code_block_title>
                <Lucideicons.file_code /> lib/my_app_web/router.ex
              </.code_block_title>
              <.code_block_actions>
                <.code_block_copy_button id="typeset-copy" value={#{inspect(@router)}} />
              </.code_block_actions>
            </.code_block_header>
            <.code_block_content code={#{inspect(@router)}} language="elixir" line_numbers />
          </.code_block>
          <p>
            The <code>ChatLive</code> module renders each message as it arrives, so the
            answer shows while it is written.
          </p>
        </div>
        """,
        slots: []
      },
      %Variation{
        id: :rtl,
        description: "Code always reads left to right. The header follows the page direction.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-3 text-sm" dir="rtl">
          <p>ثبّت الحزم، ثم شغّل خادم التطوير.</p>
          <.code_block>
            <.code_block_header>
              <.code_block_title><Lucideicons.terminal /> الطرفية</.code_block_title>
              <.code_block_actions><.code_block_copy_button id="rtl-copy" /></.code_block_actions>
            </.code_block_header>
            <.code_block_content code={"mix deps.get\\nmix phx.server"} line_numbers />
          </.code_block>
        </div>
        """,
        slots: []
      },
      %Variation{
        id: :highlighting,
        description: "`language` highlights on the server with Makeup (an optional dependency).",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title>lib/my_app_web/live/chat_live.ex</.code_block_title>
          </.code_block_header>
          <.code_block_content code={#{inspect(@chat_live)}} language="elixir" />
          """
        ]
      },
      %Variation{
        id: :languages,
        description: "Any registered Makeup lexer. A language without a lexer renders as plain text.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-4">
          <.code_block>
            <.code_block_header><.code_block_title>lib/my_app/greeter.ex</.code_block_title></.code_block_header>
            <.code_block_content code={#{inspect(@greeter)}} language="elixir" />
          </.code_block>
          <.code_block>
            <.code_block_header><.code_block_title>greeting.html.heex</.code_block_title></.code_block_header>
            <.code_block_content code={#{inspect(@heex)}} language="html" />
          </.code_block>
          <.code_block>
            <.code_block_header><.code_block_title>notes.txt</.code_block_title></.code_block_header>
            <.code_block_content code="A language that has no lexer renders as plain text." language="text" />
          </.code_block>
        </div>
        """,
        slots: []
      },
      %Variation{
        id: :ansi,
        description: "`language=\"ansi\"` renders the colors in terminal output.",
        attributes: %{class: "w-full max-w-md"},
        slots: [
          """
          <.code_block_header>
            <.code_block_title><Lucideicons.terminal /> Terminal</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id="ansi-copy" value={SaladUI.CodeBlock.strip_ansi(#{inspect(@ansi_output)})} />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content code={#{inspect(@ansi_output)}} language="ansi" wrap />
          """
        ]
      }
    ]
  end
end
