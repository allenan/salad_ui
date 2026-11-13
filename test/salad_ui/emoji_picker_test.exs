defmodule SaladUI.EmojiPickerTest do
  use ComponentCase

  import SaladUI.EmojiPicker

  defp render_picker(assigns) do
    rendered_to_string(~H"""
    <.emoji_picker {assigns} />
    """)
  end

  defp options(html) do
    [_, raw] = Regex.run(~r/data-component="emoji-picker"[^>]*data-options="([^"]*)"/, html)

    raw
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("&amp;", "&")
    |> Jason.decode!()
  end

  test "renders a SaladUI component around a popover with an anchor" do
    html = render_picker(%{id: "emoji"})

    assert html =~ ~s(id="emoji")
    assert html =~ ~s(data-component="emoji-picker")
    assert html =~ ~s(phx-hook="SaladUI")
    assert html =~ ~s(id="emoji-popover")
    assert html =~ ~s(data-component="popover")
    assert html =~ ~s(id="emoji-anchor")
    assert html =~ ~s(data-part="anchor")
    assert html =~ "emoji-picker:closed"
    assert duplicate_attrs(html) == []
  end

  test "renders the search combobox, listbox and tone buttons" do
    html = render_picker(%{id: "emoji"})

    assert html =~ ~r/id="emoji-search"[^>]*role="combobox"/
    assert html =~ ~s(aria-controls="emoji-grid")
    assert html =~ ~s(aria-label="Search emoji")
    assert html =~ ~r/id="emoji-grid"[^>]*role="listbox"[^>]*aria-label="Emoji"/
    assert html =~ ~s(aria-label="Emoji categories")
    assert html =~ ~s(phx-update="ignore")
    assert count_substring(html, "data-tone=") == 6
    assert html =~ ~s(data-slot="emoji-picker-tone-button")
  end

  test "places the content on top, aligned to the end, by default" do
    html = render_picker(%{id: "emoji"})
    assert html =~ ~r/data-part="positioner" data-side="top" data-align="end"/
    assert html =~ ~s(data-collision-padding="8")

    html = render_picker(%{id: "emoji", side: "bottom", align: "start"})
    assert html =~ ~r/data-part="positioner" data-side="bottom" data-align="start"/
  end

  test "passes English labels and the storage key to the JS" do
    opts = options(render_picker(%{id: "emoji"}))

    assert opts["storageKey"] == "salad-ui:emoji-picker"
    assert opts["labels"] == default_labels()
    assert opts["labels"]["empty"] == "No emoji found."
  end

  test "labels override strings on both sides, with atom or string keys" do
    html =
      render_picker(%{
        id: "emoji",
        labels: %{:search => "Chercher", "emoji" => "Émoji", groups: %{smileys: "Visages"}},
        "storage-key": "app:emoji"
      })

    assert html =~ ~s(aria-label="Chercher")
    assert html =~ ~s(placeholder="Chercher")
    opts = options(html)
    assert opts["labels"]["search"] == "Chercher"
    assert opts["labels"]["emoji"] == "Émoji"
    assert opts["labels"]["groups"] == %{"smileys" => "Visages"}
    assert opts["labels"]["recent"] == "Recently used"
    assert opts["storageKey"] == "app:emoji"
  end

  test "portals into a container and maps on-select" do
    html = render_picker(%{id: "emoji", "portal-container": "#portal", "on-select": "picked"})

    assert html =~ "usePortal&quot;:true"
    assert html =~ "#portal"
    assert html =~ ~s(data-event-mappings="{&quot;select&quot;:&quot;picked&quot;}")
  end

  test "carries no app-specific classes, icons or copy" do
    html = render_picker(%{id: "emoji"})
    refute html =~ ~r/commons|ember/i
    refute html =~ "hero-"
  end
end
