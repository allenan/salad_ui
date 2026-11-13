#!/usr/bin/env bash
# End-to-end check of the SaladUI installers against a freshly generated
# Phoenix app: generate app -> install -> assert patched files -> compile with
# warnings as errors -> build assets -> mount components in a real LiveView.
#
# Usage: .github/scripts/installer-e2e/run.sh <setup|install|add>
# Requires: Elixir/Erlang (matching .tool-versions) and the phx_new archive.
set -euo pipefail

MODE="${1:?usage: run.sh <setup|install|add>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

# add mode: the components salad_smoke_test.exs renders (dropdown-menu pulls
# in menu.js; the rest of the library must stay out).
ADD_COMPONENTS=(button badge card avatar dialog tabs select dropdown-menu tooltip)
# then a second run without --prefix (it is reused) whose components pull in
# other modules: sidebar -> tooltip/input/separator/skeleton (+ sidebar.js),
# date_picker -> calendar/popover/button.
ADD_MORE=(sidebar date_picker)

run_installer() {
  case "$MODE" in
    setup) mix salad.setup --yes ;;
    install) mix salad.install --yes --prefix DemoWeb.UI ;;
    add) mix salad.add --yes --prefix DemoWeb.UI "${ADD_COMPONENTS[@]}" ;;
  esac
}

cp "$REPO/.tool-versions" "$WORK/" 2>/dev/null || true
cd "$WORK"

step "phx.new demo"
mix phx.new demo --no-ecto --no-mailer --no-dashboard --no-gettext --install
cd demo

step "add salad_ui (path: $REPO)"
perl -0pi -e "s|(\{:phoenix, \"[^\"]+\"\},)|\$1\n      {:salad_ui, path: \"$REPO\"},|" mix.exs
grep -q ':salad_ui, path:' mix.exs || fail "could not add salad_ui dep to mix.exs"
mix deps.get
# Path deps aren't copied into deps/; link it so the installer's
# `@source "../../deps/salad_ui/..."` directives resolve like a Hex install.
ln -sfn "$REPO" deps/salad_ui

case "$MODE" in
  setup) USE_LINE="use SaladUI" ;;
  install | add) USE_LINE="use DemoWeb.UI" ;;
  *) fail "unknown mode: $MODE" ;;
esac

step "mix salad.$MODE"
run_installer

step "assert patched files"
grep -q 'SaladUI: SaladUI.SaladUIHook' assets/js/app.js || fail "hook not registered in app.js"
[ "$(grep -c '@import "tailwindcss"' assets/css/app.css)" = 1 ] || fail "tailwindcss imported more than once"
[ "$(grep -c '@custom-variant dark' assets/css/app.css)" = 1 ] || fail "duplicate dark variant"
grep -q 'border-border' assets/css/app.css || fail "base border rule missing"
grep -q 'hsl(var(' assets/css/app.css && fail "hsl() wrapping oklch tokens (invalid CSS)"
# shadcn's theme CSS names the sidebar background `--sidebar`; the theme must
# read it (falling back to the legacy `--sidebar-background`).
grep -q -- '--sidebar:' assets/css/app.css || fail "color scheme does not define --sidebar"
grep -qF -- '--color-sidebar: var(--sidebar, var(--sidebar-background));' assets/css/app.css ||
  fail "theme does not map --color-sidebar to --sidebar"

if [ "$MODE" = add ]; then
  step "assert only the selected components and their dependencies were copied"
  UI=lib/demo_web/ui
  for f in ui.ex ui/button.ex ui/dropdown_menu.ex ui/tooltip.ex ui/helpers.ex; do
    [ -f "lib/demo_web/$f" ] || fail "missing lib/demo_web/$f"
  done
  for f in sidebar.ex sheet.ex calendar.ex data_table.ex; do
    [ ! -e "$UI/$f" ] || fail "$UI/$f copied but not requested"
  done
  for f in index.js core/component.js components/dialog.js components/dropdown_menu.js components/menu.js; do
    [ -f "assets/js/ui/$f" ] || fail "missing assets/js/ui/$f"
  done
  for f in components/carousel.js components/calendar.js; do
    [ ! -e "assets/js/ui/$f" ] || fail "assets/js/ui/$f copied but not requested"
  done
  grep -q 'import "./ui/components/dropdown_menu.js";' assets/js/app.js || fail "dropdown_menu.js not imported"
  ! grep -q 'import "./ui/components/menu.js";' assets/js/app.js || fail "menu.js imported directly (dropdown_menu.js imports it)"
  ! grep -q 'import DemoWeb.UI.Sidebar' lib/demo_web/ui.ex || fail "ui.ex imports a module that was not copied"
fi

step "re-run is idempotent"
cp assets/css/app.css "$WORK/app.css.before"
cp assets/js/app.js "$WORK/app.js.before"
if [ "$MODE" = add ]; then (cd lib && find . -name "*.ex" -exec cksum {} + | sort) > "$WORK/lib.before"; fi
run_installer
cmp -s assets/css/app.css "$WORK/app.css.before" || fail "app.css changed on re-run"
cmp -s assets/js/app.js "$WORK/app.js.before" || fail "app.js changed on re-run"
if [ "$MODE" = add ]; then
  (cd lib && find . -name '*.ex' -exec cksum {} + | sort) | cmp -s - "$WORK/lib.before" || fail "lib/ changed on re-run"
fi

if [ "$MODE" = add ]; then
  step "mix salad.add ${ADD_MORE[*]} (prefix reused)"
  mix salad.add --yes "${ADD_MORE[@]}"
  for f in sidebar.ex skeleton.ex separator.ex input.ex date_picker.ex calendar.ex popover.ex; do
    [ -f "lib/demo_web/ui/$f" ] || fail "missing lib/demo_web/ui/$f"
  done
  [ ! -e lib/demo_ui ] || fail "second add ignored the existing DemoWeb.UI prefix"
  grep -q 'import DemoWeb.UI.Sidebar' lib/demo_web/ui.ex || fail "ui.ex missing the new import"
  grep -q 'import DemoWeb.UI.DropdownMenu' lib/demo_web/ui.ex || fail "ui.ex lost an earlier import"
  grep -q 'import "./ui/components/calendar.js";' assets/js/app.js || fail "calendar.js not imported"
  grep -q 'import "./ui/components/sidebar.js";' assets/js/app.js || fail "sidebar.js not imported"
  [ "$(grep -c 'SaladUI.SaladUIHook' assets/js/app.js)" = 1 ] || fail "hook registered twice"
fi

step "compile (warnings as errors)"
mix compile --warnings-as-errors

step "build assets"
mix assets.build
grep -q 'SaladUIHook' priv/static/assets/js/app.js || fail "SaladUI hook missing from JS bundle"
grep -q 'bg-primary' priv/static/assets/css/app.css || fail "SaladUI classes missing from CSS bundle"
grep -qE 'var\(--sidebar, ?var\(--sidebar-background\)\)' priv/static/assets/css/app.css ||
  fail "bg-sidebar does not resolve to --sidebar in the CSS bundle"

step "mount components in a LiveView"
mkdir -p test/demo_web
sed "s/__USE_SALAD__/$USE_LINE/" "$HERE/salad_smoke_test.exs" > test/demo_web/salad_smoke_test.exs
mix test test/demo_web/salad_smoke_test.exs

echo; echo "OK: installer e2e ($MODE)"
