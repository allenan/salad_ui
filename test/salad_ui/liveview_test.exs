defmodule SaladUI.LiveViewTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveView.JS

  describe "SaladUI.JS.dispatch_command/3" do
    test "supports direct call with opts and scopes client command by default" do
      assert %JS{ops: [["dispatch", args]]} = SaladUI.JS.dispatch_command("open", to: "#dialog")

      assert args.event == "salad_ui:command"
      assert args.to == "#dialog"
      assert args.bubbles == false
      assert args.detail == %{command: "open", params: %{}}
    end

    test "supports JS pipeline, command params, and explicit bubbling override" do
      js = SaladUI.JS.dispatch_command(%JS{}, "update", to: "#chart", detail: %{data: %{labels: [1]}}, bubbles: true)

      assert %JS{ops: [["dispatch", args]]} = js
      assert args.to == "#chart"
      assert args.bubbles == true
      assert args.detail == %{command: "update", params: %{data: %{labels: [1]}}}
    end

    test "carries the shared menu placeholders in its params" do
      js =
        SaladUI.JS.dispatch_command("open",
          to: "#emoji-picker",
          detail: %{anchor: SaladUI.JS.trigger(), values: %{id: SaladUI.JS.context(:id)}, ctx: SaladUI.JS.context()}
        )

      assert %JS{ops: [["dispatch", %{detail: %{params: params}}]]} = js
      assert params.anchor == %{"__salad__" => "trigger"}
      assert params.values == %{id: %{"__salad__" => "context", "key" => "id"}}
      assert params.ctx == %{"__salad__" => "context"}
      assert SaladUI.JS.context("id") == SaladUI.JS.context(:id)

      # They survive the JSON a phx-click carries.
      assert js |> Jason.encode!() |> Jason.decode!() |> hd() |> List.last() |> get_in(["detail", "params", "anchor"]) ==
               %{"__salad__" => "trigger"}
    end
  end

  describe "SaladUI.JS.copy/2" do
    test "dispatches a bubbling salad_ui:copy with the text source" do
      assert %JS{ops: [["dispatch", args]]} =
               SaladUI.JS.copy(within: "[data-row]", from: "[data-message-text]", ignored: 1)

      assert args.event == "salad_ui:copy"
      refute Map.has_key?(args, :to)
      assert args.detail == %{within: "[data-row]", from: "[data-message-text]"}
    end

    test "chains onto a JS pipeline and takes a context placeholder as text" do
      js = "copied" |> JS.push() |> SaladUI.JS.copy(text: SaladUI.JS.context(:url))

      assert %JS{ops: [["push", _], ["dispatch", %{detail: %{text: %{"__salad__" => "context"}}}]]} = js
    end
  end
end
