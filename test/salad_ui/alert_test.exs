defmodule SaladUI.AlertTest do
  use ComponentCase

  import SaladUI.Alert

  describe "Test Alerting" do
    test "it renders default alert correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert>
          <.alert_title>Heads up!</.alert_title>

          <.alert_description>Alert Descriptions</.alert_description>
        </.alert>
        """)

      for class <- ~w(col-start-2 line-clamp-1 min-h-4 font-medium tracking-tight) do
        assert html =~ class
      end

      assert html =~ "Heads up!"
      assert html =~ "Alert Descriptions"
      assert html =~ ~s(role="alert")

      for class <-
            ~w|relative grid w-full grid-cols-[0_1fr] items-start gap-y-0.5 rounded-lg border px-4 py-3 text-sm has-[&gt;svg]:grid-cols-[calc(var(--spacing)*4)_1fr] has-[&gt;svg]:gap-x-3 [&amp;&gt;svg]:size-4 [&amp;&gt;svg]:translate-y-0.5 [&amp;&gt;svg]:text-current bg-card text-card-foreground| do
        assert html =~ class
      end
    end

    test "a heroicon or legacy <span> icon wrapper gets the icon column too" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert>
          <span class="hero-check-circle"></span>
          <.alert_title>Saved</.alert_title>
        </.alert>
        """)

      for class <-
            ~w|has-[&gt;span]:grid-cols-[calc(var(--spacing)*4)_1fr] has-[&gt;span]:gap-x-3 [&amp;&gt;span]:size-4 [&amp;&gt;span]:translate-y-0.5| do
        assert html =~ class
      end
    end

    test "It renders destructive alert correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert variant="destructive">
          <.alert_title>Heads up!</.alert_title>

          <.alert_description>
            You can add components to your app using the cli
          </.alert_description>
        </.alert>
        """)

      for class <-
            ~w(relative grid rounded-lg bg-card text-destructive w-full *:data-[slot=alert-description]:text-destructive/90) do
        assert html =~ class
      end

      refute html =~ "text-card-foreground"

      assert html =~ "Heads up!"
      assert html =~ "You can add components to your app using the cli"
    end

    test "It renders alert title correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_title>Alert title</.alert_title>
        """)

      assert html =~
               ~s(<div data-slot="alert-title" class="col-start-2 line-clamp-1 min-h-4 font-medium tracking-tight">)

      assert html =~ "Alert title"
    end

    test "it renders alert description correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_description>Alert description</.alert_description>
        """)

      assert html =~ "Alert description"

      assert html =~
               ~s(<div data-slot="alert-description" class="col-start-2 grid justify-items-start gap-1 text-sm text-muted-foreground [&amp;_p]:leading-relaxed">)
    end
  end
end
