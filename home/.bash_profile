#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Added by LM Studio CLI (lms)
case ":$PATH:" in
    *":$HOME/.lmstudio/bin:"*) ;;
    *) export PATH="$PATH:$HOME/.lmstudio/bin" ;;
esac
# End of LM Studio CLI section

