# dotfiles

Personal workstation configuration (WSL2 / Ubuntu / zsh).

## Layout

```
dotfiles/
├── .zshrc                  # zsh config  → symlinked to ~/.zshrc
├── .zshrc.secrets.example  # template for API keys (real file is git-ignored)
├── nvim/
│   ├── init.lua            # Neovim config → symlinked to ~/.config/nvim/init.lua
│   └── lazy-lock.json      # pinned plugin versions → ~/.config/nvim/lazy-lock.json
└── README.md
```

Everything is tracked here and **symlinked** into place, so edits to the repo
are live immediately and the machine stays reproducible.

## What's configured

- **zsh**: Oh My Zsh + Zinit (turbo-loaded), spaceship prompt, modern CLI tools
  (`fzf`, `zoxide`, `atuin`, `eza`, `bat`, `fd`), secrets sourced from an
  untracked `~/.zshrc.secrets`.
- **Neovim**: lazy.nvim + telescope + treesitter + catppuccin + which-key,
  tuned as a learning-friendly daily driver (relative line numbers, `jk`→Esc,
  `<Space>` leader, highlight-on-yank).

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
```

Secrets (`~/.zshrc.secrets`) are **never** committed — see `.gitignore`.
