defmodule SaladUI.Avatar do
  @moduledoc """
  Implementation of avatar component for user profile pictures with fallback support.

  Avatars are visual representations of users, typically displaying a profile picture
  or initials as a fallback. The component consists of a container, image, and fallback
  elements to ensure consistent display even when images fail to load.

  ## Examples:

      <.avatar>
        <.avatar_image src="/images/profile.jpg" alt="User avatar" />
        <.avatar_fallback>JD</.avatar_fallback>
      </.avatar>

      <.avatar size="lg">
        <.avatar_image src={@user.avatar_url} alt={@user.name} />
        <.avatar_fallback>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-6">
            <path fill-rule="evenodd" d="M18 10a8 8 0 1 1-16 0 8 8 0 0 1 16 0zm-5.5-2.5a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0zM10 12a5.99 5.99 0 0 0-4.793 2.39A6.483 6.483 0 0 0 10 16.5a6.483 6.483 0 0 0 4.793-2.11A5.99 5.99 0 0 0 10 12z" clip-rule="evenodd" />
          </svg>
        </.avatar_fallback>
      </.avatar>

  With a status badge, and stacked in a group with an overflow count:

      <.avatar>
        <.avatar_image src="/images/er.png" alt="@evilrabbit" />
        <.avatar_fallback>ER</.avatar_fallback>
        <.avatar_badge class="bg-green-600 dark:bg-green-800" />
      </.avatar>

      <.avatar_group class="grayscale">
        <.avatar :for={user <- @users}>
          <.avatar_image src={user.avatar_url} alt={user.name} />
          <.avatar_fallback>{user.initials}</.avatar_fallback>
        </.avatar>
        <.avatar_group_count>+3</.avatar_group_count>
      </.avatar_group>
  """
  use SaladUI, :component

  @doc """
  Renders an avatar container.

  The avatar container is a wrapper that holds the avatar image and fallback content.

  ## Options

  * `:size` - `"sm"` (24px), `"default"` (32px) or `"lg"` (40px). Fallback
    text, `avatar_badge/1` and `avatar_group_count/1` scale with it.
  * `:class` - Additional CSS classes to apply to the avatar container.

  ## Examples

      <.avatar>
        <.avatar_image src="/images/profile.jpg" alt="User avatar" />
        <.avatar_fallback>JD</.avatar_fallback>
      </.avatar>

      <.avatar size="sm">...</.avatar>
      <.avatar class="size-16">...</.avatar>
  """
  attr :class, :string, default: nil
  attr :size, :string, values: ~w(default sm lg), default: "default", doc: "the avatar size"
  attr :rest, :global
  slot :inner_block, required: false

  # shadcn clips with `overflow-hidden` on the root; here the image and
  # fallback are rounded instead (as in shadcn's nova style) so `avatar_badge/1`
  # can sit on the edge without being clipped.
  def avatar(assigns) do
    ~H"""
    <span
      data-slot="avatar"
      data-size={@size}
      class={
        classes([
          "group/avatar relative flex size-8 shrink-0 rounded-full select-none data-[size=lg]:size-10 data-[size=sm]:size-6",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Renders an avatar image.

  The image is set to display only after it has loaded, preventing layout shifts
  and allowing the fallback to show during loading.

  ## Options

  * `:src` - The URL of the avatar image.
  * `:alt` - The alt text for the image for accessibility.
  * `:class` - Additional CSS classes to apply to the image.

  ## Examples

      <.avatar_image src="/images/profile.jpg" alt="User profile" />
      <.avatar_image src={@user.avatar_url} alt={@user.name} class="border-2" />
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(alt src)

  # The image is absolutely positioned over `avatar_fallback/1`: while loading it
  # is transparent so the fallback shows through, once loaded it covers it, and
  # on error it removes itself. Nothing LiveView renders is mutated client-side,
  # so DOM patches are safe without `phx-update="ignore"` (which would require an id).
  def avatar_image(assigns) do
    ~H"""
    <img
      data-slot="avatar-image"
      class={classes(["absolute inset-0 aspect-square size-full rounded-full object-cover", @class])}
      onerror="this.remove()"
      {@rest}
    />
    """
  end

  @doc """
  Renders an avatar fallback element.

  The fallback is displayed when the avatar image is not available or during image loading.
  This can contain text (like user initials) or an icon.

  ## Options

  * `:class` - Additional CSS classes to apply to the fallback element.

  ## Examples

      <.avatar_fallback>JD</.avatar_fallback>

      <.avatar_fallback class="bg-primary text-primary-foreground">
        <svg><!-- User icon SVG --></svg>
      </.avatar_fallback>
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: false

  def avatar_fallback(assigns) do
    ~H"""
    <span
      data-slot="avatar-fallback"
      class={
        classes([
          "flex size-full items-center justify-center rounded-full bg-muted text-sm text-muted-foreground group-data-[size=sm]/avatar:text-xs",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  A small status dot (or icon) pinned to the bottom-right of an `avatar/1`.
  Place it inside the avatar. Its size follows the avatar's `size`; icons are
  hidden on `size="sm"`.

  ## Examples

      <.avatar>
        <.avatar_image src="/images/profile.jpg" alt="User avatar" />
        <.avatar_fallback>JD</.avatar_fallback>
        <.avatar_badge class="bg-green-600 dark:bg-green-800" />
      </.avatar>

      <.avatar_badge>
        <svg>...</svg>
      </.avatar_badge>
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: false

  def avatar_badge(assigns) do
    ~H"""
    <span
      data-slot="avatar-badge"
      class={
        classes([
          "absolute end-0 bottom-0 z-10 inline-flex items-center justify-center rounded-full bg-primary text-primary-foreground ring-2 ring-background select-none",
          "group-data-[size=sm]/avatar:size-2 group-data-[size=sm]/avatar:[&>svg]:hidden",
          "group-data-[size=default]/avatar:size-2.5 group-data-[size=default]/avatar:[&>svg]:size-2",
          "group-data-[size=lg]/avatar:size-3 group-data-[size=lg]/avatar:[&>svg]:size-2",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Stacks avatars with a slight overlap and a ring separating them.

  ## Examples

      <.avatar_group>
        <.avatar>...</.avatar>
        <.avatar>...</.avatar>
        <.avatar_group_count>+3</.avatar_group_count>
      </.avatar_group>
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar_group(assigns) do
    ~H"""
    <div
      data-slot="avatar-group"
      class={
        classes([
          "group/avatar-group flex -space-x-2 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background",
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
  The trailing "+N" (or icon) bubble in an `avatar_group/1`. It matches the
  size of the avatars in the group.

  ## Examples

      <.avatar_group_count>+3</.avatar_group_count>
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def avatar_group_count(assigns) do
    ~H"""
    <div
      data-slot="avatar-group-count"
      class={
        classes([
          "relative flex size-8 shrink-0 items-center justify-center rounded-full bg-muted text-sm text-muted-foreground ring-2 ring-background group-has-data-[size=lg]/avatar-group:size-10 group-has-data-[size=sm]/avatar-group:size-6 [&>svg]:size-4 group-has-data-[size=lg]/avatar-group:[&>svg]:size-5 group-has-data-[size=sm]/avatar-group:[&>svg]:size-3",
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
