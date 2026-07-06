return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = "VeryLazy",
  config = function()
    local langs = { "bash", "css", "html", "javascript", "json", "lua", "markdown", "markdown_inline", "python", "sql", "typescript", "yaml" }
    local installed = require("nvim-treesitter.config").get_installed()
    local to_install = vim.tbl_filter(function(lang)
      return not vim.list_contains(installed, lang)
    end, langs)
    if #to_install > 0 then
      vim.cmd("TSInstall " .. table.concat(to_install, " "))
    end
  end,
}
