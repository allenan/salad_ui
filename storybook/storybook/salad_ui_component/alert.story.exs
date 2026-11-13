defmodule Storybook.SaladUIComponents.Alert do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladStorybookWeb.CoreComponents
  alias SaladUI.Alert

  def function, do: &Alert.alert/1

  def imports, do: [{Alert, [alert_title: 1, alert_description: 1]}, {CoreComponents, [icon: 1]}]

  def variations do
    [
      %Variation{
        id: :default_alert,
        template: """
        <.alert>
          <.icon name="hero-command-line" class="size-4" />
          <.alert_title>Heads up!</.alert_title>
          <.alert_description>
            You can add components to your app using the cli
          </.alert_description>
        </.alert>
        """,
        attributes: %{}
      },
      %Variation{
        id: :destructive,
        template: """
        <.alert variant="destructive">
          <.icon name="hero-exclamation-triangle" class="size-4" />
          <.alert_title>Heads up!</.alert_title>
          <.alert_description>
            You can add components to your app using the cli
          </.alert_description>
        </.alert>
        """,
        attributes: %{}
      },
      %Variation{
        id: :alert_basic,
        description: "shadcn alert-basic: a bare lucide `<svg>` as the first child takes the icon column.",
        template: """
        <.alert class="max-w-md">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10" />
            <path d="m9 12 2 2 4-4" />
          </svg>
          <.alert_title>Account updated successfully</.alert_title>
          <.alert_description>
            Your profile information has been saved. Changes will be reflected immediately.
          </.alert_description>
        </.alert>
        """
      },
      %Variation{
        id: :alert_colors,
        description: "shadcn alert-colors: custom colors through `class`.",
        template: """
        <.alert class="max-w-md border-amber-200 bg-amber-50 text-amber-900 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-50">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" />
            <path d="M12 9v4" />
            <path d="M12 17h.01" />
          </svg>
          <.alert_title>Your subscription will expire in 3 days.</.alert_title>
          <.alert_description>
            Renew now to avoid service interruption or upgrade to a paid plan to continue using the service.
          </.alert_description>
        </.alert>
        """
      },
      %Variation{
        id: :no_icon,
        template: """
        <.alert class="max-w-md">
          <.alert_title>Heads up!</.alert_title>
          <.alert_description>The title and description sit in the second column when there is no icon.</.alert_description>
        </.alert>
        """
      }
    ]
  end
end
