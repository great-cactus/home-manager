local M = {}

-- filetype -> command mapping
-- $file: full path, $dir: directory, $fileName: filename
local filetype_cmds = {
  python = "cd $dir && uv run $fileName",
  tex    = "cd $dir && latexmk $fileName",
}

-- Patterns that start a warning block
local warn_starters = {
  ':%d+: %w+Warning:',       -- Python: /path/file.py:42: DeprecationWarning: ...
  '^%u%w+Warning:',           -- Python standalone: ResourceWarning: Enable tracemalloc ...
  '^LaTeX Warning:',           -- LaTeX Warning: Reference `fig:x' undefined ...
  '^Package %S+ Warning:',    -- Package hyperref Warning: ...
  '^Class %S+ Warning:',      -- Class memoir Warning: ...
  '^Overfull \\[hv]box',      -- Overfull \hbox (9.1pt too wide) ...
  '^Underfull \\[hv]box',     -- Underfull \hbox (badness 10000) ...
}

-- Patterns that start an error block
local error_starters = {
  '^Traceback %(most recent call last%):',  -- Python traceback header
  '^%u%w+Error:',              -- Python ValueError: / SyntaxError: ...
  '^%u%w+Exception:',          -- Python RuntimeException: ...
  '^!',                        -- LaTeX ! Undefined control sequence.
}

local function refresh_incline()
  pcall(function() require('incline').refresh() end)
end

local state = {
  job_id = nil,
  buf = nil,
  stdout = {},
  stderr = {},
  warn = {},
  prev_kind = nil,
}

local function classify_stderr(line)
  for _, pat in ipairs(warn_starters) do
    if line:find(pat) then
      state.prev_kind = 'warn'
      return 'warn'
    end
  end
  for _, pat in ipairs(error_starters) do
    if line:find(pat) then
      state.prev_kind = 'error'
      return 'error'
    end
  end
  if state.prev_kind then
    return state.prev_kind
  end
  return 'error'
end


function M.run()
  if state.job_id then
    M.stop()
    return
  end

  local ft = vim.bo.filetype
  local cmd_template = filetype_cmds[ft]
  if not cmd_template then
    vim.notify("No runner configured for filetype: " .. ft, vim.log.levels.WARN, { title = "Runner" })
    return
  end

  local file = vim.fn.expand('%:p')
  local dir = vim.fn.expand('%:p:h')
  local fileName = vim.fn.expand('%:t')
  local cmd = cmd_template
    :gsub('%$fileName', fileName)
    :gsub('%$file', file)
    :gsub('%$dir', dir)

  state.stdout = {}
  state.stderr = {}
  state.warn = {}
  state.prev_kind = nil
  state.buf = vim.api.nvim_get_current_buf()
  vim.b[state.buf].runner_active = true
  refresh_incline()

  state.job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= '' then table.insert(state.stdout, line) end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line == '' then
          state.prev_kind = nil
        else
          if classify_stderr(line) == 'warn' then
            table.insert(state.warn, line)
          else
            table.insert(state.stderr, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      state.job_id = nil
      vim.schedule(function()
        local level = exit_code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
        if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
          vim.b[state.buf].runner_active = false
        end
        refresh_incline()
        local status = exit_code == 0 and 'Done' or ('Exit code: ' .. exit_code)
        local default_timeout = require("notify")._config().default_timeout()
        vim.notify(status, level, { title = "Runner", timeout = default_timeout })

        if #state.stdout > 0 then
          vim.notify(
            table.concat(state.stdout, '\n'),
            vim.log.levels.INFO,
            { title = "Runner [stdout]" }
          )
        end

        if #state.warn > 0 then
          vim.notify(
            table.concat(state.warn, '\n'),
            vim.log.levels.WARN,
            { title = "Runner [warn]" }
          )
        end

        if #state.stderr > 0 then
          vim.notify(
            table.concat(state.stderr, '\n'),
            vim.log.levels.ERROR,
            { title = "Runner [stderr]" }
          )
        end
      end)
    end,
  })
end

function M.stop()
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
      vim.b[state.buf].runner_active = false
    end
    refresh_incline()
    local default_timeout = require("notify")._config().default_timeout()
    vim.notify("Killed", vim.log.levels.WARN, { title = "Runner", timeout = default_timeout })
  end
end

function M.show_output()
  if #state.stdout == 0 and #state.warn == 0 and #state.stderr == 0 then
    vim.notify("No output", vim.log.levels.INFO, { title = "Runner" })
    return
  end
  local lines = {}
  if #state.stdout > 0 then
    table.insert(lines, '=== stdout ===')
    vim.list_extend(lines, state.stdout)
  end
  if #state.warn > 0 then
    if #lines > 0 then table.insert(lines, '') end
    table.insert(lines, '=== warn ===')
    vim.list_extend(lines, state.warn)
  end
  if #state.stderr > 0 then
    if #lines > 0 then table.insert(lines, '') end
    table.insert(lines, '=== stderr ===')
    vim.list_extend(lines, state.stderr)
  end
  vim.cmd('botright new')
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].modifiable = false
end

function M.setup(opts)
  opts = opts or {}

  if opts.filetype then
    for ft, cmd in pairs(opts.filetype) do
      filetype_cmds[ft] = cmd
    end
  end

  local run_key = opts.run_key or '<F5>'
  local output_key = opts.output_key or '<leader>ro'
  local stop_key = opts.stop_key or nil

  vim.keymap.set('n', run_key, M.run, { silent = true, desc = 'Run file' })
  vim.keymap.set('n', output_key, M.show_output, { silent = true, desc = 'Show runner output' })
  if stop_key then
    vim.keymap.set('n', stop_key, M.stop, { silent = true, desc = 'Stop runner' })
  end
end

return M
