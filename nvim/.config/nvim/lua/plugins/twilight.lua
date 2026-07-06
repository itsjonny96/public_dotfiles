return {
  "folke/twilight.nvim",
  opts = {
    dimming = {
      alpha = 0.25, -- Very aggressive dimming (as low as practical)
      inactive = false,
    },
    context = 0, -- Minimal context (can't be 0, but 1 is the minimum)
    treesitter = true, -- Disable TreeSitter to avoid expanding code blocks
    expand = {}, -- Don't expand any surrounding context
  },
  config = function(_, opts)
    require("twilight").setup(opts)

    vim.opt.hlsearch = true
    vim.opt.incsearch = true

    local group = vim.api.nvim_create_augroup("TwilightSearch", { clear = true })
    local dim_ns = vim.api.nvim_create_namespace("TwilightSearchDimNS")
    local search_dim_hl = "TwilightSearchDim"
    local preserve_groups = {
      Search = true,
      IncSearch = true,
      CurSearch = true,
      Substitute = true,
    }
    local cursorline_state = {}
    local hl_ns_state = {}
    local search_active = {}
    local wrapscan_state = vim.o.wrapscan

    local function build_dim_namespace()
      vim.api.nvim_set_hl(dim_ns, search_dim_hl, { fg = "#6c7086", bg = "NONE" })
      for _, name in ipairs(vim.fn.getcompletion("", "highlight")) do
        if not preserve_groups[name] then
          vim.api.nvim_set_hl(dim_ns, name, { link = search_dim_hl })
        end
      end
    end

    local function is_search_cmdline()
      local cmdtype = vim.fn.getcmdtype()
      return cmdtype == "/" or cmdtype == "?"
    end

    local function enable_search_dimming(win)
      if search_active[win] then
        return
      end

      search_active[win] = true
      cursorline_state[win] = vim.wo[win].cursorline
      local ok, current_ns = pcall(vim.api.nvim_win_get_hl_ns, win)
      hl_ns_state[win] = ok and current_ns or -1
      vim.wo[win].cursorline = false
      wrapscan_state = vim.o.wrapscan
      vim.o.wrapscan = false

      vim.api.nvim_win_set_hl_ns(win, dim_ns)
    end

    local function disable_search_dimming(win)
      if not search_active[win] then
        return
      end

      search_active[win] = nil

      if hl_ns_state[win] ~= nil then
        vim.api.nvim_win_set_hl_ns(win, hl_ns_state[win])
        hl_ns_state[win] = nil
      end

      if cursorline_state[win] ~= nil then
        vim.wo[win].cursorline = cursorline_state[win]
        cursorline_state[win] = nil
      end

      vim.o.wrapscan = wrapscan_state
    end

    build_dim_namespace()

    vim.api.nvim_create_autocmd("CmdlineEnter", {
      group = group,
      pattern = "*",
      callback = function()
        if is_search_cmdline() then
          enable_search_dimming(vim.api.nvim_get_current_win())
        end
      end,
    })

    vim.api.nvim_create_autocmd("CmdlineChanged", {
      group = group,
      pattern = "*",
      callback = function()
        if is_search_cmdline() then
          enable_search_dimming(vim.api.nvim_get_current_win())
        end
      end,
    })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
      group = group,
      pattern = "*",
      callback = function()
        disable_search_dimming(vim.api.nvim_get_current_win())
      end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
      group = group,
      callback = function()
        build_dim_namespace()
      end,
    })
  end,
}
