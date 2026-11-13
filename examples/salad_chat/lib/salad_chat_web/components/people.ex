defmodule SaladChatWeb.People do
  @moduledoc "Avatars, presence and profile cards."
  use SaladChatWeb, :html

  alias SaladChat.Chat.{Timezones, User}
  alias SaladChatWeb.TimeFormat

  @statuses [
    {"active", "Active", "bg-emerald-500"},
    {"away", "Away", "bg-amber-400"},
    {"focus", "Focusing", "bg-violet-500"},
    {"vacation", "On vacation", "bg-sky-400"}
  ]

  def statuses, do: @statuses

  def status_label(status),
    do: @statuses |> List.keyfind(status, 0, {nil, "Active", nil}) |> elem(1)

  @doc """
  A user's avatar: their picture with an initials fallback, and an optional
  presence dot (`online` is `nil` to hide it).
  """
  attr :user, User, required: true
  attr :size, :string, default: "default", values: ~w(sm default lg)
  attr :online, :any, default: nil, doc: "true/false shows a presence dot; nil hides it"
  attr :class, :string, default: nil

  def user_avatar(assigns) do
    ~H"""
    <.avatar size={@size} class={@class}>
      <.avatar_image :if={@user.avatar} src={@user.avatar} alt={@user.name} />
      <.avatar_fallback class={"#{@user.color} font-medium text-white"}>
        {User.initials(@user)}
      </.avatar_fallback>
      <.avatar_badge
        :if={@online != nil}
        class={presence_class(@user, @online)}
        aria-label={if @online, do: "Online", else: "Offline"}
      />
    </.avatar>
    """
  end

  defp presence_class(%User{bot?: true}, _), do: "bg-emerald-500"
  defp presence_class(%User{status: "away"}, true), do: "bg-amber-400"
  defp presence_class(%User{status: "focus"}, true), do: "bg-violet-500"
  defp presence_class(_, true), do: "bg-emerald-500"
  defp presence_class(_, _), do: "bg-background ring-[1.5px] ring-muted-foreground/60 ring-inset"

  @doc "Online / Away / Offline, in words."
  def presence_text(%User{bot?: true}, _), do: "Always here"
  def presence_text(%User{status: status}, true) when status != "active", do: status_label(status)
  def presence_text(_, true), do: "Online"
  def presence_text(_, _), do: "Offline"

  @doc """
  The card shown in author hover cards and in the channel details sheet.
  """
  attr :user, User, required: true
  attr :online, :boolean, default: false
  attr :me, :string, required: true
  attr :class, :string, default: nil

  def profile_card(assigns) do
    ~H"""
    <div class={["flex w-72 flex-col gap-3", @class]}>
      <div class="flex items-start gap-3">
        <.user_avatar user={@user} size="lg" online={@online} class="size-12" />
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-1.5">
            <p class="truncate font-semibold">{@user.name}</p>
            <.badge :if={@user.bot?} variant="secondary" class="h-4 px-1 text-[10px]">APP</.badge>
          </div>
          <p class="truncate text-sm text-muted-foreground">{@user.title}</p>
          <p class="text-xs text-muted-foreground">
            @{@user.handle} · {presence_text(@user, @online)}
          </p>
        </div>
      </div>
      <p :if={@user.status_text} class="rounded-md bg-muted px-2 py-1 text-xs">{@user.status_text}</p>
      <p :if={@user.bio != ""} class="text-sm leading-snug">{@user.bio}</p>
      <p :if={!@user.bot?} class="flex items-center gap-1.5 text-xs text-muted-foreground">
        <.icon name="hero-clock" class="size-3.5" />
        {TimeFormat.time(DateTime.utc_now(), @user.timezone)} local time · {Timezones.label(
          @user.timezone
        )}
      </p>
      <.button
        :if={@user.handle != @me}
        size="sm"
        variant="outline"
        phx-click={JS.push("open_dm", value: %{handle: @user.handle})}
      >
        <.icon name="hero-chat-bubble-left-right" /> Message
      </.button>
    </div>
    """
  end

  @doc "The app mark: a leaf in a rounded square."
  attr :class, :string, default: "size-8"

  def logo(assigns) do
    ~H"""
    <span class={[
      "inline-flex shrink-0 items-center justify-center rounded-lg bg-primary text-primary-foreground",
      @class
    ]}>
      <svg viewBox="0 0 24 24" fill="none" class="size-[60%]" aria-hidden="true">
        <path d="M12 20v-8" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <path d="M12 13c0-5-3.5-8-8.5-8 0 5 3.5 8 8.5 8Z" fill="currentColor" />
        <path d="M12 11c0-4.5 3-7 7.5-7 0 4.5-3 7-7.5 7Z" fill="currentColor" opacity=".7" />
      </svg>
    </span>
    """
  end
end
