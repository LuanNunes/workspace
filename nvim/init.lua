-- =====================================================================
--  Neovim config  —  learning-friendly daily driver
--  Tip: <leader> is the SPACE bar. Press it and wait — which-key shows
--       you every mapping that follows. That's your live cheat-sheet.
-- =====================================================================

vim.g.mapleader = " "        -- space = leader (set BEFORE plugins load)
vim.g.maplocalleader = " "

-- ---------------------------------------------------------------------
--  Options  (the ones that actually help you learn)
-- ---------------------------------------------------------------------
local o = vim.opt

-- Line numbers: relative + absolute. THE learning aid — the number next
-- to a line is exactly the count for a motion: "5j" jumps to line 5 below,
-- "d3k" deletes 3 lines up. You'll start "seeing" motions.
o.number = true
o.relativenumber = true

o.mouse = "a"                -- mouse works too (safety net while learning)
o.clipboard = "unnamedplus"  -- share the system clipboard (see note below*)
o.cursorline = true          -- highlight the line you're on
o.termguicolors = true       -- full colors for the theme
o.signcolumn = "yes"         -- stable left gutter (no text jumping)
o.scrolloff = 8              -- keep 8 lines visible above/below cursor

-- Searching
o.ignorecase = true          -- case-insensitive...
o.smartcase = true           -- ...unless you type a capital letter
o.hlsearch = true            -- highlight matches (clear with <leader>nh)
o.incsearch = true           -- jump to matches as you type

-- Indentation (your original settings)
o.expandtab = true
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2

-- Splits open where you expect
o.splitright = true
o.splitbelow = true

-- Persistent undo — undo even after closing a file
o.undofile = true

-- Clipboard no WSL: usamos X410, então WAYLAND_DISPLAY fica unset e o
-- wl-clipboard não serve. O win32yank v0.1.1 falha com erro 53 nesta máquina,
-- então a ponte é o clip.exe/PowerShell — o método documentado pelo Neovim.
if vim.fn.has("wsl") == 1 then
  local ps_paste = 'powershell.exe -NoProfile -Command '
    .. '[Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
  vim.g.clipboard = {
    name = "WslClipboard",
    copy  = { ["+"] = "clip.exe",  ["*"] = "clip.exe" },
    paste = { ["+"] = ps_paste,    ["*"] = ps_paste },
    cache_enabled = 0,
  }
end

-- ---------------------------------------------------------------------
--  A couple of quality-of-life keymaps
-- ---------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>nh", ":nohlsearch<CR>", { desc = "clear search highlight" })
-- 'jk' to leave insert mode without reaching for Esc (try it!)
map("i", "jk", "<Esc>", { desc = "exit insert mode" })

-- ---------------------------------------------------------------------
--  Plugins (lazy.nvim)
-- ---------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  -- sem tag: a versão exata vive em lazy-lock.json (`:Lazy update` para subir)
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  -- which-key: press a prefix (like <leader>) and it shows what comes next.
  -- The best learning plugin there is — makes the whole config discoverable.
  { "folke/which-key.nvim", event = "VeryLazy" },
}
require("lazy").setup(plugins, {})

-- ---------------------------------------------------------------------
--  Plugin setup
-- ---------------------------------------------------------------------
require("catppuccin").setup()
vim.cmd.colorscheme("catppuccin")

require("which-key").setup({})

require("telescope").setup({
  defaults = { hidden = true, file_ignore_patterns = {} },
  pickers = { find_files = { hidden = true } },
})

local builtin = require("telescope.builtin")
map("n", "<C-p>",       builtin.find_files, { desc = "find files" })
map("n", "<leader>ff",  builtin.find_files, { desc = "find files" })
map("n", "<leader>fg",  builtin.live_grep,  { desc = "grep in project" })
map("n", "<leader>fb",  builtin.buffers,    { desc = "open buffers" })
map("n", "<leader>fh",  builtin.help_tags,  { desc = "search help" })
-- <leader>fk = browse ALL keybindings. Forgot a mapping? Look it up here.
map("n", "<leader>fk",  builtin.keymaps,    { desc = "search keymaps" })

require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript",
                       "tsx", "json", "bash", "markdown", "markdown_inline" },
  highlight = { enable = true },
  indent = { enable = true },
})

-- Flash what you just yanked — satisfying feedback that copy worked.
vim.api.nvim_create_autocmd("TextYankPost", {
  -- vim.hl desde o Neovim 0.11 (vim.highlight está deprecado, sai no 0.13)
  callback = function() (vim.hl or vim.highlight).on_yank({ timeout = 200 }) end,
})

-- * system clipboard note: on WSL this needs a bridge (win32yank/wl-clipboard).
--   If yanking to Windows doesn't work, install win32yank — ask and I'll help.
