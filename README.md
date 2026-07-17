# dotfiles

Personal workstation configuration (WSL2 / Ubuntu / zsh).

## Layout

```
dotfiles/
├── .zshrc                  # zsh config  → symlinked to ~/.zshrc
├── .zshrc.secrets.example  # template for API keys (real file is git-ignored)
├── .ideavimrc              # IdeaVim config → symlinked to ~/.ideavimrc (all JetBrains IDEs)
├── nvim/
│   ├── init.lua            # Neovim config → symlinked to ~/.config/nvim/init.lua
│   └── lazy-lock.json      # pinned plugin versions → ~/.config/nvim/lazy-lock.json
├── vscode/
│   └── settings.json       # SNAPSHOT of VS Code settings (see note below)
├── vim-cheatsheet.md       # Vim grammar + all our <leader> mappings (PT-BR)
└── README.md
```

> **VS Code note:** VS Code runs on Windows (installed via Scoop, portable mode),
> so its real config lives at
> `C:\Users\nunes\scoop\apps\vscode\current\data\user-data\User\settings.json`.
> That's on the Windows filesystem and **can't be symlinked** from WSL, so
> `vscode/settings.json` here is a **manual snapshot** — copy it over after edits,
> or use VS Code's built-in *Settings Sync* for live syncing.

Everything is tracked here and **symlinked** into place, so edits to the repo
are live immediately and the machine stays reproducible.

## What's configured

- **zsh**: Oh My Zsh + Zinit (turbo-loaded), spaceship prompt, modern CLI tools
  (`fzf`, `zoxide`, `atuin`, `eza`, `bat`, `fd`), secrets sourced from an
  untracked `~/.zshrc.secrets`.
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

## Setup on a new machine

```sh
git clone git@github-luan:LuanNunes/workspace.git ~/dotfiles

# zsh
ln -sf ~/dotfiles/.zshrc ~/.zshrc
cp ~/dotfiles/.zshrc.secrets.example ~/.zshrc.secrets
chmod 600 ~/.zshrc.secrets      # then fill in real keys

# neovim
mkdir -p ~/.config/nvim
ln -sf ~/dotfiles/nvim/init.lua       ~/.config/nvim/init.lua
ln -sf ~/dotfiles/nvim/lazy-lock.json ~/.config/nvim/lazy-lock.json

# jetbrains (IdeaVim) — then install the "IdeaVim" plugin in each IDE
ln -sf ~/dotfiles/.ideavimrc ~/.ideavimrc
```

Secrets (`~/.zshrc.secrets`) are **never** committed — see `.gitignore`.
