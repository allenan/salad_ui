defmodule Storybook.SaladUIComponents.ToggleGroup do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.ToggleGroup.toggle_group/1

  def imports,
    do: [{SaladUI.ToggleGroup, [toggle_group_item: 1]}, {SaladUI.Field, [field: 1, field_label: 1, field_description: 1]}]

  def description do
    """
    A set of two-state buttons that can be toggled on or off. Arrow keys move
    focus between items (mirrored under RTL), Home/End jump to the ends.
    """
  end

  def variations do
    [
      %Variation{
        id: :demo,
        description: "toggle-group-demo",
        template: """
        <.toggle_group :let={builder} id="toggle-group-demo" variant="outline" type="multiple">
          <.toggle_group_item value="bold" builder={builder} aria-label="Toggle bold">
            <Lucideicons.bold class="h-4 w-4" />
          </.toggle_group_item>
          <.toggle_group_item value="italic" builder={builder} aria-label="Toggle italic">
            <Lucideicons.italic class="h-4 w-4" />
          </.toggle_group_item>
          <.toggle_group_item value="strikethrough" builder={builder} aria-label="Toggle strikethrough">
            <Lucideicons.underline class="h-4 w-4" />
          </.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :single,
        description: ~s|type="single": one item pressed at a time (items are radios)|,
        template: """
        <.toggle_group :let={builder} id="toggle-group-single" type="single" value="bold">
          <.toggle_group_item value="bold" builder={builder} aria-label="Toggle bold">
            <Lucideicons.bold class="h-4 w-4" />
          </.toggle_group_item>
          <.toggle_group_item value="italic" builder={builder} aria-label="Toggle italic">
            <Lucideicons.italic class="h-4 w-4" />
          </.toggle_group_item>
          <.toggle_group_item value="strikethrough" builder={builder} aria-label="Toggle strikethrough">
            <Lucideicons.underline class="h-4 w-4" />
          </.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :required,
        description:
          ~s|required (a SaladUI extension; Radix has none): pressing the pressed item does nothing, so one is always pressed|,
        template: """
        <.toggle_group :let={builder} id="toggle-group-required" variant="outline" type="single" default-value="all" required>
          <.toggle_group_item value="all" builder={builder}>All</.toggle_group_item>
          <.toggle_group_item value="mine" builder={builder}>Mine</.toggle_group_item>
          <.toggle_group_item value="done" builder={builder}>Done</.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :outline,
        description: "toggle-group-outline",
        template: """
        <.toggle_group :let={builder} id="toggle-group-outline" variant="outline" type="single" default-value="all">
          <.toggle_group_item value="all" builder={builder} aria-label="Toggle all">All</.toggle_group_item>
          <.toggle_group_item value="missed" builder={builder} aria-label="Toggle missed">Missed</.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :sizes,
        description: "toggle-group-sizes: sm, default and lg",
        template: """
        <div class="flex flex-col gap-4">
          <.toggle_group :let={builder} id="toggle-group-sm" type="single" default-value="top" size="sm" variant="outline">
            <.toggle_group_item value="top" builder={builder} aria-label="Toggle top">Top</.toggle_group_item>
            <.toggle_group_item value="bottom" builder={builder} aria-label="Toggle bottom">Bottom</.toggle_group_item>
            <.toggle_group_item value="left" builder={builder} aria-label="Toggle left">Left</.toggle_group_item>
            <.toggle_group_item value="right" builder={builder} aria-label="Toggle right">Right</.toggle_group_item>
          </.toggle_group>
          <.toggle_group :let={builder} id="toggle-group-default" type="single" default-value="top" variant="outline">
            <.toggle_group_item value="top" builder={builder} aria-label="Toggle top">Top</.toggle_group_item>
            <.toggle_group_item value="bottom" builder={builder} aria-label="Toggle bottom">Bottom</.toggle_group_item>
            <.toggle_group_item value="left" builder={builder} aria-label="Toggle left">Left</.toggle_group_item>
            <.toggle_group_item value="right" builder={builder} aria-label="Toggle right">Right</.toggle_group_item>
          </.toggle_group>
          <.toggle_group :let={builder} id="toggle-group-lg" type="single" default-value="top" size="lg" variant="outline">
            <.toggle_group_item value="top" builder={builder} aria-label="Toggle top">Top</.toggle_group_item>
            <.toggle_group_item value="bottom" builder={builder} aria-label="Toggle bottom">Bottom</.toggle_group_item>
            <.toggle_group_item value="left" builder={builder} aria-label="Toggle left">Left</.toggle_group_item>
            <.toggle_group_item value="right" builder={builder} aria-label="Toggle right">Right</.toggle_group_item>
          </.toggle_group>
        </div>
        """
      },
      %Variation{
        id: :spacing,
        description: "toggle-group-spacing: spacing={2} separates the items",
        template: """
        <.toggle_group :let={builder} id="toggle-group-spacing" type="multiple" variant="outline" spacing={2} size="sm">
          <.toggle_group_item
            value="star"
            builder={builder}
            aria-label="Toggle star"
            class="data-[state=on]:bg-transparent data-[state=on]:*:[svg]:fill-yellow-500 data-[state=on]:*:[svg]:stroke-yellow-500"
          >
            <Lucideicons.star /> Star
          </.toggle_group_item>
          <.toggle_group_item
            value="heart"
            builder={builder}
            aria-label="Toggle heart"
            class="data-[state=on]:bg-transparent data-[state=on]:*:[svg]:fill-red-500 data-[state=on]:*:[svg]:stroke-red-500"
          >
            <Lucideicons.heart /> Heart
          </.toggle_group_item>
          <.toggle_group_item
            value="bookmark"
            builder={builder}
            aria-label="Toggle bookmark"
            class="data-[state=on]:bg-transparent data-[state=on]:*:[svg]:fill-blue-500 data-[state=on]:*:[svg]:stroke-blue-500"
          >
            <Lucideicons.bookmark /> Bookmark
          </.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :spacing_positions,
        description: "spacing={2} with text items (radix-nova toggle-group-spacing)",
        template: """
        <.toggle_group
          :let={builder}
          id="toggle-group-spacing-positions"
          type="single"
          size="sm"
          default-value="top"
          variant="outline"
          spacing={2}
        >
          <.toggle_group_item value="top" builder={builder} aria-label="Toggle top">Top</.toggle_group_item>
          <.toggle_group_item value="bottom" builder={builder} aria-label="Toggle bottom">Bottom</.toggle_group_item>
          <.toggle_group_item value="left" builder={builder} aria-label="Toggle left">Left</.toggle_group_item>
          <.toggle_group_item value="right" builder={builder} aria-label="Toggle right">Right</.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :vertical,
        description: ~s|toggle-group-vertical: orientation="vertical" (ArrowUp/ArrowDown move focus)|,
        template: """
        <.toggle_group
          :let={builder}
          id="toggle-group-vertical"
          type="multiple"
          orientation="vertical"
          spacing={1}
          default-value={["bold", "italic"]}
        >
          <.toggle_group_item value="bold" builder={builder} aria-label="Toggle bold">
            <Lucideicons.bold />
          </.toggle_group_item>
          <.toggle_group_item value="italic" builder={builder} aria-label="Toggle italic">
            <Lucideicons.italic />
          </.toggle_group_item>
          <.toggle_group_item value="underline" builder={builder} aria-label="Toggle underline">
            <Lucideicons.underline />
          </.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :vertical_connected,
        description: ~s|orientation="vertical" with connected (spacing={0}) outline items|,
        template: """
        <.toggle_group :let={builder} id="toggle-group-vertical-connected" type="single" orientation="vertical" variant="outline">
          <.toggle_group_item value="bold" builder={builder} aria-label="Toggle bold">
            <Lucideicons.bold />
          </.toggle_group_item>
          <.toggle_group_item value="italic" builder={builder} aria-label="Toggle italic">
            <Lucideicons.italic />
          </.toggle_group_item>
          <.toggle_group_item value="underline" builder={builder} aria-label="Toggle underline">
            <Lucideicons.underline />
          </.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :disabled,
        description: "toggle-group-disabled",
        template: """
        <.toggle_group :let={builder} id="toggle-group-disabled" type="multiple" disabled>
          <.toggle_group_item value="bold" builder={builder} aria-label="Toggle bold">
            <Lucideicons.bold class="h-4 w-4" />
          </.toggle_group_item>
          <.toggle_group_item value="italic" builder={builder} aria-label="Toggle italic">
            <Lucideicons.italic class="h-4 w-4" />
          </.toggle_group_item>
          <.toggle_group_item value="strikethrough" builder={builder} aria-label="Toggle strikethrough">
            <Lucideicons.underline class="h-4 w-4" />
          </.toggle_group_item>
        </.toggle_group>
        """
      },
      %Variation{
        id: :font_weight_selector,
        description: "toggle-group-font-weight-selector: a custom toggle group inside a field",
        template: """
        <.field class="max-w-xs">
          <.field_label>Font Weight</.field_label>
          <.toggle_group
            :let={builder}
            id="toggle-group-font-weight"
            type="single"
            value="normal"
            variant="outline"
            spacing={2}
            size="lg"
          >
            <.toggle_group_item
              :for={
                {weight, label, class} <- [
                  {"light", "Light", "font-light"},
                  {"normal", "Normal", "font-normal"},
                  {"medium", "Medium", "font-medium"},
                  {"bold", "Bold", "font-bold"}
                ]
              }
              value={weight}
              builder={builder}
              aria-label={label}
              class="flex size-16 flex-col items-center justify-center rounded-xl"
            >
              <span class={["text-2xl leading-none", class]}>Aa</span>
              <span class="text-xs text-muted-foreground">{label}</span>
            </.toggle_group_item>
          </.toggle_group>
          <.field_description>
            Use <code class="rounded-md bg-muted px-1 py-0.5 font-mono">font-weight</code> utilities
            such as <code class="rounded-md bg-muted px-1 py-0.5 font-mono">font-normal</code>
            to set the font weight.
          </.field_description>
        </.field>
        """
      },
      %Variation{
        id: :rtl,
        description: ~s|toggle-group-rtl: under dir="rtl" ArrowLeft/ArrowRight are mirrored|,
        template: """
        <div dir="rtl">
          <.toggle_group :let={builder} id="toggle-group-rtl" variant="outline" type="single" value="list">
            <.toggle_group_item value="list" builder={builder} aria-label="قائمة">قائمة</.toggle_group_item>
            <.toggle_group_item value="grid" builder={builder} aria-label="شبكة">شبكة</.toggle_group_item>
            <.toggle_group_item value="cards" builder={builder} aria-label="بطاقات">بطاقات</.toggle_group_item>
          </.toggle_group>
        </div>
        """
      }
    ]
  end
end
