return {
  "nvim-tree/nvim-web-devicons",
  lazy = false, -- Load immediately so icons are available for other plugins
  config = function()
    require("nvim-web-devicons").setup({
      -- Globally enable default icons
      default = true,
      -- Strict mode: only show icons for files with recognized extensions
      strict = true,
      -- Override or add custom icons (optional)
      override = {
        -- Example: custom icon for a specific file type
        -- zsh = {
        --   icon = "",
        --   color = "#428850",
        --   cterm_color = "65",
        --   name = "Zsh"
        -- }
      },
    })
  end,
}
