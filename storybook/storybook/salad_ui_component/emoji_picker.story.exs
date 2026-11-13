defmodule Storybook.SaladUIComponents.EmojiPicker do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.EmojiPicker

  def function, do: &EmojiPicker.emoji_picker/1

  def imports, do: [{SaladUI.Button, [button: 1]}]

  def variations do
    [
      %Variation{
        id: :default,
        description:
          "One picker serves any number of plain opener buttons (`data-emoji-picker`). Search, " <>
            "arrow keys and Enter, categories, recently used and a skin tone. The dataset loads on " <>
            "first open. See Examples > Emoji reactions for picks pushed to the server.",
        template: """
        <div class="flex items-center gap-2 py-32">
          <.button variant="outline" data-emoji-picker="emoji-picker-default">
            <span aria-hidden="true">😊</span> Add reaction
          </.button>
          <.button variant="ghost" size="icon" data-emoji-picker="emoji-picker-default" aria-label="Insert emoji">
            <span aria-hidden="true">🙂</span>
          </.button>
          <.emoji_picker id="emoji-picker-default" />
        </div>
        """
      },
      %Variation{
        id: :command,
        description:
          "Opened with `SaladUI.JS.dispatch_command(\"open\", ...)` at an anchor, as from a menu item " <>
            "(`SaladUI.LiveView.send_command/4` works the same from the server).",
        template: """
        <div class="flex items-center gap-2 py-32">
          <span id="emoji-picker-command-anchor" class="rounded-md border px-3 py-2 text-sm">Anchor</span>
          <.button
            variant="outline"
            phx-click={
              SaladUI.JS.dispatch_command("open",
                to: "#emoji-picker-command",
                detail: %{anchor: "#emoji-picker-command-anchor"}
              )
            }
          >
            Open at the anchor
          </.button>
          <.emoji_picker id="emoji-picker-command" side="bottom" align="start" />
        </div>
        """
      },
      %Variation{
        id: :labels,
        description: "Every string can be overridden with `labels`, including category names.",
        template: """
        <div class="flex items-center gap-2 py-32">
          <.button variant="outline" data-emoji-picker="emoji-picker-labels">Ajouter une réaction</.button>
          <.emoji_picker
            id="emoji-picker-labels"
            storage-key="storybook:emoji-fr"
            labels={%{
              emoji: "Émoji",
              search: "Rechercher un émoji",
              categories: "Catégories",
              recent: "Récents",
              results: "Résultats",
              empty: "Aucun émoji.",
              tone: "Teinte",
              tones: ["Aucune", "Claire", "Moyennement claire", "Moyenne", "Moyennement foncée", "Foncée"],
              groups: %{smileys: "Smileys et émotions", people: "Personnes", flags: "Drapeaux"}
            }}
          />
        </div>
        """
      }
    ]
  end
end
