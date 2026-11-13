defmodule Storybook.SaladUIComponents.Card do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Badge
  alias SaladUI.Button
  alias SaladUI.Card
  alias SaladUI.Input
  alias SaladUI.Label

  def function, do: &Card.card/1
  def layout, do: :one_column

  def imports,
    do: [
      {Card, [card_header: 1, card_title: 1, card_description: 1, card_action: 1, card_content: 1, card_footer: 1]},
      {Badge, [badge: 1]},
      {Button, [button: 1]},
      {Input, [input: 1]},
      {Label, [label: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :card,
        template: """
        <.card class="w-[350px]">
          <.card_header>
            <.card_title>Create your project</.card_title>
            <.card_description>Deploy your new project in one-click.</.card_description>
          </.card_header>
          <.card_content>
            <form>
              <div class="grid w-full items-center gap-4">
                <div class="flex flex-col space-y-1.5">
                  <.label html-for="name">Name</.label>
                  <.input id="name" placeholder="Name of your project" />
                </div>
              </div>
            </form>
          </.card_content>
          <.card_footer class="flex justify-between">
            <.button variant="outline">Cancel</.button>
            <.button>Deploy</.button>
          </.card_footer>
        </.card>
        """,
        attributes: %{}
      },
      %Variation{
        id: :with_action,
        description: "`card_action` sits in the top-right corner of the header.",
        template: """
        <.card class="w-full max-w-sm">
          <.card_header>
            <.card_title>Login to your account</.card_title>
            <.card_description>Enter your email below to login to your account</.card_description>
            <.card_action>
              <.button variant="link">Sign Up</.button>
            </.card_action>
          </.card_header>
          <.card_content>
            <form>
              <div class="flex flex-col gap-6">
                <div class="grid gap-2">
                  <.label for="card-email">Email</.label>
                  <.input id="card-email" type="email" placeholder="m@example.com" required />
                </div>
                <div class="grid gap-2">
                  <div class="flex items-center">
                    <.label for="card-password">Password</.label>
                    <a href="#" class="ml-auto inline-block text-sm underline-offset-4 hover:underline">
                      Forgot your password?
                    </a>
                  </div>
                  <.input id="card-password" type="password" required />
                </div>
              </div>
            </form>
          </.card_content>
          <.card_footer class="flex-col gap-2">
            <.button type="submit" class="w-full">Login</.button>
            <.button variant="outline" class="w-full">Login with Google</.button>
          </.card_footer>
        </.card>
        """
      },
      %Variation{
        id: :small,
        description: ~s|`size="sm"` uses tighter spacing.|,
        template: """
        <.card size="sm" class="mx-auto w-full max-w-sm">
          <.card_header>
            <.card_title>Small Card</.card_title>
            <.card_description>This card uses the small size variant.</.card_description>
          </.card_header>
          <.card_content>
            <p>
              The card component supports a size prop that can be set to
              "sm" for a more compact appearance.
            </p>
          </.card_content>
          <.card_footer>
            <.button variant="outline" size="sm" class="w-full">Action</.button>
          </.card_footer>
        </.card>
        """
      },
      %Variation{
        id: :spacing,
        description: "Override the `--card-spacing` CSS variable to change the inset and section gap.",
        template: """
        <div class="mx-auto grid w-full max-w-sm gap-4">
          <.card :for={spacing <- ["[--card-spacing:--spacing(3)]", "[--card-spacing:--spacing(8)]"]} class={spacing}>
            <.card_header>
              <.card_title>Login to your account</.card_title>
              <.card_description>{spacing}</.card_description>
              <.card_action>
                <.button variant="link">Sign Up</.button>
              </.card_action>
            </.card_header>
            <.card_content>
              <.input type="email" placeholder="m@example.com" />
            </.card_content>
            <.card_footer class="flex-col gap-2">
              <.button class="w-full">Login</.button>
            </.card_footer>
          </.card>
        </div>
        """
      },
      %Variation{
        id: :edge_to_edge,
        description: "Negative `--card-spacing` margins let content run edge to edge.",
        template: """
        <.card class="mx-auto w-full max-w-sm">
          <.card_header>
            <.card_title>Terms of Service</.card_title>
            <.card_description>Review the terms before accepting the agreement.</.card_description>
          </.card_header>
          <.card_content class="-mb-(--card-spacing)">
            <div class="-mx-(--card-spacing) max-h-48 space-y-4 overflow-y-scroll border-t bg-muted/50 px-(--card-spacing) py-4 text-sm leading-relaxed">
              <p>
                These terms govern your use of the workspace, including access to
                shared documents, project files, and collaboration tools.
              </p>
              <p>
                You are responsible for the content you upload and for ensuring that
                your team has the appropriate permissions to view or edit it.
              </p>
              <p>
                We may update features or limits as the service evolves. When those
                changes materially affect your workflow, we will notify your
                workspace administrators.
              </p>
              <p>
                By continuing, you agree to keep your account credentials secure and
                to follow your organization's acceptable use policies.
              </p>
            </div>
          </.card_content>
          <.card_footer class="justify-end gap-2 border-t">
            <.button variant="outline">Decline</.button>
            <.button>Accept</.button>
          </.card_footer>
        </.card>
        """
      },
      %Variation{
        id: :image,
        description: "An image placed before the header becomes the card cover.",
        template: """
        <.card class="relative mx-auto w-full max-w-sm pt-0">
          <div class="absolute inset-0 z-30 aspect-video rounded-t-xl bg-black/35" />
          <img
            src="https://avatar.vercel.sh/shadcn1"
            alt="Event cover"
            class="relative z-20 aspect-video w-full rounded-t-xl object-cover brightness-60 grayscale dark:brightness-40"
          />
          <.card_header>
            <.card_action>
              <.badge variant="secondary">Featured</.badge>
            </.card_action>
            <.card_title>Design systems meetup</.card_title>
            <.card_description>
              A practical talk on component APIs, accessibility, and shipping faster.
            </.card_description>
          </.card_header>
          <.card_footer>
            <.button class="w-full">View Event</.button>
          </.card_footer>
        </.card>
        """
      }
    ]
  end
end
