defmodule SaladUI.TabsTest do
  use ComponentCase

  import SaladUI.Tabs

  describe "tabs/1" do
    test "renders root component attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="settings" default="account">
          <.tabs_list>
            <.tabs_trigger value="account">Account</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="account">Account content</.tabs_content>
        </.tabs>
        """)

      assert html =~ ~s(id="settings")
      assert html =~ ~s(data-component="tabs")
      assert html =~ ~s(data-part="root")
      assert html =~ ~s(data-state="idle")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ "Account content"
    end

    test "encodes default and controlled value into data-options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="settings" default="account" value="password">
          <.tabs_list>
            <.tabs_trigger value="account">Account</.tabs_trigger>
            <.tabs_trigger value="password">Password</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="account">Account content</.tabs_content>
          <.tabs_content value="password">Password content</.tabs_content>
        </.tabs>
        """)

      assert html =~ ~s(&quot;defaultValue&quot;:&quot;account&quot;)
      assert html =~ ~s(&quot;value&quot;:&quot;password&quot;)
    end

    test "defaults to horizontal orientation with shadcn root classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="settings">
          <.tabs_list>
            <.tabs_trigger value="account">Account</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ "group/tabs flex gap-2 data-[orientation=horizontal]:flex-col"
      assert html =~ ~s(&quot;orientation&quot;:&quot;horizontal&quot;)
    end

    test "renders vertical orientation on the root and in data-options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="settings" orientation="vertical">
          <.tabs_list>
            <.tabs_trigger value="account">Account</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ ~s(data-orientation="vertical")
      assert html =~ ~s(&quot;orientation&quot;:&quot;vertical&quot;)
    end

    test "encodes hyphenated on-tab-changed into event mappings" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="settings" on-tab-changed="tab_changed">
          <.tabs_list>
            <.tabs_trigger value="account">Account</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="account">Account content</.tabs_content>
        </.tabs>
        """)

      assert html =~ ~s(&quot;tab-changed&quot;:&quot;tab_changed&quot;)
    end
  end

  describe "tabs_list/1" do
    test "renders list part with custom class" do
      html = render_component(&tabs_list/1, %{class: "custom-class", inner_block: []})

      assert html =~ ~s(data-part="list")
      assert html =~ ~s(data-variant="default")
      assert html =~ "bg-muted"
      assert html =~ "group-data-[orientation=vertical]/tabs:flex-col"
      assert html =~ "custom-class"
    end

    test "renders line variant" do
      html = render_component(&tabs_list/1, %{variant: "line", inner_block: []})

      assert html =~ ~s(data-variant="line")
      assert html =~ "gap-1 bg-transparent"
      assert html =~ "data-[variant=line]:rounded-none"
      refute html =~ "bg-muted"
    end
  end

  describe "tabs_trigger/1" do
    test "renders trigger part with value and disabled state" do
      html =
        render_component(&tabs_trigger/1, %{
          value: "account",
          disabled: true,
          inner_block: []
        })

      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(data-value="account")
      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(disabled)
    end

    test "carries line-variant and vertical-orientation styles" do
      html = render_component(&tabs_trigger/1, %{value: "account", inner_block: []})

      assert html =~ "group-data-[variant=line]/tabs-list:data-[state=active]:after:opacity-100"
      assert html =~ "group-data-[orientation=vertical]/tabs:justify-start"
      assert html =~ "group-data-[variant=default]/tabs-list:data-[state=active]:shadow-sm"
    end
  end

  describe "tabs_content/1" do
    test "renders content part hidden by default" do
      html = render_component(&tabs_content/1, %{value: "account", inner_block: []})

      assert html =~ ~s(data-part="content")
      assert html =~ ~s(data-value="account")
      assert html =~ ~s(data-state="inactive")
      assert html =~ ~s(hidden)
    end
  end

  # The opening tag matching "#id" or "[attr=value]", and one attribute of it
  # ("" for a boolean attribute, nil when absent).
  defp tag(html, "#" <> id), do: find_tag(html, ~s(id="#{id}"))

  defp tag(html, "[" <> rest) do
    [name, value] = rest |> String.trim_trailing("]") |> String.split("=")
    find_tag(html, ~s(#{name}="#{value}"))
  end

  defp find_tag(html, needle) do
    ~r/<[a-z]+\s[^>]*>/
    |> Regex.scan(html)
    |> List.flatten()
    |> Enum.find(&String.contains?(&1, " " <> needle))
  end

  defp attr_of(tag, name) do
    case Regex.run(~r/\s#{Regex.escape(name)}(?:="([^"]*)")?[\s>]/, tag) do
      nil -> nil
      [_] -> ""
      [_, value] -> value
    end
  end

  describe "server-rendered state" do
    test "the builder renders the selected tab with its ARIA" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs :let={tabs} id="settings" value="password" orientation="vertical">
          <.tabs_list builder={tabs}>
            <.tabs_trigger builder={tabs} value="account">Account</.tabs_trigger>
            <.tabs_trigger builder={tabs} value="password">Password</.tabs_trigger>
          </.tabs_list>
          <.tabs_content builder={tabs} value="account">Account content</.tabs_content>
          <.tabs_content builder={tabs} value="password">Password content</.tabs_content>
        </.tabs>
        """)

      list = tag(html, "[data-slot=tabs-list]")
      assert attr_of(list, "role") == "tablist"
      assert attr_of(list, "aria-orientation") == "vertical"

      account = tag(html, "#settings-trigger-account")
      password = tag(html, "#settings-trigger-password")
      assert attr_of(password, "role") == "tab"
      assert attr_of(password, "aria-selected") == "true"
      assert attr_of(password, "aria-controls") == "settings-content-password"
      assert attr_of(password, "tabindex") == "0"
      assert attr_of(password, "data-state") == "active"
      assert attr_of(account, "aria-selected") == "false"
      assert attr_of(account, "tabindex") == "-1"
      assert attr_of(account, "data-state") == "inactive"

      panel = tag(html, "#settings-content-password")
      assert attr_of(panel, "role") == "tabpanel"
      assert attr_of(panel, "aria-labelledby") == "settings-trigger-password"
      assert attr_of(panel, "tabindex") == "0"
      assert attr_of(panel, "data-state") == "active"
      assert attr_of(panel, "hidden") == nil
      assert attr_of(tag(html, "#settings-content-account"), "hidden") == ""
    end

    test "default-value selects a tab when there is no value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs :let={tabs} id="t" default-value="b">
          <.tabs_list builder={tabs}>
            <.tabs_trigger builder={tabs} value="a">A</.tabs_trigger>
            <.tabs_trigger builder={tabs} value="b">B</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      assert html =~ ~s(&quot;defaultValue&quot;:&quot;b&quot;)
      assert attr_of(tag(html, "#t-trigger-b"), "aria-selected") == "true"
    end

    test "attributes passed by the caller win" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs :let={tabs} id="t" value="a">
          <.tabs_list builder={tabs} role="tablist">
            <.tabs_trigger builder={tabs} id="custom" role="tab" tabindex="0" value="a">A</.tabs_trigger>
          </.tabs_list>
        </.tabs>
        """)

      trigger = tag(html, "[data-slot=tabs-trigger]")
      assert attr_of(trigger, "id") == "custom"
      assert duplicate_attrs(html) == []
      refute html =~ "t-trigger-a"
    end

    test "without the builder the parts render their roles, inactive" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tabs id="t" value="a">
          <.tabs_list>
            <.tabs_trigger value="a">A</.tabs_trigger>
          </.tabs_list>
          <.tabs_content value="a">A</.tabs_content>
        </.tabs>
        """)

      assert attr_of(tag(html, "[data-slot=tabs-list]"), "role") == "tablist"
      trigger = tag(html, "[data-slot=tabs-trigger]")
      assert attr_of(trigger, "role") == "tab"
      assert attr_of(trigger, "aria-selected") == "false"
      assert attr_of(trigger, "tabindex") == nil
      panel = tag(html, "[data-slot=tabs-content]")
      assert attr_of(panel, "role") == "tabpanel"
      assert attr_of(panel, "hidden") == ""
    end
  end
end
