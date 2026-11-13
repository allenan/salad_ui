defmodule SaladUI.DropZoneTest do
  use ComponentCase

  import SaladUI.DropZone

  test "renders a hidden overlay wired to the drop-zone component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.drop_zone id="drop" for="#chat" input="#form input[type=file]" />
      """)

    assert html =~ ~s(id="drop")
    assert html =~ ~s(data-component="drop-zone")
    assert html =~ ~s(data-slot="drop-zone")
    assert html =~ ~s(data-state="idle")
    assert html =~ ~s(phx-hook="SaladUI")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ ~r/<div[^>]*\shidden[\s>]/
    assert html =~ "&quot;for&quot;:&quot;#chat&quot;"
    assert html =~ "&quot;input&quot;:&quot;#form input[type=file]&quot;"
    assert html =~ "Drop files to upload"
    assert html =~ "pointer-events-none fixed"
    assert html =~ "<svg"
    assert duplicate_attrs(html) == []
  end

  test "label, description, icon and class are overridable" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.drop_zone id="drop" label="Drop to attach" description="Up to 10 MB" class="z-50">
        <:icon><span id="custom-icon"></span></:icon>
      </.drop_zone>
      """)

    assert html =~ "Drop to attach"
    assert html =~ "Up to 10 MB"
    assert html =~ ~s(id="custom-icon")
    refute html =~ "<svg"
    assert html =~ "z-50"
    refute html =~ "z-40"
  end

  test "for and input default to nil: the parent is the region" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.drop_zone id="drop" />
      """)

    assert html =~ "&quot;for&quot;:null"
    assert html =~ "&quot;input&quot;:null"
  end
end
