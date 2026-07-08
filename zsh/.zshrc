export EDITOR="nvim"
export PSQL_PAGER='pspg -bX --no-mouse'
export BAT_THEME="Catppuccin Mocha"

# Homebrew (macOS)
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Dotfiles
[[ -f ~/dotfiles/zsh/greeting.zsh ]]  && source ~/dotfiles/zsh/greeting.zsh
[[ -f ~/dotfiles/zsh/functions.zsh ]] && source ~/dotfiles/zsh/functions.zsh
[[ -f ~/dotfiles/zsh/aliases.zsh ]]   && source ~/dotfiles/zsh/aliases.zsh
[[ -f ~/dotfiles/zsh/local.zsh ]]     && source ~/dotfiles/zsh/local.zsh

# Vi keybindings
bindkey -v
bindkey '^W' backward-kill-word

# fzf
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
  bindkey -M viins '\e\x7f' backward-kill-word
fi

# Starship prompt
eval "$(starship init zsh)"

# colorls tab completion
if command -v colorls &>/dev/null; then
  source "$(dirname "$(gem which colorls)")/tab_complete.sh"
fi

# carapace completions
if command -v carapace &>/dev/null; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  zstyle ':completion:*' format $'\e[3;37mCompleting %d\e[m'
  source <(carapace _carapace)
fi

autoload -U compinit && compinit

# Machine-specific overrides — create ~/.zshrc.local for local additions (not tracked)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
