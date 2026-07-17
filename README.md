# dotfiles

Personal shell configuration.

## Layout
- `.zshrc` — main zsh config (symlinked to `~/.zshrc`).
- `.zshrc.secrets.example` — template for API keys; real values live in
  `~/.zshrc.secrets` (git-ignored, `chmod 600`).

## Setup on a new machine
```sh
git clone <this-repo> ~/dotfiles
ln -sf ~/dotfiles/.zshrc ~/.zshrc
cp ~/dotfiles/.zshrc.secrets.example ~/.zshrc.secrets
chmod 600 ~/.zshrc.secrets   # then edit in your real keys
```
