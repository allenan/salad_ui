#!/usr/bin/env bash
# Builds priv/static/assets/salad_ui.css and typeset.css with the Tailwind CLI
# and checks that every utility SaladUI ships (scroll-fade, shimmer, scrollbar,
# typeset) is emitted. Catches a utility that was dropped, renamed or no longer
# compiles under the pinned Tailwind version.
#
# Usage: .github/scripts/css-utilities.sh
#   TAILWIND=/path/to/tailwindcss overrides the binary. By default it uses the
#   one `mix assets.setup` installed for the storybook app.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
VERSION=$(awk '/^config :tailwind/ { t = 1 } t && /version:/ { gsub(/[^0-9.]/, ""); print; exit }' "$ROOT/storybook/config/config.exs")
BIN=${TAILWIND:-$(find "$ROOT/storybook/_build" -maxdepth 1 -name "tailwind-*-$VERSION" | head -1)}
[ -x "$BIN" ] || { echo "FAIL: tailwind $VERSION not found; run 'mix assets.setup' in storybook/ or set TAILWIND" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

CLASSES=(
  scrollbar-none no-scrollbar
  scroll-fade scroll-fade-y scroll-fade-x
  scroll-fade-t scroll-fade-b scroll-fade-l scroll-fade-r scroll-fade-s scroll-fade-e
  scroll-fade-none md:scroll-fade-none
  scroll-fade-24 "scroll-fade-[15%]"
  scroll-fade-t-2 scroll-fade-b-8 scroll-fade-s-4 scroll-fade-e-6 "scroll-fade-t-[10px]"
  data-wrap:scroll-fade-y
  shimmer shimmer-once shimmer-reverse shimmer-none shimmer-duration-1000 shimmer-spread-8 shimmer-angle-45
)

cat > "$WORK/input.css" <<EOF
@import "tailwindcss" source(none);
@import "$ROOT/priv/static/assets/salad_ui.css";
@import "$ROOT/priv/static/assets/typeset.css";
@source inline("${CLASSES[*]}");
EOF

"$BIN" --input="$WORK/input.css" --output="$WORK/out.css" >/dev/null 2>&1 ||
  { "$BIN" --input="$WORK/input.css" --output="$WORK/out.css"; exit 1; }

failed=0
expect() {
  if ! grep -qF -- "$1" "$WORK/out.css"; then
    echo "FAIL: built CSS is missing: $1" >&2
    failed=1
  fi
}

# Every class, as Tailwind escapes it in a selector.
for class in "${CLASSES[@]}"; do
  selector=$(printf '%s' "$class" | sed -e 's/:/\\:/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/%/\\%/g')
  expect ".$selector"
done

# The scroll-driven reveal, its registered properties and RTL mirroring.
for edge in t b s e; do
  expect "@property --scroll-fade-$edge"
  expect "@keyframes scroll-fade-reveal-$edge"
done
expect "@property --scroll-fade-mask"
expect "animation-timeline: scroll(self y), scroll(self y)"
expect "animation-timeline: scroll(self inline), scroll(self inline)"
expect "animation-timeline: scroll(self x)"
expect '[dir="rtl"]'
expect "--scroll-fade-size: calc(var(--spacing) * 24)"
expect "--scroll-fade-size: 15%"
expect "--scroll-fade-t-size: 10px"
expect "--scroll-fade-mask: none"

# typeset.css: the container, the opt-out and the scroll wrapper.
expect ".typeset {"
expect "--typeset-flow: 1.25em"
expect ".not-typeset"
expect ".typeset-scroll"

[ "$failed" = 0 ] || exit 1
echo "OK: ${#CLASSES[@]} utilities and typeset.css present in the built CSS (tailwind $VERSION)"
