#!/usr/bin/env bash
# Detects squash commits on the parity integration branch that silently
# reverted earlier work: a commit whose tree is closest to an ancestor other
# than its parent was squashed against the wrong base, and reverted every
# commit in between. Exit 1 if any are found.
# Usage: .github/scripts/parity-audit.sh [ref] [depth]
set -uo pipefail
REF="${1:-origin/parity/integration}"
DEPTH="${2:-60}"
# Already-repaired bad squashes (9b34b26 -> c01934d, 856a69d -> 029e138).
IGNORE="${PARITY_AUDIT_IGNORE:-9b34b26 856a69d}"
chain=(); while read -r l; do chain+=("$l"); done < <(git rev-list --first-parent "$REF" | head -"$DEPTH")
bad=0
for i in "${!chain[@]}"; do
  B=${chain[$i]}; s=$(git log -1 --format=%s "$B")
  case " $IGNORE " in *" ${B:0:7} "*) continue;; esac
  case "$s" in feat\(parity/*|fix\(parity/*) ;; *) continue;; esac
  parent=${chain[$((i+1))]:-}; [ -z "$parent" ] && continue
  best="$parent"; bestn=$(git diff --name-only "$parent" "$B" | wc -l)
  for j in $(seq $((i+2)) $((i+12))); do
    A=${chain[$j]:-}; [ -z "$A" ] && break
    n=$(git diff --name-only "$A" "$B" | wc -l)
    if [ "$n" -lt "$bestn" ]; then bestn=$n; best=$A; fi
  done
  if [ "$best" != "$parent" ]; then
    bad=1
    echo "BAD ${B:0:7} $s: squashed against ${best:0:7}, reverting $(git log --format=%h "${best}..${parent}" | tr '\n' ' ')"
  fi
done
[ "$bad" = 0 ] && echo "parity-audit: no bad squashes"
exit $bad
