defmodule SaladUI.DropdownMenuTest do
  use ComponentCase

  import SaladUI.Button
  import SaladUI.DropdownMenu
  import SaladUI.Icon
  import SaladUI.Menu

  describe "Test Dropdown menu" do
    test "It renders dropdown trigger correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_trigger as={&button/1} variant="outline">
          Click me
        </.dropdown_menu_trigger>
        """)

      assert html =~ "Click me"

      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(type="button")
    end

    test "It renders dropdown menu content correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_content>
          <.menu class="w-56">
            <.menu_label>Account</.menu_label>
            <.menu_separator />
            <.menu_group>
              <.menu_item>
                <.icon name="hero-user" class="mr-2 size-4" />
                <span>Profile</span>
                <.menu_shortcut>⌘P</.menu_shortcut>
              </.menu_item>
              <.menu_item>
                <.icon name="hero-banknotes" class="mr-2 size-4" />
                <span>Billing</span>
                <.menu_shortcut>⌘B</.menu_shortcut>
              </.menu_item>
              <.menu_item>
                <.icon name="hero-cog-6-tooth" class="mr-2 size-4" />
                <span>Settings</span>
                <.menu_shortcut>⌘S</.menu_shortcut>
              </.menu_item>
            </.menu_group>
            <.menu_separator />
            <.menu_group>
              <.menu_item>
                <.icon name="hero-users" class="mr-2 size-4" />
                <span>Team</span>
              </.menu_item>
              <.menu_item disabled>
                <.icon name="hero-plus" class="mr-2 size-4" />
                <span>New team</span>
                <.menu_shortcut>⌘T</.menu_shortcut>
              </.menu_item>
            </.menu_group>
          </.menu>
        </.dropdown_menu_content>
        """)

      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="center")

      for css_class <-
            ~w(z-50 animate-in data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2) do
        assert html =~ css_class
      end
    end

    test "It renderes dropdown menu correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <div class="mt-24">
          <.dropdown_menu id="dropdown-test">
            <.dropdown_menu_trigger as={&button/1} variant="outline">
              Click me
            </.dropdown_menu_trigger>
            <.dropdown_menu_content>
              <.menu class="w-56">
                <.menu_label>Account</.menu_label>
                <.menu_separator />
                <.menu_group>
                  <.menu_item>
                    <.icon name="hero-user" class="mr-2 size-4" /> <span>Profile</span>
                    <.menu_shortcut>⌘P</.menu_shortcut>
                  </.menu_item>

                  <.menu_item>
                    <.icon name="hero-banknotes" class="mr-2 size-4" /> <span>Billing</span>
                    <.menu_shortcut>⌘B</.menu_shortcut>
                  </.menu_item>

                  <.menu_item>
                    <.icon name="hero-cog-6-tooth" class="mr-2 size-4" /> <span>Settings</span>
                    <.menu_shortcut>⌘S</.menu_shortcut>
                  </.menu_item>
                </.menu_group>
                <.menu_separator />
                <.menu_group>
                  <.menu_item>
                    <.icon name="hero-users" class="mr-2 size-4" /> <span>Team</span>
                  </.menu_item>

                  <.menu_item disabled>
                    <.icon name="hero-plus" class="mr-2 size-4" /> <span>New team</span>
                    <.menu_shortcut>⌘T</.menu_shortcut>
                  </.menu_item>
                </.menu_group>
              </.menu>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """)

      assert html =~ "<span>Profile</span>"
      assert html =~ "<span>Billing</span>"
      assert html =~ "<span>Settings</span>"
      assert html =~ "<span>New team</span>"
      assert html =~ "⌘T"
      assert html =~ "⌘S"
      assert html =~ "hero-users"

      for css_class <- ~w(relative inline-block) do
        assert html =~ css_class
      end
    end

    test "an item's phx-click is on the item element, where its click bubbles from" do
      # menu.js lets an item's click bubble (and turns Enter/Space into a
      # click), so LiveView runs this binding as well as on-select.
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_item phx-click="delete" phx-value-id="7">Delete</.dropdown_menu_item>
        """)

      assert_tag(html, "div", [{"data-part", "item"}, {"phx-click", "delete"}, {"phx-value-id", "7"}])
    end
  end

  describe "typeahead" do
    test "items pass data-text-value through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_item data-text-value="Settings">⚙ Settings</.dropdown_menu_item>
        <.dropdown_menu_checkbox_item data-text-value="Bold">B Bold</.dropdown_menu_checkbox_item>
        <.dropdown_menu_sub_trigger data-text-value="Share">↗ Share</.dropdown_menu_sub_trigger>
        """)

      assert html =~ ~s(data-text-value="Settings")
      assert html =~ ~s(data-text-value="Bold")
      assert html =~ ~s(data-text-value="Share")
    end
  end

  describe "sub-menus" do
    test "renders sub, sub-trigger with chevron and a hidden sub-content panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_sub>
          <.dropdown_menu_sub_trigger inset>Invite users</.dropdown_menu_sub_trigger>
          <.dropdown_menu_sub_content class="w-40">
            <.dropdown_menu_item>Email</.dropdown_menu_item>
          </.dropdown_menu_sub_content>
        </.dropdown_menu_sub>
        """)

      assert html =~ ~s(data-slot="dropdown-menu-sub")
      assert html =~ ~s(data-part="sub")
      assert html =~ ~s(data-slot="dropdown-menu-sub-trigger")
      assert html =~ ~s(data-part="sub-trigger")
      assert html =~ ~s(data-inset)
      assert html =~ ~s(aria-haspopup="menu")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(<path d="m9 18 6-6-6-6"></path>)
      assert html =~ "data-[state=open]:bg-accent"

      assert html =~ ~r/data-part="sub-positioner"[^>]*hidden/
      assert html =~ ~s(data-side="right")
      assert html =~ ~s(data-align="start")
      assert html =~ ~s(data-side-offset="0")
      assert html =~ ~s(data-slot="dropdown-menu-sub-content")
      assert html =~ ~s(data-part="sub-content")
      assert html =~ ~s(role="menu")
      assert html =~ "shadow-lg"
      assert html =~ "w-40"
      assert html =~ "Email"
    end

    test "sub-content accepts side and offsets; disabled sub-trigger is not focusable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_sub>
          <.dropdown_menu_sub_trigger disabled>More</.dropdown_menu_sub_trigger>
          <.dropdown_menu_sub_content side="left" side-offset={2} align-offset={-5}>
            <.dropdown_menu_item>A</.dropdown_menu_item>
          </.dropdown_menu_sub_content>
        </.dropdown_menu_sub>
        """)

      assert html =~ ~s(data-side="left")
      assert html =~ ~s(data-side-offset="2")
      assert html =~ ~s(data-align-offset="-5")
      assert html =~ ~r/data-part="sub-trigger"[^>]*data-disabled/
      assert html =~ ~r/data-part="sub-trigger"[^>]*tabindex="-1"/
    end
  end

  describe "radio group" do
    test "renders the group value and value-changed mapping" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_radio_group value="bottom" on-value-changed="set_position">
          <.dropdown_menu_radio_item value="top">Top</.dropdown_menu_radio_item>
          <.dropdown_menu_radio_item value="bottom" disabled>Bottom</.dropdown_menu_radio_item>
        </.dropdown_menu_radio_group>
        """)

      assert html =~ ~s(data-slot="dropdown-menu-radio-group")
      assert html =~ ~s(data-part="radio-group")
      assert html =~ ~s(data-value="bottom")
      assert html =~ ~s(role="group")
      assert html =~ ~s(data-event-mappings="{&quot;value-changed&quot;:&quot;set_position&quot;}")

      assert html =~ ~s(data-slot="dropdown-menu-radio-item")
      assert html =~ ~s(data-part="radio-item")
      assert html =~ ~s(data-value="top")
      assert html =~ ~s(<circle cx="12" cy="12" r="10"></circle>)
      assert html =~ "size-2 fill-current"
      assert html =~ ~r/data-part="item-indicator"[^>]*hidden/
      assert html =~ "ps-8"
      assert html =~ ~r/data-value="bottom"[^>]*data-disabled[^>]*tabindex="-1"/s
    end

    test "on-value-changed accepts a JS command" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_radio_group value="a" on-value-changed={Phoenix.LiveView.JS.push("picked")}>
          <.dropdown_menu_radio_item value="a">A</.dropdown_menu_radio_item>
        </.dropdown_menu_radio_group>
        """)

      assert html =~ "value-changed"
      assert html =~ "picked"
    end

    test "checked marks a radio item checked in the dead render" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_radio_group>
          <.dropdown_menu_radio_item value="a" checked>A</.dropdown_menu_radio_item>
          <.dropdown_menu_radio_item value="b">B</.dropdown_menu_radio_item>
        </.dropdown_menu_radio_group>
        """)

      [a, b] = html |> String.split(~s(data-part="radio-item")) |> tl()

      assert a =~ ~s(data-state="checked")
      assert a =~ ~s(aria-checked="true")
      refute a =~ ~r/data-part="item-indicator"[^>]*hidden/
      refute b =~ ~s(data-state="checked")
      assert b =~ ~r/data-part="item-indicator"[^>]*hidden/
    end
  end

  describe "shadcn v4 classes and data attributes" do
    test "items carry data-variant and data-inset and shadcn's item classes" do
      assigns = %{}

      html =
        ~H"""
        <.dropdown_menu_item inset variant="destructive">Delete</.dropdown_menu_item>
        """
        |> rendered_to_string()
        |> String.replace("&amp;", "&")
        |> String.replace("&#39;", "'")

      assert html =~ ~s(data-slot="dropdown-menu-item")
      assert html =~ ~s(role="menuitem")
      assert html =~ ~s(data-variant="destructive")
      assert html =~ ~s(data-inset)
      assert html =~ ~s(tabindex="-1")

      for css_class <-
            ~w|gap-2 rounded-sm data-[inset]:ps-8 data-[variant=destructive]:text-destructive data-[variant=destructive]:focus:bg-destructive/10 dark:data-[variant=destructive]:focus:bg-destructive/20 data-[variant=destructive]:*:[svg]:text-destructive! [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground| do
        assert html =~ css_class
      end

      refute html =~ "rounded-xs"
      refute html =~ "[&_svg]:me-2"
      refute html =~ "[&_svg]:size-4"
    end

    test "default items render data-variant=default and no data-inset" do
      assigns = %{}

      html = rendered_to_string(~H"<.dropdown_menu_item>Profile</.dropdown_menu_item>")

      assert html =~ ~s(data-variant="default")
      refute html =~ "data-inset"
      refute html =~ "data-close-on-select"
    end

    test "link items share the item classes and data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_link_item href="/settings" inset variant="destructive">
          Settings
        </.dropdown_menu_link_item>
        """)

      assert html =~ ~s(href="/settings")
      assert html =~ ~s(data-part="item")
      assert html =~ ~s(data-variant="destructive")
      assert html =~ ~s(data-inset)
      assert html =~ "data-[inset]:ps-8"
      assert html =~ "gap-2"
      refute html =~ "rounded-xs"
    end

    test "labels use font-medium and data-inset" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_label inset>My Account</.dropdown_menu_label>
        """)

      assert html =~ ~s(data-slot="dropdown-menu-label")
      assert html =~ ~s(data-inset)
      assert html =~ "font-medium"
      assert html =~ "data-[inset]:ps-8"
      refute html =~ "font-semibold"
    end

    test "close-on-select={false} renders data-close-on-select on every item kind" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_item close-on-select={false}>A</.dropdown_menu_item>
        <.dropdown_menu_checkbox_item close-on-select={false}>B</.dropdown_menu_checkbox_item>
        <.dropdown_menu_radio_item value="c" close-on-select={false}>C</.dropdown_menu_radio_item>
        """)

      assert length(String.split(html, ~s(data-close-on-select="false"))) == 4
    end

    test "content caps its height, scrolls and is focusable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_content>
          <.dropdown_menu_item>A</.dropdown_menu_item>
        </.dropdown_menu_content>
        """)

      assert html =~ ~s(data-slot="dropdown-menu-content")
      assert html =~ ~s(role="menu")
      assert html =~ ~s(tabindex="-1")

      for css_class <-
            ~w[max-h-(--dropdown-menu-content-available-height) overflow-x-hidden overflow-y-auto outline-hidden] do
        assert html =~ css_class
      end
    end

    test "separator and shortcut use shadcn's tokens" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_separator />
        <.dropdown_menu_shortcut>⌘P</.dropdown_menu_shortcut>
        """)

      assert html =~ "bg-border"
      assert html =~ "text-muted-foreground"
      refute html =~ "opacity-60"
    end

    test "the trigger renders its popup ARIA" do
      assigns = %{}

      html = rendered_to_string(~H"<.dropdown_menu_trigger>Open</.dropdown_menu_trigger>")

      assert html =~ ~s(aria-haspopup="menu")
      assert html =~ ~s(aria-expanded="false")
    end
  end

  describe "modal" do
    test "is modal by default and accepts modal={false}" do
      assigns = %{}

      default =
        rendered_to_string(~H"""
        <.dropdown_menu id="m">
          <.dropdown_menu_trigger>Open</.dropdown_menu_trigger>
        </.dropdown_menu>
        """)

      non_modal =
        rendered_to_string(~H"""
        <.dropdown_menu id="m" modal={false}>
          <.dropdown_menu_trigger>Open</.dropdown_menu_trigger>
        </.dropdown_menu>
        """)

      assert default =~ "modal&quot;:true"
      assert non_modal =~ "modal&quot;:false"
      refute non_modal =~ ~s( modal=)
    end
  end

  test "content renders collision-padding for the positioner" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown_menu id="m">
        <.dropdown_menu_content collision-padding={6}>x</.dropdown_menu_content>
      </.dropdown_menu>
      """)

    assert html =~ ~s(data-collision-padding="6")
  end

  describe "shared menus" do
    test "a trigger with `for` renders a detached trigger, not a part" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_trigger for="msg-more" context={%{id: 42}} aria-label="More">
          ⋮
        </.dropdown_menu_trigger>
        """)

      assert html =~ ~s(data-salad-for="msg-more")
      assert html =~ ~s(data-salad-context="{&quot;id&quot;:42}")
      assert html =~ ~s(data-state="closed")
      assert html =~ ~s(aria-haspopup="menu")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(type="button")
      assert html =~ ~s(data-slot="dropdown-menu-trigger")
      refute html =~ ~s(data-part="trigger")
    end

    test "a detached trigger rendered through `as` keeps its button props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_trigger for="msg-more" as={&button/1} variant="ghost" size="icon-sm">
          ⋮
        </.dropdown_menu_trigger>
        """)

      assert html =~ ~s(data-salad-for="msg-more")
      assert html =~ ~s(type="button")
      refute html =~ ~s(data-salad-context)
      refute html =~ ~s(data-part="trigger")
    end

    test "a nested trigger renders as before" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_trigger>Open</.dropdown_menu_trigger>
        """)

      assert html =~ ~s(data-part="trigger")
      refute html =~ "data-salad-for"
      refute html =~ "data-state"
    end
  end

  describe "context conditions (shared menus)" do
    test "parts render show-when / hide-when / disabled-when as JSON" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu id="msg-more">
          <.dropdown_menu_content>
            <.dropdown_menu_item phx-click="pin" hide-when={%{pinned: true}}>Pin</.dropdown_menu_item>
            <.dropdown_menu_item phx-click="unpin" show-when={%{pinned: true}}>Unpin</.dropdown_menu_item>
            <.dropdown_menu_item phx-click="remind" disabled-when={%{kind: [:bot, :agent]}}>
              Remind
            </.dropdown_menu_item>
            <.dropdown_menu_group show-when={%{own: true}}>
              <.dropdown_menu_label show-when={%{own: true}}>Yours</.dropdown_menu_label>
              <.dropdown_menu_separator hide-when={%{own: false}} />
              <.dropdown_menu_link_item navigate="/edit" show-when={%{own: true}}>Edit</.dropdown_menu_link_item>
            </.dropdown_menu_group>
            <.dropdown_menu_checkbox_item show-when={%{own: true}}>Mute</.dropdown_menu_checkbox_item>
            <.dropdown_menu_radio_group value="a" hide-when={%{own: false}}>
              <.dropdown_menu_radio_item value="a" show-when={%{own: true}}>A</.dropdown_menu_radio_item>
            </.dropdown_menu_radio_group>
            <.dropdown_menu_sub hide-when={%{kind: :bot}}>
              <.dropdown_menu_sub_trigger disabled-when={%{locked: true}}>
                React
              </.dropdown_menu_sub_trigger>
              <.dropdown_menu_sub_content>
                <.dropdown_menu_item
                  phx-click="delete"
                  show-when={[%{own: true}, %{kind: :bot}]}
                >
                  Delete
                </.dropdown_menu_item>
              </.dropdown_menu_sub_content>
            </.dropdown_menu_sub>
          </.dropdown_menu_content>
        </.dropdown_menu>
        """)

      attr = fn markers, name -> attr_of(html, markers, name) end

      assert attr.(~s(phx-click="pin"), "data-hide-when") == ~s({"pinned":true})
      assert attr.(~s(phx-click="unpin"), "data-show-when") == ~s({"pinned":true})
      assert attr.(~s(phx-click="remind"), "data-disabled-when") == ~s({"kind":["bot","agent"]})
      assert attr.(~s(data-part="group"), "data-show-when") == ~s({"own":true})
      assert attr.(~s(data-part="label"), "data-show-when") == ~s({"own":true})
      assert attr.([~s(data-part="separator"), "data-hide-when"], "data-hide-when") == ~s({"own":false})
      assert attr.("<a ", "data-show-when") == ~s({"own":true})
      assert attr.(~s(data-part="checkbox-item"), "data-show-when") == ~s({"own":true})
      assert attr.(~s(data-part="radio-group"), "data-hide-when") == ~s({"own":false})
      assert attr.(~s(data-part="radio-item"), "data-show-when") == ~s({"own":true})
      assert attr.(~s(data-part="sub"), "data-hide-when") == ~s({"kind":"bot"})
      assert attr.(~s(data-part="sub-trigger"), "data-disabled-when") == ~s({"locked":true})
      assert attr.(~s(phx-click="delete"), "data-show-when") == ~s([{"own":true},{"kind":"bot"}])
      # Unset conditions render nothing.
      assert attr.(~s(phx-click="pin"), "data-show-when") == nil
      refute html =~ ~s( show-when=)
    end

    test "a condition must be a map or a list of maps" do
      assigns = %{}

      assert_raise ArgumentError, ~r/show-when takes a map or a list of maps/, fn ->
        rendered_to_string(~H"""
        <.dropdown_menu_item show-when="own">Edit</.dropdown_menu_item>
        """)
      end

      assert_raise ArgumentError, ~r/hide-when takes a map or a list of maps/, fn ->
        rendered_to_string(~H"""
        <.dropdown_menu_item hide-when={[:own]}>Edit</.dropdown_menu_item>
        """)
      end
    end
  end

  # The value of attribute `name` on the first tag of `html` that contains
  # every string in `markers` (unescaped), or nil.
  defp attr_of(html, markers, name) do
    markers = List.wrap(markers)

    tag =
      ~r/<[a-z][^>]*>/
      |> Regex.scan(html)
      |> List.flatten()
      |> Enum.find(fn tag -> Enum.all?(markers, &String.contains?(tag, &1)) end)

    with tag when is_binary(tag) <- tag,
         [_, value] <- Regex.run(~r/\s#{name}="([^"]*)"/, tag) do
      value |> String.replace("&quot;", "\"") |> String.replace("&#39;", "'")
    else
      _ -> nil
    end
  end
end
