return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "Work Notes",
        path = "~/Documents/Work Notes",
      },
    },

    -- Completion settings
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },

    -- Note ID and path settings
    note_id_func = function(title)
      return title
    end,

    frontmatter = {
      enabled = false,
    },

    -- Daily Notes Directory
    notes_subdir = "daily",

    -- UI settings - disable obsidian.nvim's built-in UI
    ui = {
      enable = false,
    },

    legacy_commands = false,

    -- Picker configuration
    picker = {
      name = "telescope.nvim",
    },

    -- Templates
    templates = {
      subdir = "~/Documents/Work Notes/Admin/Utilities/Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },
  },

  config = function(_, opts)
    require("obsidian").setup(opts)

    -- Define your custom ObsidianWeekly command
    vim.api.nvim_create_user_command("ObsidianWeekly", function()
      local vault_root = vim.fn.expand("~/Documents/Work Notes")
      local weekly_base = vault_root .. "/Admin/Weekly Notes"

      -- Compute current ISO week info: week number from today, date from Sunday
      local now = os.time()
      local wday = os.date("*t", now).wday -- 1=Sun
      local sunday = now - (wday - 1) * 86400
      local week_num = tonumber(os.date("%V", now))
      local year = tonumber(os.date("%G", now))
      local month_day = os.date("%m-%d", sunday)
      local filename = string.format("%d-W%02d (%s)", year, week_num, month_day)
      local weekly_folder = weekly_base .. "/" .. year
      local filepath = weekly_folder .. "/" .. filename .. ".md"

      if vim.fn.filereadable(filepath) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        print("Opened weekly note: " .. filename)
      else
        -- Ensure year folder exists
        vim.fn.mkdir(weekly_folder, "p")

        -- Use Obsidian CLI + Templater to create and process the note
        local vault_path = "Admin/Weekly Notes/" .. year
        local cmd = string.format(
          'obsidian eval \'code=(async()=>{'
            .. 'const tp=app.plugins.plugins["templater-obsidian"].templater;'
            .. 'const template=app.vault.getAbstractFileByPath("Admin/Utilities/Templates/Weekly Note Template.md");'
            .. 'const folder=app.vault.getAbstractFileByPath("%s");'
            .. 'await tp.create_new_note_from_template(template,folder,"%s")'
            .. "})()\'",
          vault_path, filename
        )
        local result = vim.fn.system(cmd)
        if vim.v.shell_error ~= 0 then
          vim.notify("Failed to create weekly note: " .. result, vim.log.levels.ERROR)
          return
        end

        -- Open the newly created file
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        print("Created weekly note: " .. filename)
      end
    end, {
      desc = "Open or create weekly note with Templater via Obsidian CLI"
    })

    -- Define Catppuccin Mocha colors for TOC headings
    vim.api.nvim_set_hl(0, "ObsidianTOCH1", { fg = "#f38ba8", bold = true })  -- Red
    vim.api.nvim_set_hl(0, "ObsidianTOCH2", { fg = "#fab387", bold = true })  -- Peach
    vim.api.nvim_set_hl(0, "ObsidianTOCH3", { fg = "#f9e2af" })               -- Yellow
    vim.api.nvim_set_hl(0, "ObsidianTOCH4", { fg = "#a6e3a1" })               -- Green
    vim.api.nvim_set_hl(0, "ObsidianTOCH5", { fg = "#89b4fa" })               -- Blue
    vim.api.nvim_set_hl(0, "ObsidianTOCH6", { fg = "#cba6f7" })               -- Mauve

    -- Custom clean TOC command with proper indentation and colors
    vim.api.nvim_create_user_command("ObsidianTOCClean", function()
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local entry_display = require("telescope.pickers.entry_display")

      -- Get current buffer content
      local bufnr = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      -- Parse headings
      local headings = {}
      for lnum, line in ipairs(lines) do
        local level, text = line:match("^(#+)%s+(.+)$")
        if level then
          table.insert(headings, {
            lnum = lnum,
            text = text,
            level = #level,
          })
        end
      end

      -- Create displayer with proper formatting
      local displayer = entry_display.create({
        separator = "",
        items = {
          { width = 100 },
        },
      })

      local function make_display(entry)
        -- Use box drawing characters for indentation
        local indent = string.rep("│ ", entry.level - 1)
        local icon = "▸"
        local hl_group = "ObsidianTOCH" .. entry.level

        return displayer({
          { indent .. icon .. " " .. entry.text, hl_group },
        })
      end

      -- Create picker
      pickers.new({}, {
        prompt_title = "Table of Contents",
        finder = finders.new_table({
          results = headings,
          entry_maker = function(entry)
            return {
              value = entry,
              display = make_display,
              ordinal = entry.text,
              lnum = entry.lnum,
              level = entry.level,
              text = entry.text,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        sorting_strategy = "ascending",  -- This makes items appear top to bottom
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            vim.api.nvim_win_set_cursor(0, {selection.lnum, 0})
          end)
          return true
        end,
      }):find()
    end, { desc = "Clean TOC picker" })

    -- Smart switch: search by filename, aliases, tags, and type
    vim.api.nvim_create_user_command("ObsidianSmartSwitch", function()
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      local vault = vim.fn.expand("~/Documents/Work Notes")
      local files = vim.fn.globpath(vault, "**/*.md", false, true)
      local entries = {}

      for _, filepath in ipairs(files) do
        local name = vim.fn.fnamemodify(filepath, ":t:r")
        local aliases, tags, ftype = {}, {}, ""

        -- Read frontmatter (first 20 lines max)
        local f = io.open(filepath, "r")
        if f then
          local first_line = f:read("*l")
          if first_line and first_line:match("^---") then
            local yaml = {}
            for line in f:lines() do
              if line:match("^---") then break end
              yaml[#yaml + 1] = line
              if #yaml > 20 then break end
            end
            local raw = table.concat(yaml, "\n")

            -- Parse aliases
            local in_aliases = false
            local in_tags = false
            for _, line in ipairs(yaml) do
              -- Detect section starts
              if line:match("^aliases:") then
                in_aliases = true
                in_tags = false
                -- Check inline: aliases: [a, b]
                local inline = line:match("^aliases:%s*%[([^%]]+)%]")
                if inline then
                  for a in inline:gmatch("([^,]+)") do
                    aliases[#aliases + 1] = a:match("^%s*(.-)%s*$")
                  end
                  in_aliases = false
                end
              elseif line:match("^tags?:") then
                in_tags = true
                in_aliases = false
                local inline = line:match("^tags?:%s*%[([^%]]+)%]")
                if inline then
                  for t in inline:gmatch("([^,]+)") do
                    tags[#tags + 1] = t:match("^%s*(.-)%s*$")
                  end
                  in_tags = false
                end
              elseif line:match("^type:") then
                ftype = line:match("^type:%s*(.+)") or ""
                ftype = ftype:match("^%s*(.-)%s*$") or ""
                in_aliases = false
                in_tags = false
              elseif line:match("^%S") then
                -- New top-level key, stop collecting
                in_aliases = false
                in_tags = false
              elseif in_aliases and line:match("^%s+%- ") then
                aliases[#aliases + 1] = line:match("^%s+%- (.+)"):match("^%s*(.-)%s*$")
              elseif in_tags and line:match("^%s+%- ") then
                tags[#tags + 1] = line:match("^%s+%- (.+)"):match("^%s*(.-)%s*$")
              end
            end
          end
          f:close()
        end

        local ordinal = name
          .. " " .. table.concat(aliases, " ")
          .. " " .. table.concat(tags, " ")
          .. " " .. ftype

        entries[#entries + 1] = {
          path = filepath,
          name = name,
          aliases = aliases,
          tags = tags,
          ftype = ftype,
          ordinal = ordinal,
        }
      end

      pickers.new({}, {
        prompt_title = "Smart Switch (name/aliases/tags/type)",
        finder = finders.new_table({
          results = entries,
          entry_maker = function(entry)
            local display = entry.name

            return {
              value = entry,
              display = display,
              ordinal = entry.ordinal,
              path = entry.path,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
          end)
          return true
        end,
      }):find()
    end, { desc = "Smart switch notes by name, aliases, tags, type" })

    -- Keybindings
    local keymap = vim.keymap

    -- Note management
    keymap.set("n", "<leader>on", "<cmd>Obsidian new<cr>", { desc = "Create new note" })
    keymap.set("n", "<leader>oo", "<cmd>Obsidian open<cr>", { desc = "Open note in Obsidian app" })
    keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>", { desc = "Search notes" })
    keymap.set("n", "<leader>oq", "<cmd>ObsidianSmartSwitch<cr>", { desc = "Smart switch notes" })
    keymap.set("n", "<leader>oc", "<cmd>ObsidianTOCClean<cr>", { desc = "Opens TOC picker" })

    -- Daily notes
    keymap.set("n", "<leader>ot", "<cmd>Obsidian today<cr>", { desc = "Open today's daily note" })
    keymap.set("n", "<leader>oy", "<cmd>Obsidian yesterday<cr>", { desc = "Open yesterday's daily note" })
    keymap.set("n", "<leader>om", "<cmd>Obsidian tomorrow<cr>", { desc = "Open tomorrow's daily note" })

    -- Weekly Notes
    keymap.set("n", "<leader>wn", "<cmd>ObsidianWeekly<cr>", { desc = "Open weekly note" })

    -- Links and backlinks
    keymap.set("v", "<leader>ol", "<cmd>Obsidian link<cr>", { desc = "Create link to note" })
    keymap.set("v", "<leader>oL", "<cmd>Obsidian link_new<cr>", { desc = "Create link to new note" })
    keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", { desc = "Show backlinks" })

    -- Templates
    keymap.set("n", "<leader>oT", "<cmd>Obsidian template<cr>", { desc = "Insert template" })

    -- Follow link under cursor
    keymap.set("n", "<leader>of", "<cmd>Obsidian follow_link<cr>", { desc = "Follow link under cursor" })
  end,
}
