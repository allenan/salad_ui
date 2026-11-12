defmodule Storybook.SaladUIComponents.Trace do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Badge
  alias SaladUI.Bubble
  alias SaladUI.Button
  alias SaladUI.Dialog
  alias SaladUI.Message
  alias SaladUI.Sheet
  alias SaladUI.Trace

  def function, do: &Trace.trace/1
  def layout, do: :one_column

  def imports,
    do: [
      {Trace,
       [
         trace_line: 1,
         trace_icon: 1,
         trace_title: 1,
         trace_description: 1,
         trace_collapsible: 1,
         trace_collapsible_trigger: 1,
         trace_collapsible_content: 1
       ]},
      {Dialog,
       [dialog: 1, dialog_trigger: 1, dialog_content: 1, dialog_header: 1, dialog_title: 1, dialog_description: 1]},
      {Sheet, [sheet: 1, sheet_trigger: 1, sheet_content: 1, sheet_header: 1, sheet_title: 1, sheet_description: 1]},
      {Message, [message: 1, message_content: 1]},
      {Bubble, [bubble: 1, bubble_content: 1]},
      {Badge, [badge: 1]},
      {Button, [button: 1]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  # shadcn's examples use a CodeBlock component SaladUI doesn't have yet.
  @code "max-h-64 overflow-auto rounded-md bg-muted p-3 font-mono text-xs whitespace-pre-wrap text-foreground"
  @code_error "max-h-64 overflow-auto rounded-md bg-destructive/10 p-3 font-mono text-xs whitespace-pre-wrap text-destructive"

  def variations do
    [
      %Variation{
        id: :demo,
        description: "A finished agent turn: reasoning, tool calls (one failed, open) and sources.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-4 py-6 text-sm">
          <.message align="end">
            <.message_content>
              <.bubble align="end" variant="muted">
                <.bubble_content>Why does pnpm install fail in CI?</.bubble_content>
              </.bubble>
            </.message_content>
          </.message>
          <.message>
            <.message_content class="gap-4">
              <.trace>
                <.trace_collapsible id="demo-thought">
                  <.trace_collapsible_trigger>
                    <.trace_line>
                      <.trace_icon><.icon name="hero-check-circle" class="size-4" /></.trace_icon>
                      <.trace_title>Thought for 5s</.trace_title>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content class="whitespace-pre-wrap">CI installs with a frozen lockfile, so the install stops when package.json and pnpm-lock.yaml disagree. I should check what the last commit changed, then reproduce the install.</.trace_collapsible_content>
                </.trace_collapsible>
                <.trace_collapsible id="demo-pnpm-version">
                  <.trace_collapsible_trigger>
                    <.trace_line>
                      <.trace_icon><.icon name="hero-check-circle" class="size-4" /></.trace_icon>
                      <.trace_title>Ran pnpm --version</.trace_title>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content><pre class="#{@code}">10.18.0</pre></.trace_collapsible_content>
                </.trace_collapsible>
                <.trace_collapsible id="demo-git-diff">
                  <.trace_collapsible_trigger>
                    <.trace_line>
                      <.trace_icon><.icon name="hero-check-circle" class="size-4" /></.trace_icon>
                      <.trace_title>Ran git diff --stat HEAD~1 -- package.json pnpm-lock.yaml</.trace_title>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content><pre class="#{@code}"> package.json | 2 +-
         1 file changed, 1 insertion(+), 1 deletion(-)</pre></.trace_collapsible_content>
                </.trace_collapsible>
                <.trace_collapsible id="demo-install" open>
                  <.trace_collapsible_trigger>
                    <.trace_line status="error">
                      <.trace_icon><.icon name="hero-exclamation-circle" class="size-4" /></.trace_icon>
                      <.trace_title>Failed to run pnpm install --frozen-lockfile</.trace_title>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content><pre class="#{@code_error}">ERR_PNPM_OUTDATED_LOCKFILE  Cannot install with "frozen-lockfile" because pnpm-lock.yaml is not up to date with package.json</pre></.trace_collapsible_content>
                </.trace_collapsible>
                <.trace_collapsible id="demo-sources">
                  <.trace_collapsible_trigger>
                    <.trace_line>
                      <.trace_icon><.icon name="hero-globe-alt" class="size-4" /></.trace_icon>
                      <.trace_title>Used 2 sources</.trace_title>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content>
                    <.trace>
                      <a href="https://pnpm.io/cli/install#--frozen-lockfile" target="_blank" rel="noreferrer">
                        <.trace_line>
                          <.trace_icon><.icon name="hero-globe-alt" class="size-4" /></.trace_icon>
                          <.trace_title>pnpm install | pnpm.io<span class="sr-only"> (opens in a new tab)</span></.trace_title>
                          <.trace_icon><.icon name="hero-arrow-up-right" class="size-4" /></.trace_icon>
                        </.trace_line>
                      </a>
                      <a href="https://pnpm.io/continuous-integration" target="_blank" rel="noreferrer">
                        <.trace_line>
                          <.trace_icon><.icon name="hero-globe-alt" class="size-4" /></.trace_icon>
                          <.trace_title>Continuous Integration | pnpm.io<span class="sr-only"> (opens in a new tab)</span></.trace_title>
                          <.trace_icon><.icon name="hero-arrow-up-right" class="size-4" /></.trace_icon>
                        </.trace_line>
                      </a>
                    </.trace>
                  </.trace_collapsible_content>
                </.trace_collapsible>
              </.trace>
              <p>The last commit bumped a version in package.json without updating pnpm-lock.yaml, so the frozen install fails. Run pnpm install locally and commit the lockfile.</p>
            </.message_content>
          </.message>
        </div>
        """
      },
      %Variation{
        id: :static,
        description: "A `trace_line` on its own reads as plain text.",
        template: """
        <.trace class="max-w-sm">
          <.trace_line>
            <.trace_icon><.icon name="hero-arrows-right-left" class="size-4" /></.trace_icon>
            <.trace_title>Created branch fix/frozen-lockfile</.trace_title>
          </.trace_line>
        </.trace>
        """
      },
      %Variation{
        id: :status,
        template: """
        <.trace class="max-w-sm">
          <.trace_line>
            <.trace_icon><.icon name="hero-check-circle" class="size-4" /></.trace_icon>
            <.trace_title>Ran pnpm install</.trace_title>
          </.trace_line>
          <.trace_line status="error">
            <.trace_icon><.icon name="hero-exclamation-circle" class="size-4" /></.trace_icon>
            <.trace_title>Failed to run pnpm lint</.trace_title>
          </.trace_line>
          <.trace_line status="running">
            <.trace_icon><.icon name="hero-arrow-path" class="size-4 animate-spin" /></.trace_icon>
            <.trace_title>Running pnpm build</.trace_title>
          </.trace_line>
          <.trace_line status="pending">
            <.trace_icon><.icon name="hero-stop-circle" class="size-4" /></.trace_icon>
            <.trace_title>Run pnpm test</.trace_title>
          </.trace_line>
        </.trace>
        """
      },
      %Variation{
        id: :description,
        template: """
        <.trace class="max-w-sm">
          <.trace_line>
            <.trace_icon><.icon name="hero-pencil-square" class="size-4" /></.trace_icon>
            <.trace_title>Edited components/settings/notification-preferences-form.tsx</.trace_title>
            <.trace_description class="font-mono">+48 −12</.trace_description>
          </.trace_line>
          <.trace_line>
            <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
            <.trace_title>Ran pnpm test</.trace_title>
            <.trace_description>14s</.trace_description>
          </.trace_line>
          <.trace_line>
            <.trace_icon><.icon name="hero-magnifying-glass" class="size-4" /></.trace_icon>
            <.trace_title>Searched for useChat</.trace_title>
            <.trace_description>8 results</.trace_description>
          </.trace_line>
        </.trace>
        """
      },
      %Variation{
        id: :collapsible,
        template: """
        <div class="w-full max-w-sm">
          <.trace_collapsible id="trace-collapsible">
            <.trace_collapsible_trigger>
              <.trace_line>
                <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
                <.trace_title>Ran node --version</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content><pre class="#{@code}">$ node --version
        v24.18.0</pre></.trace_collapsible_content>
          </.trace_collapsible>
        </div>
        """
      },
      %Variation{
        id: :open_state,
        description:
          "`open` starts a row open. Drive a row from elsewhere with `SaladUI.JS.dispatch_command/3` (or `SaladUI.LiveView.send_command/4` from the server).",
        template: """
        <div class="flex w-full max-w-sm flex-col items-start gap-4">
          <.trace_collapsible id="trace-open-node" open>
            <.trace_collapsible_trigger>
              <.trace_line>
                <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
                <.trace_title>Ran node --version</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content><pre class="#{@code}">$ node --version
        v24.18.0</pre></.trace_collapsible_content>
          </.trace_collapsible>
          <.trace_collapsible id="trace-open-pnpm">
            <.trace_collapsible_trigger>
              <.trace_line>
                <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
                <.trace_title>Ran pnpm --version</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content><pre class="#{@code}">$ pnpm --version
        10.33.4</pre></.trace_collapsible_content>
          </.trace_collapsible>
          <.button
            variant="outline"
            size="sm"
            phx-click={SaladUI.JS.dispatch_command(%Phoenix.LiveView.JS{}, "toggle", to: "#trace-open-pnpm")}
          >
            Toggle the pnpm output
          </.button>
        </div>
        """
      },
      %Variation{
        id: :link,
        description: "Wrap the line in an anchor. For a new tab, use an arrow-up-right icon and an sr-only note.",
        template: """
        <.trace class="max-w-sm">
          <a href="#link">
            <.trace_line>
              <.trace_icon><.icon name="hero-document-text" class="size-4" /></.trace_icon>
              <.trace_title>Read apps/v4/lib/docs.ts</.trace_title>
              <.trace_icon><.icon name="hero-chevron-right" class="size-4" /></.trace_icon>
            </.trace_line>
          </a>
          <a href="https://docs.astro.build/en/install-and-setup/" target="_blank" rel="noreferrer">
            <.trace_line>
              <.trace_icon><.icon name="hero-globe-alt" class="size-4" /></.trace_icon>
              <.trace_title>Install Astro | docs.astro.build<span class="sr-only"> (opens in a new tab)</span></.trace_title>
              <.trace_icon><.icon name="hero-arrow-up-right" class="size-4" /></.trace_icon>
            </.trace_line>
          </a>
        </.trace>
        """
      },
      %Variation{
        id: :dialog,
        description: "Wrap the line in the dialog's trigger (`as=\"button\"`, so it is focusable).",
        template: """
        <.trace class="max-w-sm">
          <.dialog id="trace-dialog">
            <.dialog_trigger as="button">
              <.trace_line>
                <.trace_icon><.icon name="hero-globe-alt" class="size-4" /></.trace_icon>
                <.trace_title>Searched the web for cache keys</.trace_title>
                <.trace_icon><.icon name="hero-chevron-right" class="size-4" /></.trace_icon>
              </.trace_line>
            </.dialog_trigger>
            <.dialog_content>
              <.dialog_header>
                <.dialog_title>Searched the web for cache keys</.dialog_title>
                <.dialog_description>Three results were used in the response.</.dialog_description>
              </.dialog_header>
              <.trace>
                <a
                  :for={{title, url} <- [{"Caching build outputs", "https://nextjs.org/docs/app/guides/caching"}, {"Image optimization reference", "https://nextjs.org/docs/app/api-reference/components/image"}, {"Deploy hooks and cache keys", "https://vercel.com/docs/deploy-hooks"}]}
                  href={url}
                  target="_blank"
                  rel="noreferrer"
                >
                  <.trace_line>
                    <.trace_icon><.icon name="hero-globe-alt" class="size-4" /></.trace_icon>
                    <.trace_title>{title}<span class="sr-only"> (opens in a new tab)</span></.trace_title>
                    <.trace_icon><.icon name="hero-arrow-up-right" class="size-4" /></.trace_icon>
                  </.trace_line>
                </a>
              </.trace>
            </.dialog_content>
          </.dialog>
        </.trace>
        """
      },
      %Variation{
        id: :sheet,
        description: "The same shape as the dialog: put the line in the sheet's trigger.",
        template: """
        <.trace class="max-w-sm">
          <.sheet id="trace-sheet">
            <.sheet_trigger role="button" tabindex="0">
              <.trace_line>
                <.trace_icon><.icon name="hero-folder-open" class="size-4" /></.trace_icon>
                <.trace_title>Explored 4 files</.trace_title>
                <.trace_icon><.icon name="hero-chevron-right" class="size-4" /></.trace_icon>
              </.trace_line>
            </.sheet_trigger>
            <.sheet_content>
              <.sheet_header>
                <.sheet_title>Explored 4 files</.sheet_title>
                <.sheet_description>Files read while preparing the response.</.sheet_description>
              </.sheet_header>
              <ul class="flex flex-col gap-2 px-6 font-mono text-xs">
                <li>apps/v4/lib/docs.ts</li>
                <li>apps/v4/lib/components.ts</li>
                <li>apps/v4/next.config.mjs</li>
                <li>apps/v4/package.json</li>
              </ul>
            </.sheet_content>
          </.sheet>
        </.trace>
        """
      },
      %Variation{
        id: :group,
        template: """
        <.trace class="max-w-sm">
          <.trace_line>
            <.trace_icon><.icon name="hero-magnifying-glass" class="size-4" /></.trace_icon>
            <.trace_title>Searched for minimumReleaseAge</.trace_title>
          </.trace_line>
          <.trace_line>
            <.trace_icon><.icon name="hero-document-text" class="size-4" /></.trace_icon>
            <.trace_title>Read pnpm-workspace.yaml</.trace_title>
          </.trace_line>
          <.trace_line>
            <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
            <.trace_title>Ran pnpm install</.trace_title>
          </.trace_line>
        </.trace>
        """
      },
      %Variation{
        id: :sources,
        description: "A collapsible row whose detail is a trace of link rows.",
        template: """
        <div class="w-full max-w-sm">
          <.trace_collapsible id="trace-sources" open>
            <.trace_collapsible_trigger>
              <.trace_line>
                <.trace_icon><.icon name="hero-globe-alt" class="size-4" /></.trace_icon>
                <.trace_title>Used 3 sources</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content>
              <.trace>
                <a
                  :for={{title, href} <- [{"Install Astro | docs.astro.build", "https://docs.astro.build/en/install-and-setup/"}, {"create-astro | npmjs.com", "https://www.npmjs.com/package/create-astro"}, {"Settings: minimumReleaseAge | pnpm.io", "https://pnpm.io/settings#minimumreleaseage"}]}
                  href={href}
                  target="_blank"
                  rel="noreferrer"
                >
                  <.trace_line>
                    <.trace_icon><.icon name="hero-globe-alt" class="size-4" /></.trace_icon>
                    <.trace_title>{title}<span class="sr-only"> (opens in a new tab)</span></.trace_title>
                    <.trace_icon><.icon name="hero-arrow-up-right" class="size-4" /></.trace_icon>
                  </.trace_line>
                </a>
              </.trace>
            </.trace_collapsible_content>
          </.trace_collapsible>
        </div>
        """
      },
      %Variation{
        id: :chain_of_thought,
        description: "A collapsible row with step rows inside. Set the parent's status and title from its children.",
        template: """
        <div class="w-full max-w-sm">
          <.trace_collapsible id="cot" open>
            <.trace_collapsible_trigger>
              <.trace_line status="running">
                <.trace_title>Looking into the slow deploy</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content>
              <.trace>
                <.trace_collapsible id="cot-search">
                  <.trace_collapsible_trigger>
                    <.trace_line>
                      <.trace_icon><.icon name="hero-magnifying-glass" class="size-4" /></.trace_icon>
                      <.trace_title>Searched for the checkout build log</.trace_title>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content class="flex flex-wrap gap-1.5">
                    <.badge variant="secondary">vercel.com</.badge>
                    <.badge variant="secondary">github.com</.badge>
                  </.trace_collapsible_content>
                </.trace_collapsible>
                <a href="#steps">
                  <.trace_line>
                    <.trace_icon><.icon name="hero-document-text" class="size-4" /></.trace_icon>
                    <.trace_title>Read the last twelve deploys</.trace_title>
                    <.trace_icon><.icon name="hero-chevron-right" class="size-4" /></.trace_icon>
                  </.trace_line>
                </a>
                <.trace_collapsible id="cot-cache-key">
                  <.trace_collapsible_trigger>
                    <.trace_line status="running">
                      <.trace_icon><.icon name="hero-magnifying-glass" class="size-4" /></.trace_icon>
                      <.trace_title>Searching for the cache key</.trace_title>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content><pre class="#{@code}">cache key image optimization</pre></.trace_collapsible_content>
                </.trace_collapsible>
              </.trace>
            </.trace_collapsible_content>
          </.trace_collapsible>
        </div>
        """
      },
      %Variation{
        id: :commit,
        description: "A line for each changed file; each opens its diff in a sheet.",
        template: """
        <.trace class="max-w-sm">
          <.trace_collapsible id="commit" open>
            <.trace_collapsible_trigger>
              <.trace_line>
                <.trace_icon><.icon name="hero-code-bracket-square" class="size-4" /></.trace_icon>
                <.trace_title>Committed a1b2c3: Fix the login redirect</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content>
              <.trace>
                <.sheet id="commit-login-page">
                  <.sheet_trigger role="button" tabindex="0">
                    <.trace_line>
                      <.trace_icon><.icon name="hero-pencil-square" class="size-4" /></.trace_icon>
                      <.trace_title>Edited app/login/page.tsx</.trace_title>
                      <.trace_description class="font-mono">+2 −2</.trace_description>
                      <.trace_icon><.icon name="hero-chevron-right" class="size-4" /></.trace_icon>
                    </.trace_line>
                  </.sheet_trigger>
                  <.sheet_content>
                    <.sheet_header>
                      <.sheet_title class="font-mono">app/login/page.tsx</.sheet_title>
                      <.sheet_description>2 additions, 2 deletions</.sheet_description>
                    </.sheet_header>
                    <pre class="mx-6 mb-6 overflow-auto rounded-md bg-muted p-3 font-mono text-xs text-foreground"><span class="text-muted-foreground">@@ -14,7 +14,7 @@ export default async function LoginPage(&lbrace;</span>
        <span class="block bg-destructive/10 text-destructive">  const redirectTo =</span><span class="block bg-destructive/10 text-destructive">    next &amp;&amp; next.startsWith("/") ? next : "/"</span><span class="block bg-emerald-500/10 text-emerald-700 dark:text-emerald-400">  const redirectTo = safeRedirect(next)</span>  return &lt;LoginForm redirectTo=&lbrace;redirectTo&rbrace; /&gt;</pre>
                  </.sheet_content>
                </.sheet>
                <.sheet id="commit-redirect">
                  <.sheet_trigger role="button" tabindex="0">
                    <.trace_line>
                      <.trace_icon><.icon name="hero-document-plus" class="size-4" /></.trace_icon>
                      <.trace_title>Added lib/auth/redirect.ts</.trace_title>
                      <.trace_description class="font-mono">+7 −0</.trace_description>
                      <.trace_icon><.icon name="hero-chevron-right" class="size-4" /></.trace_icon>
                    </.trace_line>
                  </.sheet_trigger>
                  <.sheet_content>
                    <.sheet_header>
                      <.sheet_title class="font-mono">lib/auth/redirect.ts</.sheet_title>
                      <.sheet_description>7 additions, 0 deletions</.sheet_description>
                    </.sheet_header>
                    <pre class="mx-6 mb-6 overflow-auto rounded-md bg-emerald-500/10 p-3 font-mono text-xs text-emerald-700 dark:text-emerald-400">export function safeRedirect(next: string | undefined) &lbrace;
          if (!next || !next.startsWith("/") || next.startsWith("//")) &lbrace;
            return "/"
          &rbrace;

          return next
        &rbrace;</pre>
                  </.sheet_content>
                </.sheet>
              </.trace>
            </.trace_collapsible_content>
          </.trace_collapsible>
        </.trace>
        """
      },
      %Variation{
        id: :whole_turn,
        description: "Three levels: the turn, a summary, and the rows. Text between steps sits between two traces.",
        template: """
        <div class="w-full max-w-sm">
          <.trace_collapsible id="turn" open>
            <.trace_collapsible_trigger>
              <.trace_line status="error">
                <.trace_title>Worked for 2m 4s, 1 command failed</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content class="flex flex-col gap-2">
              <.trace>
                <.trace_collapsible id="turn-thought">
                  <.trace_collapsible_trigger>
                    <.trace_line>
                      <.trace_icon><.icon name="hero-light-bulb" class="size-4" /></.trace_icon>
                      <.trace_title>Thought</.trace_title>
                      <.trace_description>12s</.trace_description>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content class="whitespace-pre-wrap">I should check which package managers are installed before I scaffold anything.</.trace_collapsible_content>
                </.trace_collapsible>
                <.trace_collapsible id="turn-commands" open>
                  <.trace_collapsible_trigger>
                    <.trace_line status="error">
                      <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
                      <.trace_title>Ran 2 commands, 1 failed</.trace_title>
                    </.trace_line>
                  </.trace_collapsible_trigger>
                  <.trace_collapsible_content>
                    <.trace>
                      <.trace_line>
                        <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
                        <.trace_title>Ran node --version</.trace_title>
                      </.trace_line>
                      <.trace_collapsible id="turn-pnpm">
                        <.trace_collapsible_trigger>
                          <.trace_line status="error">
                            <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
                            <.trace_title>Failed to run pnpm --version</.trace_title>
                          </.trace_line>
                        </.trace_collapsible_trigger>
                        <.trace_collapsible_content><pre class="#{@code_error}">command not found: pnpm</pre></.trace_collapsible_content>
                      </.trace_collapsible>
                    </.trace>
                  </.trace_collapsible_content>
                </.trace_collapsible>
              </.trace>
              <p>Node is installed and pnpm is not. Reading the docs config.</p>
              <.trace>
                <a href="#turn">
                  <.trace_line>
                    <.trace_icon><.icon name="hero-document-text" class="size-4" /></.trace_icon>
                    <.trace_title>Read apps/v4/lib/docs.ts</.trace_title>
                    <.trace_icon><.icon name="hero-chevron-right" class="size-4" /></.trace_icon>
                  </.trace_line>
                </a>
              </.trace>
            </.trace_collapsible_content>
          </.trace_collapsible>
        </div>
        """
      },
      %Variation{
        id: :reasoning,
        description:
          "Reasoning rows while streaming and after. In a LiveView, bind `open` to the streaming flag (`open={@streaming}`) and the row opens while it streams; render a bare `trace_line` until the first text arrives.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-4 py-6 text-sm">
          <.trace>
            <.trace_line status="running">
              <.trace_icon><.icon name="hero-light-bulb" class="size-4" /></.trace_icon>
              <.trace_title>Thinking</.trace_title>
            </.trace_line>
          </.trace>
          <.trace>
            <.trace_collapsible id="reasoning-streaming" open>
              <.trace_collapsible_trigger>
                <.trace_line status="running">
                  <.trace_icon><.icon name="hero-light-bulb" class="size-4" /></.trace_icon>
                  <.trace_title>Thinking</.trace_title>
                </.trace_line>
              </.trace_collapsible_trigger>
              <.trace_collapsible_content class="whitespace-pre-wrap">The build log shows install and compile finish in under a minute. Image optimization takes almost four...</.trace_collapsible_content>
            </.trace_collapsible>
          </.trace>
          <.trace>
            <.trace_collapsible id="reasoning-done">
              <.trace_collapsible_trigger>
                <.trace_line>
                  <.trace_icon><.icon name="hero-light-bulb" class="size-4" /></.trace_icon>
                  <.trace_title>Thought</.trace_title>
                </.trace_line>
              </.trace_collapsible_trigger>
              <.trace_collapsible_content class="whitespace-pre-wrap">The build log shows install and compile finish in under a minute. Image optimization takes almost four, and it reruns on every deploy because the cache key includes the commit hash.</.trace_collapsible_content>
            </.trace_collapsible>
          </.trace>
          <p>Image optimization is the bottleneck. Key its cache on the lockfile and the image directory instead of the commit hash.</p>
        </div>
        """
      },
      %Variation{
        id: :tool_calls,
        description: "Tool calls by state: running, done (output on expand), failed and denied.",
        template: """
        <.trace class="max-w-sm">
          <.trace_collapsible id="tool-node">
            <.trace_collapsible_trigger>
              <.trace_line>
                <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
                <.trace_title>Ran node --version</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content><pre class="#{@code}">v24.18.0</pre></.trace_collapsible_content>
          </.trace_collapsible>
          <.trace_collapsible id="tool-pnpm">
            <.trace_collapsible_trigger>
              <.trace_line status="error">
                <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
                <.trace_title>Failed to run pnpm --version</.trace_title>
              </.trace_line>
            </.trace_collapsible_trigger>
            <.trace_collapsible_content><pre class="#{@code}">command not found: pnpm</pre></.trace_collapsible_content>
          </.trace_collapsible>
          <.trace_line status="running">
            <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
            <.trace_title>Running npm --version</.trace_title>
          </.trace_line>
          <.trace_line>
            <.trace_icon><.icon name="hero-command-line" class="size-4" /></.trace_icon>
            <.trace_title>Denied rm -rf node_modules</.trace_title>
          </.trace_line>
        </.trace>
        """
      }
    ]
  end
end
