# Clash proxy for all shells (Cursor agent runs non-interactive bash)
[[ -f ~/.config/omarchy/proxy.sh ]] && source ~/.config/omarchy/proxy.sh

# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# /etc/omarchy.conf is written by omarchy-dev-link. When absent, force the
# package default instead of preserving a stale inherited dev-link value before
# we decide which rc file to source.
if [[ -f /etc/omarchy.conf ]]; then
  source /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
else
  export OMARCHY_PATH=/usr/share/omarchy
fi
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# The Vercel CLI cannot handle Clash's ALL_PROXY=socks5://... and dies on every
# API call with "TypeError: fetch failed". Route it through noproxy so plain
# `vercel ...` just works. A function, not an alias: mise's node bin comes
# before ~/.local/bin on PATH, so a wrapper script there would be shadowed.
# No recursion — `noproxy` execs via `env`, which does a fresh PATH lookup and
# finds the real binary, not this function.
vercel() {
  noproxy vercel "$@"
}

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/jackz/.lmstudio/bin"
# End of LM Studio CLI section

export PATH="$HOME/bin:$PATH"
