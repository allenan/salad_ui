defmodule SaladUI.Mix.Tasks.IgniterMissing do
  @moduledoc false
  # `igniter` is an optional dependency: SaladUI's installer tasks fall back to
  # this message when the app doesn't have it.

  def run(task) do
    Mix.shell().error("""
    The task `mix #{task}` needs the `igniter` package, an optional dependency of SaladUI.

    Add it to your deps in mix.exs and run `mix deps.get`:

        {:igniter, "~> 0.6", only: [:dev, :test]}

    or install SaladUI with `mix igniter.install salad_ui`, which adds both.
    See https://hexdocs.pm/igniter/readme.html#installation
    """)

    exit({:shutdown, 1})
  end
end
