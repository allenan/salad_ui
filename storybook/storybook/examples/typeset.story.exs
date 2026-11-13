defmodule Storybook.Examples.Typeset do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Badge
  import SaladUI.Card
  import SaladUI.CodeBlock

  def doc do
    """
    shadcn/typeset, shipped as the opt-in `priv/static/assets/typeset.css`. Everything inside a
    `typeset` container (rendered markdown, chat replies, docs) gets its type rhythm from three
    variables: `--typeset-size`, `--typeset-leading` and `--typeset-flow`. Components (anything
    with `data-slot`) keep their own styles; `not-typeset` opts a subtree out; `typeset-scroll`
    scrolls a wide table.
    """
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-10 py-6 lg:grid-cols-2">
      <section class="flex min-w-0 flex-col gap-3">
        <p class="font-mono text-xs text-muted-foreground">typeset</p>
        <article id="typeset-article" class="typeset">
          <h1>Shipping a LiveView chat</h1>
          <p>
            A <strong>LiveView</strong>
            keeps state on the server and sends <em>diffs</em>. Read the <a href="#">streams guide</a>
            first, and press <kbd>Ctrl</kbd>
            + <kbd>K</kbd>
            to search.
          </p>
          <h2>Install</h2>
          <ol>
            <li>Add <code>salad_ui</code> to your deps.</li>
            <li>
              Run the installer.
              <ul>
                <li>It copies <code>salad_ui.css</code>.</li>
                <li>It registers the hook.</li>
              </ul>
            </li>
          </ol>
          <.code_block>
            <.code_block_header>
              <.code_block_title>Terminal</.code_block_title>
            </.code_block_header>
            <.code_block_content code="mix igniter.install salad_ui" />
          </.code_block>
          <blockquote>
            <p>Typeset never restyles a block that is already on screen when a new one streams in.</p>
          </blockquote>
          <h3>Options</h3>
          <div class="typeset-scroll">
            <table>
              <thead>
                <tr>
                  <th>Variable</th>
                  <th>Default</th>
                  <th>Controls</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><code>--typeset-size</code></td>
                  <td>1em</td>
                  <td>Base text size, follows the container</td>
                </tr>
                <tr>
                  <td><code>--typeset-leading</code></td>
                  <td>1.75</td>
                  <td>Line height</td>
                </tr>
                <tr>
                  <td><code>--typeset-flow</code></td>
                  <td>1.25em</td>
                  <td>Space between blocks</td>
                </tr>
              </tbody>
            </table>
          </div>
          <hr />
          <h4>Opting out</h4>
          <.card class="not-typeset">
            <.card_header>
              <.card_title>Untouched component</.card_title>
              <.card_description>
                <p>A paragraph inside <code>not-typeset</code> keeps the card's styles.</p>
              </.card_description>
            </.card_header>
          </.card>
          <p>
            A
            <.badge variant="secondary">badge</.badge>
            inline keeps its own styles too.
          </p>
        </article>
      </section>

      <section class="flex min-w-0 flex-col gap-3">
        <p class="font-mono text-xs text-muted-foreground">
          typeset text-sm [--typeset-flow:1em] [--typeset-leading:1.6] (a chat preset)
        </p>
        <div class="typeset rounded-xl bg-muted/50 p-4 text-sm [--typeset-flow:1em] [--typeset-leading:1.6]">
          <p>Wrap the input in a form and debounce the change event:</p>
          <.code_block>
            <.code_block_content code={~s(<.input field={@form[:query]} phx-debounce="300" />)} />
          </.code_block>
          <p>Then handle <code>"search"</code> in your LiveView.</p>
        </div>

        <p class="mt-6 font-mono text-xs text-muted-foreground">
          typeset [--typeset-size:15px] [--typeset-flow:1.5em] (a docs preset)
        </p>
        <div class="typeset [--typeset-size:15px] [--typeset-flow:1.5em]">
          <h2>Heading</h2>
          <p>
            Headings own the space below them; every block adds its own space above, so
            appending never moves what came before.
          </p>
          <ul class="contains-task-list">
            <li class="task-list-item"><input type="checkbox" checked disabled /> Port typeset</li>
            <li class="task-list-item"><input type="checkbox" disabled /> Write the docs</li>
          </ul>
        </div>
      </section>
    </div>
    """
  end
end
