defmodule SaladChatWeb.LandingLive do
  @moduledoc """
  "Who are you today?" There is no auth: pick a seeded person and the chat
  opens at `/as/:handle/c/general`. Open a second tab as someone else to see
  messages, typing and presence move between them.
  """
  use SaladChatWeb, :live_view

  import SaladChatWeb.People

  alias SaladChat.Chat
  alias SaladChatWeb.{Paths, Presence}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(SaladChat.PubSub, Presence.topic())

    {:ok,
     assign(socket,
       page_title: "Pick a user",
       users: Chat.list_users(bots: false),
       online: Presence.online_handles()
     )}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, online: Presence.online_handles())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-svh bg-gradient-to-b from-primary/10 via-background to-background">
        <main class="mx-auto flex max-w-3xl flex-col gap-10 px-4 py-14 sm:py-20">
          <header class="flex flex-col items-center gap-4 text-center">
            <.logo class="size-14 rounded-2xl shadow-sm" />
            <div class="flex flex-col gap-2">
              <h1 class="text-3xl font-bold tracking-tight sm:text-4xl">Salad Chat</h1>
              <p class="max-w-xl text-balance text-muted-foreground">
                A team chat built entirely with SaladUI and Phoenix LiveView.
                Pick someone to sign in as. Open another tab as a teammate to watch
                messages, typing and presence sync in real time.
              </p>
            </div>
            <div class="flex flex-wrap justify-center gap-2">
              <.badge variant="secondary">
                <.icon name="hero-bolt" class="size-3" /> LiveView streams
              </.badge>
              <.badge variant="secondary">
                <.icon name="hero-sparkles" class="size-3" /> AI assistant
              </.badge>
              <.badge variant="outline">No database · resets on restart</.badge>
            </div>
          </header>

          <section aria-labelledby="pick-user">
            <h2 id="pick-user" class="mb-3 text-sm font-medium text-muted-foreground">
              Greenhouse workspace · {length(@users)} people
            </h2>
            <.item_group class="grid gap-3 sm:grid-cols-2">
              <.item
                :for={user <- @users}
                id={"pick-#{user.handle}"}
                variant="outline"
                navigate={Paths.channel_path(user.handle, "general")}
                class="bg-card shadow-xs transition-shadow hover:shadow-md"
              >
                <.item_media>
                  <.user_avatar
                    user={user}
                    size="lg"
                    online={MapSet.member?(@online, user.handle)}
                    class="size-11"
                  />
                </.item_media>
                <.item_content>
                  <.item_title>{user.name}</.item_title>
                  <.item_description>{user.title}</.item_description>
                </.item_content>
                <.item_actions>
                  <span
                    :if={MapSet.member?(@online, user.handle)}
                    class="text-xs text-emerald-600 dark:text-emerald-400"
                  >
                    online
                  </span>
                  <.icon name="hero-chevron-right" class="size-4 text-muted-foreground" />
                </.item_actions>
              </.item>
            </.item_group>
          </section>

          <footer class="text-center text-xs text-muted-foreground">
            Made with <a
              href="https://github.com/bluzky/salad_ui"
              class="underline underline-offset-2"
            >SaladUI</a>,
            a shadcn/ui port for Phoenix. All people, messages and pictures are made up.
          </footer>
        </main>
      </div>
    </Layouts.app>
    """
  end
end
