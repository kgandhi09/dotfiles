# Setup fzf
# ---------
if [[ ! "$PATH" == */home/gandhi/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/gandhi/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/gandhi/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/gandhi/.fzf/shell/key-bindings.zsh"
