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
end
