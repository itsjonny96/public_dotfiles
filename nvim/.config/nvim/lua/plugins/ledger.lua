return {
  "ledger/vim-ledger",
  ft = { "ledger", "journal" },
  init = function()
    -- Associate .journal files with the ledger filetype
    vim.filetype.add({
      extension = {
        journal = "ledger",
      },
    })
  end,
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "ledger",
      callback = function()
        vim.opt_local.foldmethod = "syntax"
        vim.opt_local.foldlevel = 0
      end,
    })
  end,
}
