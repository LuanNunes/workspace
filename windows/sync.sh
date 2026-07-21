#!/usr/bin/env bash
# Sync the Windows-side config between this repo and the Windows filesystem.
#
#   ./windows/sync.sh pull    Windows  → repo   (run before committing)
#   ./windows/sync.sh push    repo     → Windows (run after cloning or pulling)
#   ./windows/sync.sh diff    show what differs, change nothing
#
# These files can't be symlinked: they live on NTFS, the apps that own them
# rewrite the file wholesale when you edit through their UI, and Windows won't
# follow a symlink into the WSL filesystem. So the repo keeps a snapshot and
# this script copies it back and forth.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# %USERPROFILE% as a WSL path. cmd.exe is run from /mnt/c so it doesn't warn
# about the current directory being a UNC path.
win_home() {
  local p
  p="$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" || true
  if [[ -n "${p:-}" ]]; then wslpath -u "$p"; else echo "/mnt/c/Users/$USER"; fi
}

WIN="$(win_home)"
WT_STATE="$WIN/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"

# A portable install (Scoop) keeps settings under the install dir; a regular
# user install keeps them in %APPDATA%. This machine uses the latter — VS Code
# lives in AppData\Local\Programs — so that is the fallback.
VSCODE_USER="$WIN/scoop/apps/vscode/current/data/user-data/User"
[[ -d $VSCODE_USER ]] || VSCODE_USER="$WIN/AppData/Roaming/Code/User"

# Neovim on Windows reads %LOCALAPPDATA%\nvim. The init.lua is shared with WSL
# as-is — the only platform-specific part of it is the clipboard bridge, which
# is already guarded by `if vim.fn.has("wsl")`.
NVIM_USER="$WIN/AppData/Local/nvim"

# repo path (relative to the repo root) : path on the Windows side
PAIRS=(
  "nvim/init.lua:$NVIM_USER/init.lua"
  "nvim/lazy-lock.json:$NVIM_USER/lazy-lock.json"
  "windows/powershell/Microsoft.PowerShell_profile.ps1:$WIN/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
  "windows/oh-my-posh/theme.omp.json:$WIN/.config/oh-my-posh/theme.omp.json"
  "windows/vscode/settings.json:$VSCODE_USER/settings.json"
  # NB: o Windows Terminal NÃO entra aqui. Seu settings.json é por máquina
  # (profiles/GUIDs diferentes), então ./windows/windows-terminal/apply-theme.py
  # MESCLA o tema no arquivo real em vez de copiá-lo por cima.
)

usage() { sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 1; }

action="${1:-}"
[[ $action == pull || $action == push || $action == diff ]] || usage

for pair in "${PAIRS[@]}"; do
  rel="${pair%%:*}"
  win="${pair#*:}"
  repo="$REPO/$rel"

  case $action in
    pull)
      if [[ -f $win ]]; then
        mkdir -p "$(dirname "$repo")"
        cp "$win" "$repo"
        echo "pulled  $rel"
      else
        echo "missing $win — skipped" >&2
      fi
      ;;
    push)
      if [[ -f $repo ]]; then
        if [[ -d $(dirname "$win") ]]; then
          cp "$repo" "$win"
          echo "pushed  $rel"
        else
          echo "missing $(dirname "$win") — app not installed? skipped" >&2
        fi
      fi
      ;;
    diff)
      if [[ -f $repo && -f $win ]]; then
        if diff -q "$repo" "$win" >/dev/null; then
          echo "same    $rel"
        else
          echo "DIFFERS $rel"
          diff -u "$repo" "$win" || true
        fi
      else
        echo "missing $rel or its Windows counterpart" >&2
      fi
      ;;
  esac
done
