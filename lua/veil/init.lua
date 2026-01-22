local M = {}

M.enabled = false
M.matches = {}

-- Default configuration
M.defaults = {
  -- Files where veil is automatically enabled
  files = {
    ".env",
    ".env.*",
    ".npmrc",
    ".pypirc",
    "credentials.json",
    "secrets.yaml",
    "secrets.yml",
    ".secrets",
  },
  -- Patterns to match (key = value format)
  -- The VALUE part will be concealed (content inside quotes, not the quotes themselves)
  patterns = {
    -- Generic patterns for any file
    { pattern = "(%w+_KEY%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(%w+_SECRET%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(%w+_TOKEN%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(%w+_PASSWORD%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(API_KEY%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(AUTH_SECRET%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(DATABASE_URL%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(REDIS_URL%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(password%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(secret%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
    { pattern = "(token%s*[=:]%s*[\"']?)([^\"'\n]+)", group = 2 },
  },
  -- Character used to conceal
  conceal_char = "*",
  -- Auto enable on matching files
  auto_enable = true,
  -- Extra files added by user (merged with defaults)
  extra_files = {},
  -- Extra patterns added by user (merged with defaults)
  extra_patterns = {},
  -- Exclude default files (use only user-defined)
  exclude_default_files = false,
  -- Exclude default patterns (use only user-defined)
  exclude_default_patterns = false,
  -- Highlight settings for concealed text (nil = use theme's Comment color)
  highlight = nil,
  -- Reveal value when entering insert mode on the line
  reveal_on_insert = false,
  -- Default keybindings (set to false to disable)
  keymaps = {
    toggle = "<leader>sv",  -- Toggle veil
    peek = "<leader>sp",    -- Peek at values
  },
}

M.opts = {}

-- Build a pattern from a simple keyword (e.g., "MY_VAR" -> pattern that matches MY_VAR=value)
local function keyword_to_pattern(keyword)
  return {
    pattern = "(" .. keyword .. "%s*[=:]%s*[\"']?)([^\"'\n]+)",
    group = 2,
  }
end

-- Get a color from the user's theme
local function get_theme_color()
  -- Try to get Comment highlight (always exists in themes)
  local comment_hl = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  if comment_hl and comment_hl.fg then
    return string.format("#%06x", comment_hl.fg)
  end
  -- Fallback to a neutral color
  return "#888888"
end

-- Check if current file matches configured files
local function is_target_file()
  local filename = vim.fn.expand("%:t")
  local filepath = vim.fn.expand("%:p")

  for _, pattern in ipairs(M.opts.files) do
    -- Check exact filename match
    if filename == pattern then
      return true
    end
    -- Check glob pattern (e.g., .env.*)
    if pattern:match("%*") then
      local regex = pattern:gsub("%.", "%%."):gsub("%*", ".*")
      if filename:match("^" .. regex .. "$") then
        return true
      end
    end
  end
  return false
end

-- Apply concealment to current buffer
local function apply_conceal()
  if not M.enabled then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Clear existing matches
  M.clear_matches()

  -- Set conceal options
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = "nvic"

  for line_num, line in ipairs(lines) do
    for _, pat in ipairs(M.opts.patterns) do
      -- Use Vim regex for matching
      local vim_pattern = pat.pattern:gsub("%(", "\\("):gsub("%)", "\\)")
      
      -- Find all matches in the line
      local start_col = 1
      while true do
        local match_start, match_end = line:find(pat.pattern, start_col)
        if not match_start then
          break
        end

        -- Extract the parts using Lua pattern
        local full_match = line:sub(match_start, match_end)
        local key_part, value_part = full_match:match(pat.pattern)

        if value_part and #value_part > 0 then
          -- Calculate the column where the value starts
          local key_len = key_part and #key_part or 0
          local value_start_col = match_start + key_len - 1

          -- Add match for concealing
          local match_id = vim.fn.matchadd("Conceal", 
            string.format("\\%%%dl\\%%>%dc\\%%<%dc.", 
              line_num, 
              value_start_col,
              match_end + 1
            ),
            100,
            -1,
            { conceal = M.opts.conceal_char }
          )
          table.insert(M.matches, match_id)
        end

        start_col = match_end + 1
      end
    end
  end
end

-- Clear all concealment matches
function M.clear_matches()
  for _, match_id in ipairs(M.matches) do
    pcall(vim.fn.matchdelete, match_id)
  end
  M.matches = {}
end

-- Enable veil
function M.enable()
  if M.enabled then
    return -- Already enabled, don't notify again
  end
  M.enabled = true
  apply_conceal()
  vim.notify("Veil enabled", vim.log.levels.INFO)
end

-- Disable veil
function M.disable()
  M.enabled = false
  M.clear_matches()
  vim.wo.conceallevel = 0
  vim.notify("Veil disabled", vim.log.levels.INFO)
end

-- Toggle veil
function M.toggle()
  if M.enabled then
    M.disable()
  else
    M.enable()
  end
end

-- Peek - temporarily reveal value on current line only
M.peek_line = nil

function M.peek()
  if not M.enabled then
    vim.notify("Veil is not enabled", vim.log.levels.WARN)
    return
  end

  local current_line = vim.fn.line(".")

  -- If already peeking this line, stop
  if M.peek_line == current_line then
    M.stop_peek()
    return
  end

  -- Start peeking current line
  M.peek_line = current_line
  M.apply_conceal_except_line(current_line)
end

-- Stop peeking and restore all conceals
function M.stop_peek()
  if M.peek_line then
    M.peek_line = nil
    apply_conceal()
  end
end

-- Apply conceal to all lines except the specified one
function M.apply_conceal_except_line(skip_line)
  M.clear_matches()

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  vim.wo.conceallevel = 2
  vim.wo.concealcursor = "nvic"

  for line_num, line in ipairs(lines) do
    if line_num ~= skip_line then
      for _, pat in ipairs(M.opts.patterns) do
        local start_col = 1
        while true do
          local match_start, match_end = line:find(pat.pattern, start_col)
          if not match_start then
            break
          end

          local full_match = line:sub(match_start, match_end)
          local key_part, value_part = full_match:match(pat.pattern)

          if value_part and #value_part > 0 then
            local key_len = key_part and #key_part or 0
            local value_start_col = match_start + key_len - 1

            local match_id = vim.fn.matchadd("Conceal",
              string.format("\\%%%dl\\%%>%dc\\%%<%dc.",
                line_num,
                value_start_col,
                match_end + 1
              ),
              100,
              -1,
              { conceal = M.opts.conceal_char }
            )
            table.insert(M.matches, match_id)
          end

          start_col = match_end + 1
        end
      end
    end
  end
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  M.opts = vim.tbl_deep_extend("force", M.defaults, opts)

  -- Handle files
  if M.opts.exclude_default_files then
    M.opts.files = {}
  end
  -- Merge extra_files into files
  for _, file in ipairs(M.opts.extra_files) do
    table.insert(M.opts.files, file)
  end

  -- Handle patterns
  if M.opts.exclude_default_patterns then
    M.opts.patterns = {}
  end
  -- Merge extra_patterns into patterns
  for _, pat in ipairs(M.opts.extra_patterns) do
    -- If it's a simple string, convert to pattern
    if type(pat) == "string" then
      table.insert(M.opts.patterns, keyword_to_pattern(pat))
    else
      table.insert(M.opts.patterns, pat)
    end
  end

  -- Set up highlight group
  local hl_opts = M.opts.highlight or { fg = get_theme_color() }
  vim.api.nvim_set_hl(0, "VeilConceal", hl_opts)
  -- Link Conceal to our custom highlight
  vim.api.nvim_set_hl(0, "Conceal", { link = "VeilConceal" })

  -- Create user commands
  vim.api.nvim_create_user_command("Veil", function()
    M.toggle()
  end, { desc = "Toggle Veil" })

  vim.api.nvim_create_user_command("VeilEnable", function()
    M.enable()
  end, { desc = "Enable Veil" })

  vim.api.nvim_create_user_command("VeilDisable", function()
    M.disable()
  end, { desc = "Disable Veil" })

  vim.api.nvim_create_user_command("VeilPeek", function()
    M.peek()
  end, { desc = "Toggle peek mode (reveal values temporarily)" })

  -- Set up keymaps
  if M.opts.keymaps then
    if M.opts.keymaps.toggle then
      vim.keymap.set("n", M.opts.keymaps.toggle, "<cmd>Veil<CR>", { desc = "Toggle Veil" })
    end
    if M.opts.keymaps.peek then
      vim.keymap.set("n", M.opts.keymaps.peek, "<cmd>VeilPeek<CR>", { desc = "Peek at values" })
    end
  end

  local group = vim.api.nvim_create_augroup("Veil", { clear = true })

  -- Auto-enable on matching files
  if M.opts.auto_enable then
    vim.api.nvim_create_autocmd({ "BufEnter", "BufRead" }, {
      group = group,
      callback = function()
        if is_target_file() then
          M.enable()
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = group,
      callback = function()
        if M.enabled and is_target_file() then
          apply_conceal()
        end
      end,
    })
  end

  -- Reveal on insert mode (optional)
  if M.opts.reveal_on_insert then
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = group,
      callback = function()
        if M.enabled and is_target_file() then
          vim.wo.concealcursor = "nvc" -- Remove 'i' to reveal in insert mode
        end
      end,
    })

    vim.api.nvim_create_autocmd("InsertLeave", {
      group = group,
      callback = function()
        if M.enabled and is_target_file() then
          vim.wo.concealcursor = "nvic" -- Restore full conceal
        end
      end,
    })
  end

  -- Auto-hide peek when leaving the line
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    callback = function()
      if M.peek_line and M.peek_line ~= vim.fn.line(".") then
        M.stop_peek()
      end
    end,
  })
end

return M
