vim.g.mapleader = ","
vim.g.maplocalleader = "\\"
-- Bootstrap lazy.nvim (auto-installs if not present)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup("plugins", {
  change_detection = {
    notify = false,
  },
})

-- Search highlighting customization
vim.api.nvim_set_hl(0, 'Search', {
  fg = '#f5c2e7',  -- Bright pink for all matches
  bg = 'NONE',
  bold = true,
})

vim.api.nvim_set_hl(0, 'IncSearch', {
  fg = '#cba6f7',  -- Mauve for current match
  bg = 'NONE',
  bold = true,
  underline = true,
})

-- Map Option+Backspace to delete word backward in insert mode
vim.keymap.set('i', '<M-BS>', '<C-w>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>dd', function()
  vim.cmd('r !date +\\%m.\\%d.\\%Y')
end, { noremap = true, silent = true, desc = 'Insert date only' })


vim.opt.number = true          -- Show line numbers
vim.opt.expandtab = true       -- Use spaces instead of tabs
vim.opt.shiftwidth = 4         -- Indent width
vim.opt.tabstop = 4            -- Tab width
vim.opt.relativenumber = true 
vim.opt.timeoutlen = 700
vim.opt.conceallevel = 2

-- Jinja2 filetype detection
vim.filetype.add({
  pattern = {
    [".*%.sql%.j2"] = "jinja.sql",
    [".*%.j2"] = "jinja",
  },
})
