# ============================================================================
#  Powerlevel10k instant prompt
# ============================================================================
# Draws the prompt from a cache before the rest of this file runs, so the shell
# feels instant. MUST stay at the very top, and nothing above it may print to
# stdout or read from stdin — that would corrupt the cached frame.
# `quiet` because the fastfetch banner below deliberately prints during startup;
# p10k buffers it and replays it above the prompt instead of warning about it.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
#  Environment
# ============================================================================
# WSL display / GL — X410 no Windows como servidor X.
# WSL2 em modo NAT: o IP do host muda a cada boot, então DISPLAY é derivado da
# rota default em vez de fixo. No Windows: X410 com "Allow Public Access" e a
# vEthernet (WSL) liberada no firewall, senão a conexão é recusada.
unset WAYLAND_DISPLAY
export DISPLAY="$(ip route show default | awk '{print $3; exit}'):0"
export LIBGL_ALWAYS_INDIRECT=1

# Locale
export LANG=en_US.UTF-8
export LANGUAGE="en_US:en"
export LC_ALL="en_US.UTF-8"

# App/tooling env
export ANTHROPIC_MODEL=claude-opus-4-8
export AI_ASSISTANT_ENABLED=true

# Default editor: Neovim (used by git commits, `kubectl edit`, etc.)
export EDITOR="nvim"
export VISUAL="nvim"

# Secrets (API keys) — kept out of this file, see ~/.zshrc.secrets (chmod 600)
[[ -f "$HOME/.zshrc.secrets" ]] && source "$HOME/.zshrc.secrets"

# ============================================================================
#  PATH
# ============================================================================
export BREW_HOME="/home/linuxbrew/.linuxbrew/bin"
export PATH="$PATH:$BREW_HOME:$HOME/bin:$HOME/.local/bin:$HOME/.dotnet/tools"

# Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# ============================================================================
#  Oh My Zsh
# ============================================================================
export ZSH="$HOME/.oh-my-zsh"
# Prompt comes from Powerlevel10k, loaded via Zinit below — leave OMZ's theme
# empty so it doesn't install a prompt of its own.
ZSH_THEME=""

# Syntax highlighting & autosuggestions are loaded via Zinit (below);
# asdf is sourced manually (below) — so they are intentionally NOT listed here.
plugins=(git brew dotnet)

source "$ZSH/oh-my-zsh.sh"

# ============================================================================
#  Zinit (plugin manager)
# ============================================================================
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Annexes (required for annexes; loaded without Turbo)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# Prompt — loaded eagerly (no Turbo): the prompt is the first thing drawn, and
# deferring it would defeat the instant-prompt cache at the top of this file.
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Inline suggestion (the PSReadLine InlineView equivalent): greys out the rest of
# the command ahead of the cursor. Set before the plugin loads below.
#   → / End   accept the whole suggestion
#   Ctrl-→    accept one word
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'   # Tokyo Night comment grey
ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # history first, then completions
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20             # don't suggest on huge buffers

# Turbo mode: load after the prompt appears (faster startup).
zinit wait lucid light-mode for \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-autosuggestions

# ============================================================================
#  Language / version managers
# ============================================================================
# asdf v0.16+ é um binário Go: não existe mais asdf.sh para dar source, só os
# shims no PATH.  https://asdf-vm.com/guide/getting-started.html
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
export PATH="$ASDF_DATA_DIR/shims:$PATH"

# Completions — compinit tem de vir DEPOIS do Oh My Zsh (que é sourceado acima).
# Gerar uma vez com:
#   mkdir -p "$ASDF_DATA_DIR/completions" && asdf completion zsh > "$ASDF_DATA_DIR/completions/_asdf"
fpath=("$ASDF_DATA_DIR/completions" $fpath)
autoload -Uz compinit && compinit

# Hooks de plugin — só existem depois de `asdf plugin add java` / `golang`.
[[ -f "$ASDF_DATA_DIR/plugins/java/set-java-home.zsh" ]] && . "$ASDF_DATA_DIR/plugins/java/set-java-home.zsh"
[[ -f "$ASDF_DATA_DIR/plugins/golang/set-env.zsh" ]]    && . "$ASDF_DATA_DIR/plugins/golang/set-env.zsh"

