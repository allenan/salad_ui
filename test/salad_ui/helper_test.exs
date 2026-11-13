defmodule SaladUI.HelperTest do
  use ExUnit.Case, async: true

  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS
  alias SaladUI.Helpers

  test "prepare_assign with default value" do
    assigns = %{__changed__: %{}}
    assert %{value: nil} = Helpers.prepare_assign(assigns)

    assigns = %{__changed__: %{}, value: "test"}
    assert %{value: "test"} = Helpers.prepare_assign(assigns)

    assigns = %{__changed__: %{}, value: ""}
    assert %{value: nil} = Helpers.prepare_assign(assigns)

    assigns = %{__changed__: %{}, value: []}
    assert %{value: nil} = Helpers.prepare_assign(assigns)
  end

  test "prepare_assign using default value if value is missing or empty" do
    assigns = %{__changed__: %{}, value: "", "default-value": "default"}
    assert %{value: "default"} = Helpers.prepare_assign(assigns)

    assigns = %{__changed__: %{}, value: nil, "default-value": "default"}
    assert %{value: "default"} = Helpers.prepare_assign(assigns)

    assigns = %{__changed__: %{}, value: [], "default-value": "default"}
    assert %{value: "default"} = Helpers.prepare_assign(assigns)

    assigns = %{__changed__: %{}, value: "test", "default-value": "default"}
    assert %{value: "test"} = Helpers.prepare_assign(assigns)
  end

  test "prepare_assign override name/value if provided" do
    assigns = %{
      __changed__: %{},
      value: "test",
      name: "name",
      field: %FormField{value: "value", name: "field", id: "a", errors: [], field: :name, form: nil}
    }

    assert %{value: "test", name: "name"} = Helpers.prepare_assign(assigns)
  end

  test "prepare_assign preserves explicit falsy value over field value" do
    assigns = %{
      __changed__: %{},
      value: false,
      field: %FormField{value: true, name: "field", id: "a", errors: [], field: :name, form: nil}
    }

    assert %{value: false} = Helpers.prepare_assign(assigns)
  end

  test "prepare_assign used name/value from field" do
    assigns = %{
      __changed__: %{},
      field: %FormField{value: "value", name: "field", id: "a", errors: [], field: :name, form: nil}
    }

    assert %{value: "value", name: "field"} = Helpers.prepare_assign(assigns)
  end

  test "prepare_assign build name for multiple" do
    assigns = %{
      __changed__: %{},
      multiple: "true",
      field: %FormField{value: "value", name: "name", id: "a", errors: [], field: :name, form: nil}
    }

    assert %{name: "name[]"} = Helpers.prepare_assign(assigns)
  end

  test "event_mappings collects assigned on-* handlers" do
    assigns = %{
      :"on-open" => "opened",
      :"on-value-changed" => %JS{},
      :"on-close" => nil,
      :"on-select" => false,
      id: "dialog"
    }

    assert %{
             "open" => "opened",
             "value-changed" => %JS{}
           } = Helpers.event_mappings(assigns)
  end

  test "build error with custom translation function" do
    previous = Application.fetch_env(:salad_ui, :error_translator_function)
    Application.put_env(:salad_ui, :error_translator_function, {__MODULE__, :translate_error})

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:salad_ui, :error_translator_function, value)
        :error -> Application.delete_env(:salad_ui, :error_translator_function)
      end
    end)

    assigns = %{
      __changed__: %{},
      field: %FormField{
        value: "value",
        name: "name",
        id: "a",
        errors: [{"error 1", []}, {"error 2", []}],
        field: :name,
        form: nil
      }
    }

    assert %{errors: ["translated error 1", "translated error 2"]} = Helpers.prepare_assign(assigns)
  end

  def translate_error({"error 1", _}), do: "translated error 1"
  def translate_error({"error 2", _}), do: "translated error 2"

  describe "tw_merge/1" do
    test "merges conflicting Tailwind classes, later wins" do
      assert Helpers.tw_merge(["px-2 py-1", nil, "px-4"]) == "py-1 px-4"
    end

    test "keeps not-* opt-out classes TwMerge cannot parse instead of crashing" do
      # kept where it was, like any class TwMerge has no group for
      assert Helpers.tw_merge(["flex px-2", "not-typeset px-4", nil]) == "flex not-typeset px-4"
      assert Helpers.tw_merge(["not-prose"]) == "not-prose"
      assert Helpers.tw_merge(["not-italic"]) == "not-italic"
    end

    test "keeps the scroll-fade utilities side by side" do
      assert Helpers.tw_merge(["scroll-fade-x data-wrap:scroll-fade-y", "scroll-fade-y scroll-fade-8"]) ==
               "scroll-fade-x data-wrap:scroll-fade-y scroll-fade-y scroll-fade-8"
    end
  end

  describe "style/1" do
    test "merges maps and appends a single trailing semicolon" do
      assert Helpers.style([%{color: "red"}, %{"font-size": "16px"}]) == "color: red; font-size: 16px;"
    end

    test "preserves the original order of raw string declarations" do
      assert Helpers.style(["color: red", "font-weight: bold"]) == "color: red; font-weight: bold;"
    end

    test "keeps map declarations before raw string declarations, in order" do
      assert Helpers.style([%{color: "red"}, "font-weight: bold"]) == "color: red; font-weight: bold;"
    end

    test "returns an empty string when nothing is provided" do
      assert Helpers.style([%{}]) == ""
      assert Helpers.style([]) == ""
    end
  end
end
