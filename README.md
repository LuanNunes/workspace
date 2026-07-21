# dotfiles

Personal workstation configuration (WSL2 / Ubuntu / zsh).

## Layout

```
dotfiles/
├── .zshrc                  # zsh config  → symlinked to ~/.zshrc
├── .p10k.zsh               # Powerlevel10k prompt → symlinked to ~/.p10k.zsh
├── .zshrc.secrets.example  # template for API keys (real file is git-ignored)
├── .ideavimrc              # IdeaVim config → symlinked to ~/.ideavimrc (all JetBrains IDEs)
├── nvim/
│   ├── init.lua            # Neovim config → symlinked to ~/.config/nvim/init.lua
│   └── lazy-lock.json      # pinned plugin versions → ~/.config/nvim/lazy-lock.json
├── windows/                # SNAPSHOTS of the Windows side (see note below)
│   ├── sync.sh             # copies these files to/from Windows
│   ├── powershell/         # PowerShell profile (prompt, PSReadLine, aliases)
│   ├── oh-my-posh/         # oh-my-posh prompt theme (Tokyo Night)
│   ├── windows-terminal/   # Windows Terminal settings (scheme, font, keys)
│   └── vscode/             # VS Code settings
├── vim-cheatsheet.md       # Vim grammar + all our <leader> mappings (PT-BR)
└── README.md
```

Everything under WSL is tracked here and **symlinked** into place, so edits to
the repo are live immediately and the machine stays reproducible.

> **Windows note:** everything under `windows/` is a **snapshot**, not a symlink.
> Those files live on NTFS, the apps that own them rewrite the file wholesale
> when you edit through their UI, and Windows won't follow a symlink into the
> WSL filesystem. Keep them in sync with:
>
> ```sh
> ./windows/sync.sh pull    # Windows → repo   (before committing)
> ./windows/sync.sh push    # repo → Windows   (after cloning or pulling)
> ./windows/sync.sh diff    # show what drifted
> ```

## What's configured

- **zsh**: Oh My Zsh + Zinit (turbo-loaded), Powerlevel10k prompt (rainbow style,
  recoloured to Tokyo Night — see `.p10k.zsh`), `fastfetch` banner on startup,
  modern CLI tools
  (`fzf`, `zoxide`, `atuin`, `eza`, `bat`, `fd`), secrets sourced from an
  untracked `~/.zshrc.secrets`.
  Inline suggestions (PSReadLine style) come from `zsh-autosuggestions`:
  <kbd>→</kbd>/<kbd>End</kbd> accepts the whole suggestion, <kbd>Ctrl</kbd>+<kbd>→</kbd>
  one word at a time. <kbd>Ctrl</kbd>+<kbd>R</kbd> and <kbd>↑</kbd> belong to `atuin`.
- **Neovim**: lazy.nvim + telescope + treesitter + catppuccin + which-key,
  tuned as a learning-friendly daily driver (relative line numbers, `jk`→Esc,
  `<Space>` leader, highlight-on-yank).
- **JetBrains (IdeaVim)**: one shared `~/.ideavimrc` for all IDEs (IntelliJ,
  WebStorm, PyCharm, Rider, DataGrip, Studio). Mirrors the Neovim leader keys
  and maps `<Space>`-prefixed shortcuts to IDE actions (find/navigate/refactor/run).
  Requires the **IdeaVim** plugin per IDE: *Settings → Plugins → Marketplace →
  "IdeaVim" → Install → Restart*. Optional extras (uncomment in `.ideavimrc`
  after installing from Marketplace): **Which-Key**, **IdeaVim-EasyMotion** (+AceJump),
  **IdeaVim-Sneak**.
- **VS Code (vscodevim)**: same `<Space>` leader and `jk`→Esc, relative line
  numbers, EasyMotion + surround enabled, `<leader>` mapped to VS Code commands
  (find/navigate/refactor). Extension `vscodevim.vim` installed on the Windows side.
