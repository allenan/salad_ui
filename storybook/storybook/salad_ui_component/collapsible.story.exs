defmodule Storybook.SaladUIComponents.Collapsible do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Collapsible

  def function, do: &Collapsible.collapsible/1

  def imports,
    do: [
      {Collapsible, [collapsible_trigger: 1, collapsible_content: 1]},
      {SaladUI.Button, [button: 1]},
      {SaladUI.Card, [card: 1, card_header: 1, card_title: 1, card_description: 1, card_content: 1]},
      {SaladUI.Field, [field: 1, field_group: 1, field_label: 1]},
      {SaladUI.Input, [input: 1]},
      {SaladUI.Tabs, [tabs: 1, tabs_list: 1, tabs_trigger: 1]},
      {SaladUI.Helpers, [as_child: 1]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{open: false, class: "w-[350px] space-y-2"},
        slots: [
          """
          <div class="flex items-center justify-between space-x-4 px-4">
            <h4 class="text-sm font-semibold">
              @peduarte starred 3 repositories
            </h4>
            <.collapsible_trigger>
              <.button variant="ghost" size="sm" class="w-9 p-0">
                <.icon name="hero-chevron-up-down" class="size-4"></.icon>
                <span class="sr-only">
                  Toggle
                </span>
              </.button>
            </.collapsible_trigger>
          </div>
          <div class="rounded-md border border-border px-4 py-3 font-mono text-sm">
            @radix-ui/primitives
          </div>
          <.collapsible_content class="space-y-2">
            <div class="rounded-md border border-border px-4 py-3 font-mono text-sm">
              @radix-ui/colors
            </div>
            <div class="rounded-md border border-border px-4 py-3 font-mono text-sm">
              @stitches/react
            </div>
          </.collapsible_content>
          """
        ]
      },
      %Variation{
        id: :basic,
        description: "shadcn collapsible-basic: the root's `data-state` tints the open panel.",
        template: """
        <.card class="mx-auto w-full max-w-sm">
          <.card_content>
            <.collapsible id="collapsible-basic" class="rounded-md data-[state=open]:bg-muted">
              <.as_child tag={&collapsible_trigger/1} child={&button/1} variant="ghost" class="group w-full">
                Product details
                <Lucideicons.chevron_down class="ml-auto group-data-[state=open]:rotate-180" />
              </.as_child>
              <.collapsible_content class="flex flex-col items-start gap-2 p-2.5 pt-0 text-sm">
                <div>
                  This panel can be expanded or collapsed to reveal additional content.
                </div>
                <.button size="xs">Learn More</.button>
              </.collapsible_content>
            </.collapsible>
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :demo,
        description: "shadcn collapsible-demo: order details that expand from a ghost icon button.",
        template: """
        <.collapsible id="collapsible-demo" class="flex w-[350px] flex-col gap-2">
          <div class="flex items-center justify-between gap-4 px-4">
            <h4 class="text-sm font-semibold">Order #4189</h4>
            <.as_child tag={&collapsible_trigger/1} child={&button/1} variant="ghost" size="icon" class="size-8">
              <Lucideicons.chevrons_up_down />
              <span class="sr-only">Toggle details</span>
            </.as_child>
          </div>
          <div class="flex items-center justify-between rounded-md border px-4 py-2 text-sm">
            <span class="text-muted-foreground">Status</span>
            <span class="font-medium">Shipped</span>
          </div>
          <.collapsible_content class="flex flex-col gap-2">
            <div class="rounded-md border px-4 py-2 text-sm">
              <p class="font-medium">Shipping address</p>
              <p class="text-muted-foreground">100 Market St, San Francisco</p>
            </div>
            <div class="rounded-md border px-4 py-2 text-sm">
              <p class="font-medium">Items</p>
              <p class="text-muted-foreground">2x Studio Headphones</p>
            </div>
          </.collapsible_content>
        </.collapsible>
        """
      },
      %Variation{
        id: :settings,
        description:
          "shadcn collapsible-settings: two more inputs expand into a subgrid; the icon swaps on the trigger's `data-state`.",
        template: """
        <.card class="mx-auto w-full max-w-xs" size="sm">
          <.card_header>
            <.card_title>Radius</.card_title>
            <.card_description>Set the corner radius of the element.</.card_description>
          </.card_header>
          <.card_content>
            <.collapsible id="collapsible-settings" class="flex items-start gap-2">
              <.field_group class="grid w-full grid-cols-2 gap-2">
                <.field>
                  <.field_label for="radius-x" class="sr-only">Radius X</.field_label>
                  <.input id="radius-x" placeholder="0" value="0" />
                </.field>
                <.field>
                  <.field_label for="radius-y" class="sr-only">Radius Y</.field_label>
                  <.input id="radius-y" placeholder="0" value="0" />
                </.field>
                <.collapsible_content class="col-span-full grid grid-cols-subgrid gap-2">
                  <.field>
                    <.field_label for="radius-bottom-x" class="sr-only">Radius X</.field_label>
                    <.input id="radius-bottom-x" placeholder="0" value="0" />
                  </.field>
                  <.field>
                    <.field_label for="radius-bottom-y" class="sr-only">Radius Y</.field_label>
                    <.input id="radius-bottom-y" placeholder="0" value="0" />
                  </.field>
                </.collapsible_content>
              </.field_group>
              <.as_child
                tag={&collapsible_trigger/1}
                child={&button/1}
                variant="outline"
                size="icon"
                class="group"
                aria-label="Toggle more radius fields"
              >
                <Lucideicons.maximize class="group-data-[state=open]:hidden" />
                <Lucideicons.minimize class="hidden group-data-[state=open]:block" />
              </.as_child>
            </.collapsible>
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :file_tree,
        description: "shadcn collapsible-file-tree: nested collapsibles, one per folder.",
        template: """
        <.card class="mx-auto w-full max-w-[16rem] gap-2" size="sm">
          <.card_header>
            <.tabs id="file-tree-tabs" default="explorer">
              <.tabs_list class="w-full">
                <.tabs_trigger value="explorer">Explorer</.tabs_trigger>
                <.tabs_trigger value="settings">Outline</.tabs_trigger>
              </.tabs_list>
            </.tabs>
          </.card_header>
          <.card_content>
            <div class="flex flex-col gap-1">
              <.collapsible id="file-tree-components">
                <.as_child
                  tag={&collapsible_trigger/1}
                  child={&button/1}
                  variant="ghost"
                  size="sm"
                  class="group w-full justify-start transition-none hover:bg-accent hover:text-accent-foreground"
                >
                  <Lucideicons.chevron_right class="transition-transform group-data-[state=open]:rotate-90" />
                  <Lucideicons.folder />
                  components
                </.as_child>
                <.collapsible_content class="mt-1 ml-5">
                  <div class="flex flex-col gap-1">
                    <.collapsible id="file-tree-components-ui">
                      <.as_child
                        tag={&collapsible_trigger/1}
                        child={&button/1}
                        variant="ghost"
                        size="sm"
                        class="group w-full justify-start transition-none hover:bg-accent hover:text-accent-foreground"
                      >
                        <Lucideicons.chevron_right class="transition-transform group-data-[state=open]:rotate-90" />
                        <Lucideicons.folder />
                        ui
                      </.as_child>
                      <.collapsible_content class="mt-1 ml-5">
                        <div class="flex flex-col gap-1">
                          <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                            <Lucideicons.file />
                            <span>button.tsx</span>
                          </.button>
                          <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                            <Lucideicons.file />
                            <span>card.tsx</span>
                          </.button>
                          <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                            <Lucideicons.file />
                            <span>dialog.tsx</span>
                          </.button>
                          <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                            <Lucideicons.file />
                            <span>input.tsx</span>
                          </.button>
                          <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                            <Lucideicons.file />
                            <span>select.tsx</span>
                          </.button>
                          <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                            <Lucideicons.file />
                            <span>table.tsx</span>
                          </.button>
                        </div>
                      </.collapsible_content>
                    </.collapsible>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>login-form.tsx</span>
                    </.button>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>register-form.tsx</span>
                    </.button>
                  </div>
                </.collapsible_content>
              </.collapsible>
              <.collapsible id="file-tree-lib">
                <.as_child
                  tag={&collapsible_trigger/1}
                  child={&button/1}
                  variant="ghost"
                  size="sm"
                  class="group w-full justify-start transition-none hover:bg-accent hover:text-accent-foreground"
                >
                  <Lucideicons.chevron_right class="transition-transform group-data-[state=open]:rotate-90" />
                  <Lucideicons.folder />
                  lib
                </.as_child>
                <.collapsible_content class="mt-1 ml-5">
                  <div class="flex flex-col gap-1">
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>utils.ts</span>
                    </.button>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>cn.ts</span>
                    </.button>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>api.ts</span>
                    </.button>
                  </div>
                </.collapsible_content>
              </.collapsible>
              <.collapsible id="file-tree-hooks">
                <.as_child
                  tag={&collapsible_trigger/1}
                  child={&button/1}
                  variant="ghost"
                  size="sm"
                  class="group w-full justify-start transition-none hover:bg-accent hover:text-accent-foreground"
                >
                  <Lucideicons.chevron_right class="transition-transform group-data-[state=open]:rotate-90" />
                  <Lucideicons.folder />
                  hooks
                </.as_child>
                <.collapsible_content class="mt-1 ml-5">
                  <div class="flex flex-col gap-1">
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>use-media-query.ts</span>
                    </.button>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>use-debounce.ts</span>
                    </.button>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>use-local-storage.ts</span>
                    </.button>
                  </div>
                </.collapsible_content>
              </.collapsible>
              <.collapsible id="file-tree-types">
                <.as_child
                  tag={&collapsible_trigger/1}
                  child={&button/1}
                  variant="ghost"
                  size="sm"
                  class="group w-full justify-start transition-none hover:bg-accent hover:text-accent-foreground"
                >
                  <Lucideicons.chevron_right class="transition-transform group-data-[state=open]:rotate-90" />
                  <Lucideicons.folder />
                  types
                </.as_child>
                <.collapsible_content class="mt-1 ml-5">
                  <div class="flex flex-col gap-1">
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>index.d.ts</span>
                    </.button>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>api.d.ts</span>
                    </.button>
                  </div>
                </.collapsible_content>
              </.collapsible>
              <.collapsible id="file-tree-public">
                <.as_child
                  tag={&collapsible_trigger/1}
                  child={&button/1}
                  variant="ghost"
                  size="sm"
                  class="group w-full justify-start transition-none hover:bg-accent hover:text-accent-foreground"
                >
                  <Lucideicons.chevron_right class="transition-transform group-data-[state=open]:rotate-90" />
                  <Lucideicons.folder />
                  public
                </.as_child>
                <.collapsible_content class="mt-1 ml-5">
                  <div class="flex flex-col gap-1">
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>favicon.ico</span>
                    </.button>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>logo.svg</span>
                    </.button>
                    <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                      <Lucideicons.file />
                      <span>images</span>
                    </.button>
                  </div>
                </.collapsible_content>
              </.collapsible>
              <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                <Lucideicons.file />
                <span>app.tsx</span>
              </.button>
              <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                <Lucideicons.file />
                <span>layout.tsx</span>
              </.button>
              <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                <Lucideicons.file />
                <span>globals.css</span>
              </.button>
              <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                <Lucideicons.file />
                <span>package.json</span>
              </.button>
              <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                <Lucideicons.file />
                <span>tsconfig.json</span>
              </.button>
              <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                <Lucideicons.file />
                <span>README.md</span>
              </.button>
              <.button variant="link" size="sm" class="w-full justify-start gap-2 text-foreground">
                <Lucideicons.file />
                <span>.gitignore</span>
              </.button>
            </div>
          </.card_content>
        </.card>
        """
      }
    ]
  end
end
