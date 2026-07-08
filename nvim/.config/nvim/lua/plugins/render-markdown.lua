return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons", -- Optional: for file icons
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
  end,
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Render" },
  },
  opts = {
    -- Disabled by default, toggle with <leader>mr
    enabled = false,
    -- Maximum file size to render (in MB)
    max_file_size = 1.5,
    -- Debounce rendering (in milliseconds)
    debounce = 100,
    -- Render modes (which modes to render in)
    render_modes = { "n", "c" },
    -- Anti-conceal settings
    anti_conceal = {
      -- Enable anti-conceal (prevents hiding syntax when cursor is on line)
      enabled = true,
    },
    -- Heading settings
    heading = {
      -- Enable heading rendering
      enabled = true,
      -- Heading icons
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      -- Heading signs (left column)
      sign = true,
      -- Heading backgrounds
      backgrounds = {
        "RenderMarkdownH1Bg",
        "RenderMarkdownH2Bg",
        "RenderMarkdownH3Bg",
        "RenderMarkdownH4Bg",
        "RenderMarkdownH5Bg",
        "RenderMarkdownH6Bg",
      },
    },
    -- Code block settings
    code = {
      -- Enable code block rendering
      enabled = true,
      -- Code block sign
      sign = true,
      -- Code block style
      style = "full",
      -- Syntax highlighting in code blocks
      highlight = "RenderMarkdownCode",
      highlight_language = nil,
      -- Left padding
      left_pad = 0,
      -- Right padding
      right_pad = 0,
    },
    -- Bullet list settings
    bullet = {
      -- Enable bullet rendering
      enabled = true,
      -- Bullet icons for different levels
      icons = { "●", "○", "◆", "◇" },
    },
    -- Table settings
    pipe_table = {
      -- Enable table rendering
      enabled = true,
      -- Table style: 'full' (borders around all cells), 'normal' (header separator only)
      style = "full",
      -- Cell content style: 'padded', 'trimmed', 'raw', 'overlay'
      cell = "padded",
      -- Minimum column width
      min_width = 0,
      -- Border characters (using round preset)
      preset = "round",
      -- Show alignment indicators
      alignment_indicator = "━",
    },
  },
}

