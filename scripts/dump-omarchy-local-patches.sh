#!/usr/bin/env bash
# Capture uncommitted local edits inside ~/.local/share/omarchy (the upstream
# basecamp/omarchy checkout) as a durable, diffable artifact in this repo.
# ~/.local/share/omarchy is stock/upstream-tracked — it must NOT be edited
# directly, but it currently has local Clash-proxy/AUR-routing patches that
# aren't backed up anywhere. This dumps them as a diff + copied untracked
# files + manifest, so they can be reviewed/reapplied/upstreamed later
# without leaving the "never edit" tree dirty across an `omarchy update`.
set -euo pipefail

OMARCHY_SRC="${HOME}/.local/share/omarchy"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATE_DIR="$(date +%F)"
OUT="${ROOT}/patches/omarchy-local/${DATE_DIR}"

if [[ ! -d "${OMARCHY_SRC}/.git" ]]; then
  echo "ERROR: ${OMARCHY_SRC} is not a git checkout" >&2
  exit 1
fi

mkdir -p "$OUT"

cd "$OMARCHY_SRC"
BASE_COMMIT="$(git rev-parse HEAD)"
BASE_DESC="$(git log -1 --format='%h %s')"

MODIFIED=$(git diff --name-only)
UNTRACKED=$(git status --porcelain=v1 | awk '/^\?\?/ {print $2}')

if [[ -z "$MODIFIED" && -z "$UNTRACKED" ]]; then
  echo "No local modifications in ${OMARCHY_SRC} — nothing to dump."
  rmdir "$OUT" 2>/dev/null || true
  exit 0
fi

git diff > "${OUT}/tracked-modifications.diff"

if [[ -n "$UNTRACKED" ]]; then
  mkdir -p "${OUT}/untracked"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    dest="${OUT}/untracked/${f}"
    mkdir -p "$(dirname "$dest")"
    cp -a "$OMARCHY_SRC/$f" "$dest"
  done <<<"$UNTRACKED"
fi

{
  echo "Base commit: ${BASE_COMMIT}"
  echo "Base commit desc: ${BASE_DESC}"
  echo "Dumped: $(date -Iseconds)"
  echo
  echo "Modified (tracked-modifications.diff):"
  [[ -n "$MODIFIED" ]] && echo "$MODIFIED" | sed 's/^/  - /' || echo "  (none)"
  echo
  echo "Untracked (copied verbatim under untracked/):"
  [[ -n "$UNTRACKED" ]] && echo "$UNTRACKED" | sed 's/^/  - /' || echo "  (none)"
  echo
  echo "To reapply against a fresh checkout at the same base commit:"
  echo "  cd ~/.local/share/omarchy && git checkout ${BASE_COMMIT} && git apply --3way ${OUT}/tracked-modifications.diff"
  echo "  cp -a ${OUT}/untracked/. ~/.local/share/omarchy/"
} > "${OUT}/MANIFEST.txt"

echo "Dumped local omarchy patches to ${OUT}"
echo "Review, then: git -C ${ROOT} add patches/omarchy-local/${DATE_DIR} && git -C ${ROOT} commit -m 'Omarchy local patches ${DATE_DIR}' && git -C ${ROOT} push"
