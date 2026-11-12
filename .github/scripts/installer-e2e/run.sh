#!/usr/bin/env bash
# End-to-end check of the SaladUI installers against a freshly generated
# Phoenix app: generate app -> install -> assert patched files -> compile with
# warnings as errors -> build assets -> mount components in a real LiveView.
#
# Usage: .github/scripts/installer-e2e/run.sh <setup|install>
# Requires: Elixir/Erlang (matching .tool-versions) and the phx_new archive.
set -euo pipefail

MODE="${1:?usage: run.sh <setup|install>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

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
  setup)
    step "mix salad.setup"
    mix salad.setup --yes
    USE_LINE="use SaladUI"
    ;;
  install)
    step "mix salad.install"
    mix salad.install --yes --prefix DemoWeb.UI
    USE_LINE="use DemoWeb.UI"
    ;;
  *) fail "unknown mode: $MODE" ;;
esac

step "assert patched files"
grep -q 'SaladUI: SaladUI.SaladUIHook' assets/js/app.js || fail "hook not registered in app.js"
[ "$(grep -c '@import "tailwindcss"' assets/css/app.css)" = 1 ] || fail "tailwindcss imported more than once"
[ "$(grep -c '@custom-variant dark' assets/css/app.css)" = 1 ] || fail "duplicate dark variant"
grep -q 'border-border' assets/css/app.css || fail "base border rule missing"
grep -q 'hsl(var(' assets/css/app.css && fail "hsl() wrapping oklch tokens (invalid CSS)"

step "re-run is idempotent"
cp assets/css/app.css /tmp/app.css.before
cp assets/js/app.js /tmp/app.js.before
if [ "$MODE" = setup ]; then mix salad.setup --yes; else mix salad.install --yes --prefix DemoWeb.UI; fi
cmp -s assets/css/app.css /tmp/app.css.before || fail "app.css changed on re-run"
cmp -s assets/js/app.js /tmp/app.js.before || fail "app.js changed on re-run"

step "compile (warnings as errors)"
mix compile --warnings-as-errors

step "build assets"
mix assets.build
grep -q 'SaladUIHook' priv/static/assets/js/app.js || fail "SaladUI hook missing from JS bundle"
grep -q 'bg-primary' priv/static/assets/css/app.css || fail "SaladUI classes missing from CSS bundle"

step "mount components in a LiveView"
mkdir -p test/demo_web
sed "s/__USE_SALAD__/$USE_LINE/" "$HERE/salad_smoke_test.exs" > test/demo_web/salad_smoke_test.exs
mix test test/demo_web/salad_smoke_test.exs

echo; echo "OK: installer e2e ($MODE)"
