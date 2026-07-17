# ============================================================================
#  Environment
# ============================================================================
unset WAYLAND_DISPLAY

# WSL display / GL
export DISPLAY=0.0.0.0:0
export LIBGL_ALWAYS_INDIRECT=1

# Locale
export LANG=en_US.UTF-8
export LANGUAGE="en_US:en"
export LC_ALL="en_US.UTF-8"

# App/tooling env
export ANTHROPIC_MODEL=claude-opus-4-8
export AI_ASSISTANT_ENABLED=true

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
ZSH_THEME="spaceship"

# Syntax highlighting & autosuggestions are loaded via Zinit (below);
# asdf is sourced manually (below) — so they are intentionally NOT listed here.
plugins=(git brew dotnet)

source "$ZSH/oh-my-zsh.sh"

# ============================================================================
#  Spaceship prompt
# ============================================================================
SPACESHIP_PROMPT_ORDER=(
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  dotnet
  java
  node
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)
SPACESHIP_PROMPT_ASYNC=false
SPACESHIP_USER_COLOR="#5f00d7"
SPACESHIP_USER_SHOW=always
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "

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

# Turbo mode: load after the prompt appears (faster startup).
zinit wait lucid light-mode for \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-autosuggestions

# ============================================================================
#  Language / version managers
# ============================================================================
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
. "$HOME/.asdf/plugins/java/set-java-home.zsh"
. "$HOME/.asdf/plugins/golang/set-env.zsh"

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
  alias ll="eza -lah --group-directories-first --icons"
  alias la="eza -a  --group-directories-first"
  alias lt="eza --tree --level=2"
fi

# bat (modern cat)
command -v bat &>/dev/null && alias cat="bat --paging=never"

# ============================================================================
#  Startup commands
# ============================================================================
command -v setxkbmap &>/dev/null && setxkbmap -layout us -variant intl 2>/dev/null
command -v keychain  &>/dev/null && eval "$(keychain --quiet --eval --agents ssh ~/.ssh/nunes@domo)"

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

# Zsh config
alias zshconfig="nano ~/.zshrc"
alias zshreload="source ~/.zshrc"

# Domo
alias domo-admin="cd /home/nunes/projects/domo/admin-console && ./initDatabase.sh rig && ./runLocal.sh rig"
alias tug="tug-eks"
alias tug-feature="tug set feature -f forms; tug set feature -f workflows; tug set feature -f code-engine-v2; tug set feature -f hopper; tug set feature -f data-app; tug set feature -f forms-widget; tug set feature -f wf_person; tug set feature -f forms-singleton; tug set feature -f domo-wide; tug set feature -f wf_group; tug set feature -f wf_accounts; tug set feature -f wf_templates; tug set feature -f wf-tasks-identifiers; tug set feature -f ce-run-with-defined-object; tug set feature -f ce-example-tab; tug set feature -f wf-form-starts-v2; tug set feature -f forms-question-rail; tug set feature -f gp-admin; tug set feature -f workflow-start-widget; tug set feature -f embed-card-public; tug set feature -f embed-card-view; tug set feature -f embed-card; tug set feature -f private-embed-v2; tug set feature -f story-embed-v2; tug set feature -f story-embed-export; tug set feature -f relational-appdb;"
