defmodule SaladUI.Mix.JSImportListTest do
  @moduledoc """
  Every JS component that registers itself must be imported by both
  `mix salad.setup` and `mix salad.install`, or its markup renders but never
  wires up. `chart` is opt-in because it needs the `chart.js` npm package.
  """
  use ExUnit.Case, async: true

  @opt_in ~w(chart)
  @root Path.expand("../../..", __DIR__)

  defp registered_components do
    @root
    |> Path.join("assets/salad_ui/components/*.js")
    |> Path.wildcard()
    |> Enum.filter(&(File.read!(&1) =~ ~r/SaladUI\.register\(/))
    |> Enum.map(&Path.basename(&1, ".js"))
    |> Kernel.--(@opt_in)
    |> Enum.sort()
  end

  test "registered components are all non-empty" do
    assert "dialog" in registered_components()
    assert "command" in registered_components()
  end

  for {task, pattern} <- [
        {"lib/mix/tasks/salad.setup.ex", ~s(import "salad_ui/components/NAME";)},
        {"lib/mix/tasks/salad.install.ex", ~s(import "./ui/components/NAME.js";)}
      ] do
    test "#{task} imports every registered component" do
      source = File.read!(Path.join(@root, unquote(task)))

      missing =
        Enum.reject(registered_components(), fn name ->
          String.contains?(source, String.replace(unquote(pattern), "NAME", name))
        end)

      assert missing == [], "#{unquote(task)} is missing JS imports for: #{Enum.join(missing, ", ")}"
    end
  end
end