# ============================================================================
#  Key bindings
# ============================================================================
# Word-wise movement isn't bound out of the box; Ctrl-←/→ is what the terminal
# sends, and forward-word doubles as "accept one word of the inline suggestion".
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ============================================================================
#  Modern CLI tools
# ============================================================================
# Fuzzy finder (Ctrl-T files, Alt-C cd, Ctrl-R history unless atuin owns it)
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
fi

# Smarter cd: `z <partial>` jumps to frecent dirs
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Better shell history (owns Ctrl-R when present)
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# eza (modern ls) aliases
if command -v eza &>/dev/null; then
  alias ls="eza --group-directories-first --icons"
  alias ll="eza -lah --group-directories-first --icons"
  alias la="eza -a  --group-directories-first --icons"
  alias lt="eza --tree --level=2 --icons"
fi

# bat (modern cat)
command -v bat &>/dev/null && alias cat="bat --paging=never"

# ============================================================================
#  Startup commands
# ============================================================================
command -v setxkbmap &>/dev/null && setxkbmap -layout us -variant intl 2>/dev/null
command -v keychain  &>/dev/null && eval "$(keychain --quiet --eval --agents ssh ~/.ssh/nunes.lfa)"

# System banner, only for a real interactive terminal (skips VS Code tasks,
# `zsh -c`, scp/rsync sessions and anything else without a tty).
if [[ -o interactive && -t 1 ]] && command -v fastfetch &>/dev/null; then
  fastfetch
fi

# ============================================================================
#  Aliases
# ============================================================================
# JetBrains IDEs (launch detached)
alias idea="/opt/idea/bin/idea </dev/null &>/dev/null &"
alias webstorm="/opt/webstorm/bin/webstorm </dev/null &>/dev/null &"
alias pycharm="/opt/pycharm/bin/pycharm </dev/null &>/dev/null &"
alias rider="/opt/rider/bin/rider </dev/null &>/dev/null &"
alias datagrip="/opt/datagrip/bin/datagrip </dev/null &>/dev/null &"
alias android="/opt/android-studio/bin/studio </dev/null &>/dev/null &"

# Apps
alias firefox="firefox-dev >/tmp/firefox-dev.log 2>&1 & disown"
alias dcu="docker compose up"
alias dcd="docker compose down"

# Editor — route muscle memory to Neovim
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# Zsh config
alias zshconfig="nvim ~/.zshrc"
alias zshreload="source ~/.zshrc"

# Domo
alias domo-admin="cd /home/nunes/projects/domo/admin-console && ./initDatabase.sh rig && ./runLocal.sh rig"
alias tug="tug-eks"
alias tug-feature="tug set feature -f forms; tug set feature -f workflows; tug set feature -f code-engine-v2; tug set feature -f hopper; tug set feature -f data-app; tug set feature -f forms-widget; tug set feature -f wf_person; tug set feature -f forms-singleton; tug set feature -f domo-wide; tug set feature -f wf_group; tug set feature -f wf_accounts; tug set feature -f wf_templates; tug set feature -f wf-tasks-identifiers; tug set feature -f ce-run-with-defined-object; tug set feature -f ce-example-tab; tug set feature -f wf-form-starts-v2; tug set feature -f forms-question-rail; tug set feature -f gp-admin; tug set feature -f workflow-start-widget; tug set feature -f embed-card-public; tug set feature -f embed-card-view; tug set feature -f embed-card; tug set feature -f private-embed-v2; tug set feature -f story-embed-v2; tug set feature -f story-embed-export; tug set feature -f relational-appdb;"

# ============================================================================
#  Powerlevel10k config
# ============================================================================
# Generated from the official "rainbow" template, recoloured to Tokyo Night.
# Symlinked to ~/.p10k.zsh; run `p10k configure` to regenerate from scratch.
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
