# Powerlevel10k instant prompt (must stay near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export EDITOR="nvim"
export PSQL_PAGER='pspg -bX --no-mouse'
export BAT_THEME="Catppuccin Mocha"

# Homebrew (macOS)
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Powerlevel10k theme
if [[ -f /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
elif [[ -f ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme
fi

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

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Machine-specific overrides — create ~/.zshrc.local for local additions (not tracked)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
