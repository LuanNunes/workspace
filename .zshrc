# ============================================================================
#  SSH agent
# ============================================================================
# Loads the passphrase-protected key into a persistent agent (keychain reuses
# one agent across shells, so only the first shell after a boot prompts). This
# MUST run before the instant-prompt block below: it reads the passphrase from
# the terminal, and p10k's instant prompt would otherwise contend for the tty
# and swallow the prompt. SSH_ASKPASS_REQUIRE=never forces the prompt onto this
# terminal instead of a graphical askpass helper — without it the exported
# DISPLAY makes ssh-add reach for an askpass program that isn't installed, and
# it fails with "Problem adding; giving up". Guarded to a real interactive tty
# so non-interactive shells (scp, `zsh -c`, VS Code tasks) never block on it.
if [[ -o interactive && -t 1 ]] && command -v keychain &>/dev/null; then
  eval "$(SSH_ASKPASS_REQUIRE=never keychain --quiet --eval --agents ssh ~/.ssh/nunes.lfa)"
fi

# ============================================================================
#  Powerlevel10k instant prompt
# ============================================================================
# Instant prompt draws a cached prompt at the top, then homes the cursor and
# clears to end of screen (\e[J) once the real prompt is ready — which wipes the
# fastfetch banner printed during startup. We want BOTH: the banner on the first
# interactive shell of each boot, and the fast instant prompt on every shell
# after. So gate it on a marker (created by the banner block below): while the
# marker is absent (first shell) instant prompt stays OFF so the banner
# survives; once it exists (later shells, no banner) instant prompt is ON.
# The marker lives in XDG_RUNTIME_DIR (tmpfs, wiped on reboot), so the banner
# comes back on the first shell after each restart.
# Nothing below here may print to stdout or read from stdin — the only thing
# allowed above is the SSH agent block, which owns the tty for its passphrase
# prompt before instant prompt starts.
_p9k_banner_marker="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/fastfetch-shown"
if [[ -e "$_p9k_banner_marker" ]]; then
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
else
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
fi

# ============================================================================
#  Environment
# ============================================================================
# WSL display / GL — X410 on Windows as the X server.
# WSL2 in MIRRORED networking mode shares the Windows host's network stack, so
# the host (and X410) is reachable over loopback — DISPLAY is a fixed
# 0.0.0.0:0. This replaced the old NAT-mode derivation from the default route:
# in mirrored mode that route's gateway is the real LAN router (e.g.
# 192.168.50.1), not the Windows host, so the derived DISPLAY pointed at nothing
# and every GUI app (IDEs, etc.) died with "Can't connect to X11 window server".
# On Windows: X410 with "Allow Public Access", or the connection is refused.
unset WAYLAND_DISPLAY
export DISPLAY=0.0.0.0:0
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
# asdf: support both generations. Classic (<=0.15) ships ~/.asdf/asdf.sh, which
# defines the `asdf` FUNCTION, the PATH (bin + shims) and completions — without
# sourcing it, plugin hooks like java's set-java-home fail with
# "command not found: asdf". 0.16+ is a Go binary with no asdf.sh, so the shims
# on PATH are enough.  https://asdf-vm.com/guide/getting-started.html
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
  . "$HOME/.asdf/asdf.sh"                       # asdf classic (<=0.15)
else
  export PATH="$ASDF_DATA_DIR/shims:$PATH"      # asdf 0.16+ (Go binary)
fi

# Completions — compinit tem de vir DEPOIS do Oh My Zsh (que é sourceado acima).
# Gerar uma vez com:
#   mkdir -p "$ASDF_DATA_DIR/completions" && asdf completion zsh > "$ASDF_DATA_DIR/completions/_asdf"
fpath=("$ASDF_DATA_DIR/completions" $fpath)
autoload -Uz compinit && compinit

# Interactive completion menu: Tab highlights an entry; a second Tab enters
# "menu selection" so you can move with the arrow keys and Enter to pick.
zstyle ':completion:*' menu select
zmodload zsh/complist                    # provides the `menuselect` keymap
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history

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

# Smarter cd: `z <partial>` jumps to frecent dirs, `zi` picks from a fzf list.
# Zinit aliases zi (and zpl/zplg/zini) to itself, and an alias wins over a
# function — so zi would run the plugin manager instead of zoxide. Drop it;
# `zinit` still works under its own name.
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  unalias zi 2>/dev/null
fi

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
# Backgrounded (&!): setxkbmap talks to the X server, so if X410 is down it
# would block the whole startup (and delay the banner below) until the X
# connection times out. Detach it — the layout still applies once X is up.
# (SSH key loading lives in the SSH agent block at the top of this file.)
command -v setxkbmap &>/dev/null && setxkbmap -layout us -variant intl 2>/dev/null &!

# System banner, only for a real interactive terminal (skips VS Code tasks,
# `zsh -c`, scp/rsync sessions and anything else without a tty), and only on the
# first such shell per boot — new tabs/panes/ssh sessions after it stay clean.
# Dropping the marker also flips the instant-prompt block at the top ON for every
# later shell (see there). The marker is in tmpfs, so it resets on reboot.
if [[ -o interactive && -t 1 ]] && command -v fastfetch &>/dev/null; then
  if [[ ! -e "$_p9k_banner_marker" ]]; then
    fastfetch
    : > "$_p9k_banner_marker"
  fi
fi
unset _p9k_banner_marker

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
