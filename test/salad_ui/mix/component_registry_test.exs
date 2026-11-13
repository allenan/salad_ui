defmodule SaladUI.Mix.Tasks.ComponentRegistryTest do
  use ExUnit.Case, async: true

  alias SaladUI.Mix.Tasks.ComponentRegistry

  setup_all do
    %{registry: ComponentRegistry.load(File.cwd!())}
  end

  defp resolve!(registry, names) do
    {:ok, plan} = ComponentRegistry.resolve(registry, List.wrap(names))
    plan
  end

  describe "dependency map integrity" do
    # These guard `mix salad.add` against copying a component without
    # something it needs. If one fails after adding a component, the new
    # code references something the scanner can't map to a file.
    test "every SaladUI module reference resolves to a file", %{registry: registry} do
      assert ComponentRegistry.unresolved_refs(registry) == []
    end

    test "every data-component has a registered JS implementation", %{registry: registry} do
      assert ComponentRegistry.unregistered_components(registry) == []
    end

    test "every relative JS import resolves to a file", %{registry: registry} do
      assert ComponentRegistry.unresolved_js_imports(registry) == []
    end

    test "every module ui.ex can import is defined by a component file", %{registry: registry} do
      using = File.read!("lib/salad_ui.ex")

      for [module] <- Regex.scan(~r/^\s+import (SaladUI\.[\w.]+)/m, using, capture: :all_but_first) do
        assert Map.has_key?(registry.modules, module), "#{module} is imported by SaladUI.__using__ but not defined"
      end
    end

    test "every component resolves to a self-contained plan", %{registry: registry} do
      for name <- ComponentRegistry.component_names(registry) do
        plan = resolve!(registry, name)

        assert "#{name}.ex" in plan.ex_files
        assert "helpers.ex" in plan.ex_files
        assert "class_merge.ex" in plan.ex_files

        for entry <- plan.js_entries do
          assert entry in plan.js_files
          assert "index.js" in plan.js_files
        end

        # every JS file the plan copies only imports files the plan copies
        for file <- plan.js_files, import <- registry.js[file].imports do
          assert import in plan.js_files, "#{name}: #{file} imports #{import}, which is not copied"
        end
      end
    end
  end

  describe "resolve/2" do
    test "pure markup components need no JavaScript", %{registry: registry} do
      plan = resolve!(registry, "button")

      assert plan.ex_files == ["button.ex", "class_merge.ex", "helpers.ex"]
      assert plan.modules == ["SaladUI.Button", "SaladUI.ClassMerge", "SaladUI.Helpers"]
      assert plan.js_entries == []
      assert plan.js_files == []
    end

    test "follows module references transitively", %{registry: registry} do
      plan = resolve!(registry, "sidebar")

      for file <- ~w(sidebar.ex input.ex separator.ex skeleton.ex) do
        assert file in plan.ex_files
      end

      refute "dropdown_menu.ex" in plan.ex_files
      refute "tooltip.ex" in plan.ex_files
      assert plan.js_entries == ["components/sidebar.js"]
      assert "core/positioned-element.js" in plan.js_files
    end

    test "includes nested modules in subdirectories", %{registry: registry} do
      assert "questionnaire/state.ex" in resolve!(registry, "questionnaire").ex_files
    end

    test "copies JS imported by an entry without importing it from app.js", %{registry: registry} do
      plan = resolve!(registry, "drawer")

      assert plan.js_entries == ["components/drawer.js"]
      assert "components/dialog.js" in plan.js_files

      plan = resolve!(registry, "dropdown_menu")
      assert plan.js_entries == ["components/dropdown_menu.js"]
      assert "components/menu.js" in plan.js_files
    end

    test "copies only the core modules that are imported", %{registry: registry} do
      plan = resolve!(registry, "tabs")

      assert "core/component.js" in plan.js_files
      assert "core/hook.js" in plan.js_files
      refute "core/positioned-element.js" in plan.js_files

      assert "core/positioned-element.js" in resolve!(registry, "popover").js_files
    end

    test "copies data a component loads with import(), with its license", %{registry: registry} do
      plan = resolve!(registry, "emoji_picker")

      assert "popover.ex" in plan.ex_files
      assert plan.js_entries == ["components/emoji_picker.js", "components/popover.js"]
      assert "components/emoji_picker/data.json" in plan.js_files
      assert "components/emoji_picker/DATA_LICENSE.txt" in plan.js_files
      refute "components/emoji_picker/generate_data.exs" in plan.js_files
      assert plan.packages == []
    end

    test "reports npm packages the JS needs", %{registry: registry} do
      assert resolve!(registry, "chart").packages == ["chart.js"]
      assert resolve!(registry, "dialog").packages == []
    end

    test "merges several components", %{registry: registry} do
      plan = resolve!(registry, ["dialog", "tabs", "dialog"])

      assert plan.components == ["dialog", "tabs"]
      assert plan.js_entries == ["components/dialog.js", "components/tabs.js"]
    end

    test "rejects unknown names", %{registry: registry} do
      assert ComponentRegistry.resolve(registry, ["dialog", "nope", "zzz"]) == {:error, {:unknown, ["nope", "zzz"]}}
    end
  end

  test "normalize_name/1 accepts kebab-case, CamelCase, file names and shadcn aliases" do
    assert ComponentRegistry.normalize_name("alert-dialog") == "alert_dialog"
    assert ComponentRegistry.normalize_name("AlertDialog") == "alert_dialog"
    assert ComponentRegistry.normalize_name("alert_dialog.ex") == "alert_dialog"
    assert ComponentRegistry.normalize_name("input-otp") == "input_otp"
    assert ComponentRegistry.normalize_name("sonner") == "toast"
  end
end
