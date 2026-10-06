# Partagé entre NixOS (PC) et macOS (MacBook) : les chemins sont essayés dans l'ordre
# via _src (le premier qui existe gagne), le reste est séparé par $OSTYPE plus bas.

# ── homebrew (macOS) ─────────────────────────────────────────
# avant le reste : met /opt/homebrew/bin dans le PATH (zoxide, direnv…)
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# ── history ──────────────────────────────────────────────────
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# ── input & completion ───────────────────────────────────────
bindkey -v
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit
compinit

# ── path ─────────────────────────────────────────────────────
export PATH="$HOME/nixos-config/scripts:$PATH"
export PATH="$PATH:$HOME/.local/bin"

# ── ssh agent (gcr/gnome-keyring, Linux uniquement) ──────────
# sur macOS, surtout ne pas toucher : SSH_AUTH_SOCK vient de launchd (agent du trousseau)
[[ $OSTYPE == linux* ]] && export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"

# ── tmux autostart (disabled) ────────────────────────────────
# if command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
#   tmux attach 2>/dev/null || tmux new-session
# fi

# ── helpers ──────────────────────────────────────────────────
_src() { local f; for f in "$@"; do [[ -r $f ]] && { source "$f"; return 0; }; done; return 1 }

# ── tools & plugins ──────────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
# prompt : dots/starship/.config/starship.toml
command -v starship &>/dev/null && eval "$(starship init zsh)"

_src /usr/share/fzf/completion.zsh   /run/current-system/sw/share/fzf/completion.zsh   /opt/homebrew/opt/fzf/shell/completion.zsh
_src /usr/share/fzf/key-bindings.zsh /run/current-system/sw/share/fzf/key-bindings.zsh /opt/homebrew/opt/fzf/shell/key-bindings.zsh

_src \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /run/current-system/sw/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

_src \
  /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh \
  /run/current-system/sw/share/zsh-history-substring-search/zsh-history-substring-search.zsh \
  /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# zsh-syntax-highlighting must be sourced last
_src \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /run/current-system/sw/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── ls colors ────────────────────────────────────────────────
if command -v dircolors &>/dev/null; then
  # Linux : matugen-themed overrides on top of stock defaults
  eval "$(dircolors -b)"
  _src ~/.cache/dircolors/theme-matugen
else
  # macOS : ls BSD, pas de dircolors
  export CLICOLOR=1
fi

# ── nixos / macos ────────────────────────────────────────────
if [[ $OSTYPE == linux* ]]; then
  # ATTENTION : supprime TOUTES les anciennes générations NixOS (plus de rollback possible).
  # Nom explicite exprès (l'original s'appelait juste "clean", trop discret pour ce que ça fait),
  # + confirmation avant de lancer.
  alias nix-purge-old-generations="echo 'Ceci va supprimer TOUTES les anciennes générations NixOS (plus de retour en arrière possible). Ctrl+C pour annuler, Entrée pour continuer.' && read -r && sudo nix-collect-garbage -d && sudo nixos-rebuild boot --flake $HOME/nixos-config/nixos#nixos"
  alias nixconf="nvim $HOME/nixos-config/nixos"
  alias rebuild="sudo nixos-rebuild switch --flake $HOME/nixos-config/nixos#nixos |& nom"
  alias search="nix search nixpkgs"
  alias upgrade="nix flake update --flake $HOME/nixos-config/nixos && rebuild"
  alias emu="EMULATOR_GPU=host $HOME/nixos-config/scripts/android-avd.sh start"
  alias zed="zeditor"
  # hp pavilion trackpad reset
  alias trackpad="sudo modprobe -r psmouse && sudo modprobe psmouse"
else
  # équivalent de `rebuild` : installe ce qui manque du Brewfile
  alias rebuild="brew bundle --file $HOME/nixos-config/mac/Brewfile"
  alias upgrade="brew update && brew upgrade"
  alias search="brew search"
fi
alias dots="cd $HOME/nixos-config"

# ── general QoL ──────────────────────────────────────────────
alias catall="find . -type f -exec tail -n +1 {} + | nvim"
alias ff="fastfetch"
alias p="python3"
alias py="python"
alias tmux_kill="rm -rf ~/.local/share/tmux/resurrect && tmux kill-server"
alias q="exit"
alias wq="exit"
alias weather="curl wttr.in"
alias y="yazi"

# ── git QoL ──────────────────────────────────────────────────
alias ga="git add ."
alias gc="git add . && git commit -m"
alias gp="git push --set-upstream origin HEAD"
alias gs="git status"

# Resend CLI
export PATH="$HOME/.resend/bin:$PATH"
