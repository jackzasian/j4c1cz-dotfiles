#!/bin/bash
# Apply custom Omarchy Plymouth theme (Arch j4c1cz logo). Requires sudo.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/share/plymouth/themes/omarchy"

"${HOME}/.config/omarchy/branding/generate-arch-j4c1cz.sh"
"${DIR}/render-logo.sh"

install_theme() {
  local cp_cmd=(cp)
  [[ ${EUID:-0} -ne 0 ]] && cp_cmd=(sudo cp)

  "${cp_cmd[@]}" "${DIR}/bullet.png" "${DIR}/entry.png" "${DIR}/lock.png" \
    "${DIR}/logo.png" "${DIR}/omarchy.plymouth" "${DIR}/omarchy.script" \
    "${DIR}/progress_bar.png" "${DIR}/progress_box.png" "$DEST/"

  if [[ -d "${DIR}/logos" ]]; then
    "${cp_cmd[@]}" -r "${DIR}/logos" "$DEST/"
  fi

  if [[ ${EUID:-0} -ne 0 ]]; then
    sudo plymouth-set-default-theme omarchy
    if command -v limine-mkinitcpio &>/dev/null; then
      sudo limine-mkinitcpio
    else
      sudo mkinitcpio -P
    fi
  else
    plymouth-set-default-theme omarchy
    if command -v limine-mkinitcpio &>/dev/null; then
      limine-mkinitcpio
    else
      mkinitcpio -P
    fi
  fi
}

install_theme
echo "Plymouth theme applied. Reboot to see the boot splash."
