import Config

config :tailwind,
  version: "4.3.5",
  default: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ],
  storybook: [
    args: ~w(
          --input=assets/css/storybook.css
          --output=priv/static/assets/storybook.css
        ),
    cd: Path.expand("..", __DIR__)
  ]

# Exercises the app theme extension in SaladUI.ClassMerge (see its moduledoc).
if config_env() == :test do
  config :salad_ui, :class_merge, theme: [text: ~w(panel), color: ~w(star), radius: ~w(control)]
end
