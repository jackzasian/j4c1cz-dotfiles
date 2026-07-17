# Clash proxy for all shells (Cursor agent runs non-interactive bash)
[[ -f ~/.config/omarchy/proxy.sh ]] && source ~/.config/omarchy/proxy.sh

# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/jackz/.lmstudio/bin"
# End of LM Studio CLI section

export PATH="$HOME/bin:$PATH"
