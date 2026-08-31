#!/usr/bin/env bash
# Machine setup, one step at a time.
#
# This script is deliberately NOT a black box. Every step prints WHAT it is
# about to do and WHY before doing it, and each step can be run on its own so
# you can stop, look around, and understand the result before moving on.
#
#   ./omarchy/bootstrap.sh --list            # the steps, in order
#   ./omarchy/bootstrap.sh pkgs              # run one step
#   ./omarchy/bootstrap.sh links mise        # run several
#   ./omarchy/bootstrap.sh all               # run everything, in order
#   ./omarchy/bootstrap.sh --dry-run all     # print every command, change NOTHING
#   ./omarchy/bootstrap.sh doctor            # read-only: what drifted?
#
# Everything is idempotent: re-running a step that is already done is a no-op.
#
# This is the Omarchy counterpart of macos/bootstrap.sh and follows the same
# shape on purpose. It is much shorter, and that is the point: Omarchy arrives
# already configured, so this adds a personal layer rather than building a
# machine from nothing. Where the two differ, the step explains why.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=false

# Guard on Omarchy, not on Linux. Plain Arch would survive most of this, but the
# links and ssh steps assume Omarchy's config layout and its systemd user
# session — and the WSL box is Linux too, where running this would be wrong.
if [[ ! -r /etc/os-release ]] || ! grep -q '^ID=omarchy$' /etc/os-release; then
  echo "This script is for the Omarchy machine. Use macos/bootstrap.sh on the Mac." >&2
  exit 1
fi

STEPS=(pkgs links secrets ssh mise git doctor)

# --- output helpers ---------------------------------------------------------
bold()    { printf '\n\033[1;35m━━ %s\033[0m\n' "$*"; }
explain() { printf '\033[2m%s\033[0m\n' "$*"; }
skip()    { printf '   \033[2m· %s\033[0m\n' "$*"; }
ok()      { printf '   \033[32m✓\033[0m %s\n' "$*"; }
warn()    { printf '   \033[33m!\033[0m %s\n' "$*"; }
bad()     { printf '   \033[31m✗\033[0m %s\n' "$*"; }
# ok() for something that only just happened — silent in a dry run, where it
# did not.
ok_done() { $DRY_RUN || ok "$*"; }

# Echo a command, then run it — unless --dry-run, in which case only echo.
# Everything that MUTATES the machine goes through this, so --dry-run is a
# faithful preview. Read-only probes are called directly.
run() {
  printf '   \033[36m$\033[0m %s\n' "$*"
  $DRY_RUN || "$@"
}
# Same, for anything needing a pipe, redirect or shell expansion.
run_sh() {
  printf '   \033[36m$\033[0m %s\n' "$1"
  $DRY_RUN || eval "$1"
}

# Symlink $1 → $2, moving any real file already there out of the way first.
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    skip "$dst already points at the repo"
    return
  fi
  [[ -d "$(dirname "$dst")" ]] || run mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    run mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
  fi
  run ln -sfn "$src" "$dst"
}

# Read a declarative list, minus comments and blank lines.
list() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$1"
}