- **Windows host** (`windows/`): PowerShell profile with an oh-my-posh prompt,
  PSReadLine in `ListView` prediction mode, and the same aliases as zsh
  (`ls`/`ll`/`lt` via eza, git shortcuts, `z`, `fzf`). Same one-line powerline
  prompt as zsh, but **deliberately distinct**: PowerShell runs *Kanagawa* +
  *JetBrainsMono NF*, WSL runs *Tokyo Night* + *UbuntuSansMono NF*, so a glance
  tells you which shell you're in. Both are set per profile in Windows Terminal
  (the defaults stay on the WSL look); oh-my-posh, PSReadLine and fzf follow the
  PowerShell palette.

## Setup on a new machine

```sh
git clone git@github.com:LuanNunes/workspace.git ~/projects/resolve-programming/workspace
export DOTFILES=~/projects/resolve-programming/workspace   # adjust if cloned elsewhere
```

### 1. Packages (all in the Ubuntu repos)

```sh
sudo nala install -y zsh neovim fzf zoxide atuin eza bat fd-find unzip keychain \
                     locales ripgrep build-essential fastfetch
sudo locale-gen en_US.UTF-8
```

- `ripgrep` is **required** by telescope's `live_grep` (`<leader>fg`).
- `build-essential` is **required** by treesitter to compile parsers (`:TSUpdate`).
- Debian renames two binaries — `.zshrc` looks for the upstream names, so link them:
  ```sh
  mkdir -p ~/.local/bin
  ln -sf "$(command -v batcat)" ~/.local/bin/bat
  ln -sf "$(command -v fdfind)" ~/.local/bin/fd
  ```

### 2. zsh

```sh
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
cp "$DOTFILES/.zshrc.secrets.example" ~/.zshrc.secrets
chmod 600 ~/.zshrc.secrets      # then fill in real keys

# Oh My Zsh — Zinit bootstraps itself, and pulls Powerlevel10k, on first start
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

chsh -s "$(command -v zsh)"     # make zsh the login shell (takes effect next session)
```

```sh
ln -sf "$DOTFILES/.p10k.zsh" ~/.p10k.zsh
```

> The Oh My Zsh installer overwrites `~/.zshrc` — re-run the `ln -sf` above if it does.

The prompt needs a **Nerd Font** in the terminal (this setup uses
*UbuntuSansMono NF*) and a truecolor terminal, since `.p10k.zsh` uses Tokyo Night
hex colors. To start over from the wizard instead: `p10k configure`.

### 3. asdf

asdf 0.16+ is a **Go binary**, not a sourced shell script (`asdf.sh` no longer
exists). Install the release binary into `/usr/local/bin`, then generate completions:

```sh
mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf"
```

`.zshrc` only puts `$ASDF_DATA_DIR/shims` on the PATH — see
<https://asdf-vm.com/guide/getting-started.html>.

### 4. Neovim

```sh
mkdir -p ~/.config/nvim
ln -sf "$DOTFILES/nvim/init.lua"       ~/.config/nvim/init.lua
ln -sf "$DOTFILES/nvim/lazy-lock.json" ~/.config/nvim/lazy-lock.json
```

Clipboard: `clipboard=unnamedplus` needs a bridge. This machine uses **X410**
(see below), so `WAYLAND_DISPLAY` is unset and `wl-clipboard` is not an option.
`win32yank` v0.1.1 exits with error 53 here (tested from both the Linux and the
Windows filesystem), so `init.lua` configures `vim.g.clipboard` to use
`clip.exe` + PowerShell `Get-Clipboard` instead — no extra install needed, both
already ship with Windows.

### 5. JetBrains (IdeaVim)

```sh
ln -sf "$DOTFILES/.ideavimrc" ~/.ideavimrc
```

Then install the **IdeaVim** plugin in each IDE.

### Display (X410)

`.zshrc` points `DISPLAY` at X410 on Windows. WSL2 runs in **NAT** mode here, so
the host IP changes on every boot and `DISPLAY` is derived from the default
route rather than hardcoded. On the Windows side: enable **"Allow Public
Access"** in X410 and allow the *vEthernet (WSL)* adapter through the firewall,
otherwise the connection is refused.

Secrets (`~/.zshrc.secrets`) are **never** committed — see `.gitignore`.
