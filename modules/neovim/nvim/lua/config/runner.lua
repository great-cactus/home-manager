local M = {}

-- filetype -> command mapping
-- $file: full path, $dir: directory, $fileName: filename
local filetype_cmds = {
  python = "cd $dir && uv run $fileName",
  tex    = "cd $dir && latexmk $fileName",
}

local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

local state = {
  job_id = nil,
  stdout = {},
  stderr = {},
  spinner_idx = 0,
  spinner_timer = nil,
  notification = nil,
}

local function start_spinner(cmd)
  state.spinner_idx = 0
  state.notification = vim.notify(
    spinner_frames[1] .. ' ' .. cmd,
    vim.log.levels.INFO,
    { title = "Runner", timeout = false }
  )
  state.spinner_timer = vim.uv.new_timer()
  state.spinner_timer:start(80, 80, vim.schedule_wrap(function()
    state.spinner_idx = (state.spinner_idx + 1) % #spinner_frames
    state.notification = vim.notify(
      spinner_frames[state.spinner_idx + 1] .. ' Running...',
      vim.log.levels.INFO,
      { title = "Runner", replace = state.notification, timeout = false }
    )
  end))
end

local function stop_spinner()
  if state.spinner_timer then
    state.spinner_timer:stop()
    state.spinner_timer:close()
    state.spinner_timer = nil
  end
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
  start_spinner(cmd)

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
        if line ~= '' then table.insert(state.stderr, line) end
      end
    end,
    on_exit = function(_, exit_code)
      stop_spinner()
      state.job_id = nil
      vim.schedule(function()
        local level = exit_code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
        local status = exit_code == 0 and 'Done' or ('Exit code: ' .. exit_code)
        local default_timeout = require("notify")._config().default_timeout()
        vim.notify(status, level, { title = "Runner", replace = state.notification, timeout = default_timeout })

        if #state.stdout > 0 then
          vim.notify(
            table.concat(state.stdout, '\n'),
            vim.log.levels.INFO,
            { title = "Runner [stdout]" }
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
    stop_spinner()
    state.job_id = nil
    local default_timeout = require("notify")._config().default_timeout()
    vim.notify("Killed", vim.log.levels.WARN, { title = "Runner", replace = state.notification, timeout = default_timeout })
  end
end

function M.show_output()
  if #state.stdout == 0 and #state.stderr == 0 then
    vim.notify("No output", vim.log.levels.INFO, { title = "Runner" })
    return
  end
  local lines = {}
  if #state.stdout > 0 then
    table.insert(lines, '=== stdout ===')
    vim.list_extend(lines, state.stdout)
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