# ===========================================================================
step_pkgs() {
  bold "1/7  Arch packages"
  explain "Installs everything in omarchy/packages.txt with pacman. That file IS
the inventory of this machine — if you install something by hand later, add it
there and commit, or the next machine won't have it.

--needed makes this a no-op for what is already installed, which is most of the
list: Omarchy ships eza, bat, fd, ripgrep, fzf, zoxide, jq, lazygit, tmux and
starship as dependencies of its own packages. Naming them here anyway promotes
them to *explicitly installed*, so they survive a
\`pacman -Rns \$(pacman -Qdtq)\` orphan sweep and show up in \`pacman -Qeq\`.

This is the ONLY step that needs root, and the only one that needs a real
terminal window — sudo reads the password from a tty. sudo rather than pkexec
because a terminal is where a password prompt belongs, and because this session
runs polkitd but no polkit authentication agent to draw a dialog with anyway."

  # sudo reads the password from a terminal, and this is the only step that
  # needs one. Said plainly here because sudo's own message ("a terminal is
  # required to read the password") does not tell you WHICH context you are
  # missing a terminal in — and the two that bite are an agent's shell and a
  # `!`-prefixed command inside one, both of which look like a terminal from
  # where you typed them. pkexec is not the answer either: polkitd runs, but
  # this session starts no polkit authentication agent to draw a dialog with.
  if ! $DRY_RUN && [[ ! -t 0 ]] && ! sudo -n true 2>/dev/null; then
    bad "no terminal here to read the sudo password on"
    explain "   Run this one step from a real terminal window:
       ./omarchy/bootstrap.sh pkgs
   Every other step needs no root and runs anywhere."
    return 1
  fi

  local pkgs=()
  mapfile -t pkgs < <(list "$DOTFILES/omarchy/packages.txt")
  run sudo pacman -S --needed "${pkgs[@]}"
}

# ===========================================================================
step_links() {
  bold "2/7  Dotfile symlinks"
  explain "Each config in the repo is symlinked to where the app expects it, so
editing the repo is live and 'git pull' is the whole update process. Any real
file already at the destination is renamed to <file>.bak.<timestamp> first —
nothing is destroyed.

Note what is NOT here. ~/.config/nvim stays Omarchy's LazyVim, ~/.config/mise/
stays mise's own, and the shell is bash with Omarchy's rc chain: where Omarchy
already ships something, the repo extends it instead of replacing it. The only
shared file this machine takes from the repo root is .ideavimrc, which is
IDE-side and has no Omarchy equivalent.

The Hyprland .lua files are safe to own: Omarchy loads its own defaults from
/usr/share/omarchy/default/hypr/ BEFORE reading these, so they are override
files by design, and tracking them cannot stop 'omarchy update' from improving
the defaults underneath.

One hazard worth knowing about, because it is silent. Omarchy's update
migrations edit user configs, and most do it in a symlink-preserving way
('cp' onto the path, or 'cat > file'). But some use 'sed -i' — and GNU sed -i
writes a temp file and renames it over the target, which REPLACES the symlink
with a regular file. The known targets are the terminal configs
(ghostty/foot/alacritty/kitty). If that happens, this machine silently detaches
from the repo and keeps working, which is the worst kind of failure. The
'doctor' step exists to catch exactly this; re-running 'links' repairs it."

  link "$DOTFILES/omarchy/bashrc"            "$HOME/.bashrc"
  link "$DOTFILES/.ideavimrc"                "$HOME/.ideavimrc"

  local f
  for f in hyprland bindings input looknfeel monitors autostart; do
    link "$DOTFILES/omarchy/hypr/$f.lua"     "$HOME/.config/hypr/$f.lua"
  done

  link "$DOTFILES/omarchy/ghostty/config"    "$HOME/.config/ghostty/config"
  link "$DOTFILES/omarchy/shell.json"        "$HOME/.config/omarchy/shell.json"

  echo
  explain "Hyprland reloads its config on save, but validate anyway:
     hyprctl reload && hyprctl configerrors
   Ghostty:  omarchy restart terminal
   The bar:  shell.json hot-reloads on save.
   bash:     open a new terminal (or 'source ~/.bashrc')."
}

# ===========================================================================
step_secrets() {
  bold "3/7  Secrets"
  explain "~/.bashrc.secrets holds the API keys. It is git-ignored and sourced by
omarchy/bashrc. Copy the real one from another machine, or fill this template in.

The template is .zshrc.secrets.example, shared with the other two machines: it is
only 'export' lines, so it is shell-agnostic. Only the destination is named for
the shell that sources it."

  if [[ -f "$HOME/.bashrc.secrets" ]]; then
    skip "~/.bashrc.secrets exists — not overwriting"
    return
  fi
  run cp "$DOTFILES/.zshrc.secrets.example" "$HOME/.bashrc.secrets"
  run chmod 600 "$HOME/.bashrc.secrets"
  ok_done "created ~/.bashrc.secrets — fill in the real keys"
}

# ===========================================================================
step_ssh() {
  bold "4/7  SSH agent"
  explain "Omarchy sets up no SSH agent at all — this is the one place where it
ships nothing rather than something to extend. Without an agent,
~/.ssh/config's 'AddKeysToAgent yes' has nowhere to add the key, and you retype
the passphrase on every single push.

Three machines, three agent stories — and this one is closest to the Mac's:

  WSL      'keychain' keeps one ssh-agent alive across shells and you type the
           passphrase once per boot, in the first terminal. .zshrc drives it.
  macOS    launchd owns the agent; AddKeysToAgent + UseKeychain load the key on
           first use and read the passphrase from the login Keychain.
  Omarchy  systemd's user session owns it, via the ssh-agent.socket unit Arch
           ships. Same shape as the Mac: no shell involvement at all. It is also
           the only option that reaches GUI programs — uwsm imports
           ~/.config/environment.d/, so an editor launched from a Hyprland
           keybinding gets SSH_AUTH_SOCK too, which a shell rc could never do.

Not gnome-keyring: it runs here, but with --components=pkcs11,secrets. Its ssh
component is gone in current versions, replaced by a separate gcr-ssh-agent, and
there is no reason to prefer it over the plain agent.

This writes ~/.ssh/config only if there is none, and never generates keys."

  run systemctl --user enable --now ssh-agent.socket

  local envd="$HOME/.config/environment.d"
  local envfile="$envd/ssh_auth_sock.conf"
  if [[ -f "$envfile" ]]; then
    skip "$envfile exists"
  else
    [[ -d "$envd" ]] || run mkdir -p "$envd"
    run_sh "printf 'SSH_AUTH_SOCK=\${XDG_RUNTIME_DIR}/ssh-agent.socket\n' > '$envfile'"
    ok_done "wrote $envfile — read at the next login"
  fi

  [[ -d "$HOME/.ssh" ]] || run mkdir -p "$HOME/.ssh"
  run chmod 700 "$HOME/.ssh"

  if [[ -f "$HOME/.ssh/config" ]]; then
    skip "~/.ssh/config exists — not touching it"
  else
    run_sh "cat > '$HOME/.ssh/config' <<'SSHEOF'
Host *
    AddKeysToAgent yes
    IdentitiesOnly yes

# Personal machine: one identity.
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/nunes.lfa
SSHEOF"
    run chmod 600 "$HOME/.ssh/config"
  fi

  echo
  explain "Copy the key FILE over from another machine — this never generates one.
Then:
     chmod 600 ~/.ssh/nunes.lfa
     ssh -T git@github.com          # AddKeysToAgent loads it, asks once
The passphrase prompt lands on this terminal. No askpass helper is set, which is
deliberate: ssh started from a GUI app should fail visibly rather than hang
behind an unpainted dialog."
}

# ===========================================================================
step_mise() {
  bold "5/7  mise tools"
  explain "mise is Omarchy's version manager: it comes from Omarchy's own package
repo, its bash init activates it, and the 'mup' alias updates through it. This
machine uses it for everything — unlike the Mac and the WSL box, which pin
language runtimes with asdf. Running both here would put two sets of shims on
PATH racing over the same 'node', and this machine already gave up shell
uniformity, so there is nothing left for that trade to buy.

Each line of omarchy/mise-tools.txt is applied with 'mise use --global'. The
repo declares the intent; mise owns ~/.config/mise/config.toml, because it
rewrites that file itself — symlinking a config its own tool rewrites is the
same quiet fight as the sed -i one described in the 'links' step. Same division
as packages.txt, which declares intent and lets pacman own its database."

  if ! command -v mise >/dev/null 2>&1; then
    bad "mise not on PATH — run the 'pkgs' step first"
    $DRY_RUN || return 1
    return 0
  fi

  local tool
  while read -r tool; do
    run mise use --global "$tool"
  done < <(list "$DOTFILES/omarchy/mise-tools.txt")

  run mise install
}

# ===========================================================================
step_git() {
  bold "6/7  git"
  explain "Omarchy already ships a good global config — and, unusually, ships it
at ~/.config/git/config rather than ~/.gitconfig. That matters: git reads the
XDG path only when ~/.gitconfig does NOT exist, so 'git config --global' here
edits Omarchy's file rather than shadowing it. Your name and email are already
in it, set by the installer, along with rerere, histogram diffs and
push.autoSetupRemote — all worth keeping.

Three settings still need changing or adding:

  init.defaultBranch   — Omarchy ships 'master'; every machine here uses 'main'.
  core.autocrlf=false  — 'input' was a Windows-era setting. The checkout is
                         already LF, so no translation is wanted.
  fetch.prune=true     — delete local refs whose remote branch is gone.

No core.excludesfile: the .DS_Store problem is the Mac's, and there is no Linux
equivalent worth a global ignore file."

  run git config --global init.defaultBranch main
  run git config --global core.autocrlf false
  run git config --global fetch.prune true
}

# ===========================================================================
step_doctor() {
  bold "7/7  doctor"
  explain "Reads only, changes nothing. It exists because every link on this
machine can be silently broken by something that is not you — an 'omarchy
update' migration that runs sed -i over a terminal config, a reinstall that
re-seeds /etc/skel, an app that rewrites its own config file. Run it after every
'omarchy update'."
  echo

  local issues=0

  # --- symlinks ---
  local pairs=(
    "$HOME/.bashrc|$DOTFILES/omarchy/bashrc"
    "$HOME/.ideavimrc|$DOTFILES/.ideavimrc"
    "$HOME/.config/ghostty/config|$DOTFILES/omarchy/ghostty/config"
    "$HOME/.config/omarchy/shell.json|$DOTFILES/omarchy/shell.json"
  )
  local f
  for f in hyprland bindings input looknfeel monitors autostart; do
    pairs+=("$HOME/.config/hypr/$f.lua|$DOTFILES/omarchy/hypr/$f.lua")
  done

  printf '   \033[1mLinks\033[0m\n'
  local pair dst src
  for pair in "${pairs[@]}"; do
    dst="${pair%%|*}"; src="${pair##*|}"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      ok "${dst/#$HOME/\~}"
    elif [[ -e "$dst" ]]; then
      bad "${dst/#$HOME/\~} is a real file, not a link into the repo"
      issues=$(( issues + 1 ))
    else
      bad "${dst/#$HOME/\~} is missing"
      issues=$(( issues + 1 ))
    fi
  done

  # --- shell ---
  echo; printf '   \033[1mShell\033[0m\n'
  local current
  current="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "$current" == */bash ]]; then
    ok "login shell is $current"
  else
    bad "login shell is $current — this machine is set up for bash"
    issues=$(( issues + 1 ))
  fi
  if [[ -n "${OMARCHY_PATH:-}" ]]; then
    ok "OMARCHY_PATH=$OMARCHY_PATH"
  else
    bad "OMARCHY_PATH unset — Omarchy's env-bootstrap did not run"
    issues=$(( issues + 1 ))
  fi
  # omarchy/bashrc opens with a COPY of Omarchy's stock preamble, and a copy
  # drifts. /etc/skel/.bashrc is the upstream original and is package-owned, so
  # pacman replaces it on update — which makes it the right thing to compare
  # against. Compare only the executable lines: upstream rewording a comment is
  # not a problem, upstream adding a `source` line is.
  local skel="/etc/skel/.bashrc" stale=0 codeline
  if [[ -r $skel ]]; then
    while IFS= read -r codeline; do
      if ! grep -qxF "$codeline" "$HOME/.bashrc" 2>/dev/null; then
        bad "~/.bashrc is missing a line Omarchy's stock .bashrc has:"
        printf '       %s\n' "$codeline"
        stale=$(( stale + 1 ))
      fi
    done < <(grep -vE '^[[:space:]]*(#|$)' "$skel")
    if (( stale )); then
      issues=$(( issues + 1 ))
      explain "   Omarchy changed its stock preamble. Copy the missing line into
   omarchy/bashrc, above the personal layer, and commit."
    else
      ok "~/.bashrc carries Omarchy's stock preamble in full"
    fi
  else
    warn "$skel unreadable — cannot check the preamble for drift"
  fi

  # --- secrets ---
  # The 'secrets' step seeds this file from a template, and a template that is
  # never filled in is worse than no file: omarchy/bashrc exports it into every
  # interactive shell, and claude and codex run here through mise. An invalid
  # ANTHROPIC_API_KEY overrides subscription auth and fails somewhere that points
  # nowhere near a dotfile. Self-clearing: filling it in or removing it both make
  # this go quiet.
  echo; printf '   \033[1mSecrets\033[0m\n'
  local secrets="$HOME/.bashrc.secrets"
  if [[ ! -f $secrets ]]; then
    skip "no ~/.bashrc.secrets — omarchy/bashrc sources it only when present"
  elif grep -q REPLACE_ME "$secrets"; then
    bad "~/.bashrc.secrets still holds template placeholders"
    explain "   Fill in the real keys, or rm the file."
    issues=$(( issues + 1 ))
  else
    ok "~/.bashrc.secrets has no leftover placeholders"
  fi

  # --- packages ---
  echo; printf '   \033[1mPackages\033[0m\n'
  local missing=() p
  while read -r p; do
    pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
  done < <(list "$DOTFILES/omarchy/packages.txt")
  if (( ${#missing[@]} )); then
    bad "not installed: ${missing[*]}"
    issues=$(( issues + 1 ))
  else
    ok "every package in packages.txt is installed"
  fi

  # --- ssh ---
  echo; printf '   \033[1mSSH\033[0m\n'
  if systemctl --user is-enabled ssh-agent.socket >/dev/null 2>&1; then
    ok "ssh-agent.socket enabled"
  else
    bad "ssh-agent.socket not enabled"
    issues=$(( issues + 1 ))
  fi
  if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
    ok "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
  else
    warn "SSH_AUTH_SOCK unset here (environment.d is read at login)"
  fi

  # --- mise ---
  echo; printf '   \033[1mmise\033[0m\n'
  if command -v mise >/dev/null 2>&1; then
    local installed absent=() tool
    installed="$(mise ls --installed 2>/dev/null | awk '{print $1}')"
    while read -r tool; do
      grep -qx "${tool%%@*}" <<<"$installed" || absent+=("$tool")
    done < <(list "$DOTFILES/omarchy/mise-tools.txt")
    if (( ${#absent[@]} )); then
      bad "declared but not installed: ${absent[*]}"
      issues=$(( issues + 1 ))
    else
      ok "every tool in mise-tools.txt is installed"
    fi
    # asdf here would mean two shim directories fighting over the same runtime.
    if command -v asdf >/dev/null 2>&1; then
      warn "asdf is also installed — this machine is meant to use mise alone"
    fi
  else
    bad "mise not on PATH"
    issues=$(( issues + 1 ))
  fi

  echo
  if (( issues )); then
    printf '   \033[31m%d problem(s).\033[0m Most are repaired by re-running the step that owns them:\n' "$issues"
    printf '     ./omarchy/bootstrap.sh pkgs links mise\n'
  else
    printf '   \033[32mEverything matches the repo.\033[0m\n'
  fi
}

# ===========================================================================
#  Driver
# ===========================================================================
usage() {
  cat <<EOF
Usage: ./omarchy/bootstrap.sh [--dry-run] <step>... | all
       ./omarchy/bootstrap.sh --list

Steps, in order:
   1. pkgs      everything in omarchy/packages.txt (pacman)
   2. links     symlink the repo's configs into place
   3. secrets   create ~/.bashrc.secrets from the template
   4. ssh       systemd ssh-agent + ~/.ssh/config (never generates keys)
   5. mise      apply omarchy/mise-tools.txt
   6. git       global git settings
   7. doctor    read-only: what drifted from the repo?

This machine keeps Omarchy's own bash, LazyVim and mise; the repo extends them
rather than replacing them. See omarchy/README.md.
EOF
}

ARGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --list|-l|--help|-h) usage; exit 0 ;;
    *) ARGS+=("$arg") ;;
  esac
done

[[ ${#ARGS[@]} -gt 0 ]] || { usage; exit 0; }

if [[ "${ARGS[0]}" == "all" ]]; then
  ARGS=("${STEPS[@]}")
fi

for want in "${ARGS[@]}"; do
  # shellcheck disable=SC2076
  if [[ ! " ${STEPS[*]} " =~ " ${want} " ]]; then
    echo "Unknown step: $want" >&2
    usage >&2
    exit 1
  fi
done

$DRY_RUN && printf '\n\033[1;33m*** DRY RUN — nothing will be modified ***\033[0m\n'

for want in "${ARGS[@]}"; do
  "step_${want}"
done

bold "Done"
cat <<'EOF'
Steps that are NOT scripted, on purpose — they need your eyes:

  1. Open a new terminal, or `source ~/.bashrc`. The SSH_AUTH_SOCK from
     ~/.config/environment.d/ needs a full logout, not just a new shell.

  2. Copy ~/.ssh/nunes.lfa over from another machine, chmod 600 it, then
     `ssh -T git@github.com` once to load it into the agent.

  3. hyprctl reload && hyprctl configerrors — the repo's Hyprland files are now
     live; this is how you find a typo before it bites at the next login.

  4. First `nvim` after installing packages compiles the treesitter parsers.
     Give it a minute, then `:checkhealth`.
EOF
