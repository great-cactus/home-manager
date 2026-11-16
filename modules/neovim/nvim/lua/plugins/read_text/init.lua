-- Read text aloud (Lua port of great-cactus/read-text.vim, no denops).
--
--   :ReadFromCursor [voice]   cursor line to the end of the buffer
--   :ReadSelection [voice]    last visual selection
--   :ReadLine [voice]         current line
--   :ReadTextStop / :ReadTextPause / :ReadTextResume / :ReadTextTogglePause
--   :ReadTextCheckConnection  is the provider usable?
-- The *Async commands of read-text.vim remain as aliases that also report
-- completion. LaTeX buffers are read through plugins.read_text.rules.
local M = {}

M.defaults = {
  tts_provider = 'voicevox', -- voicevox | espeak | melo | kokoro
  voicevox_url = 'http://localhost:50021',
  voicevox_speaker = 3,
  espeak_voice = 'en',
  espeak_variant = '',
  espeak_command = 'espeak',
  melo_language = 'EN',
  melo_speaker = 'EN-US',
  melo_device = 'auto',
  melo_python = 'python3',
  kokoro_command = 'kokoro-tts',
  kokoro_model_path = '~/.local/share/kokoro-tts/kokoro-v1.0.onnx',
  kokoro_voices_path = '~/.local/share/kokoro-tts/voices-v1.0.bin',
  kokoro_lang = 'en-us',
  kokoro_voice = 'af_sarah',
  kokoro_format = 'wav',
  speed = 1.0,
  pitch = 0.0,
  temp_dir = vim.fn.stdpath('cache') .. '/read-text',
  file_prefix = 'vim_tts_',
  auto_cleanup = true,
  audio_command = 'aplay',
  audio_args = { '-q' },
  split_threshold = 50,
  pipeline_buffer_size = 2,
  reading_rules = true,
}

M.config = vim.deepcopy(M.defaults)
local current -- running engine

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = 'read-text' })
  end)
end

-- >>> text extraction
local function apply_rules(text, bufname)
  if M.config.reading_rules and require('plugins.read_text.rules').applies_to(bufname) then
    return require('plugins.read_text.rules').parse(text)
  end
  return text
end

function M.text_from_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  return table.concat(vim.api.nvim_buf_get_lines(0, row - 1, -1, false), '\n')
end

function M.text_of_selection()
  local mode = vim.fn.visualmode()
  local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = mode ~= '' and mode or 'v' })
  return table.concat(lines, '\n')
end

function M.text_of_line()
  return vim.api.nvim_get_current_line()
end
-- <<< text extraction

--- Read `text`; any reading in progress is stopped first.
function M.read(text, opts, on_done)
  M.stop()
  local engine = require('plugins.read_text.engine').new(M.config)
  current = engine
  engine:start(text, opts, function(err)
    if current == engine then
      current = nil
    end
    if on_done then
      on_done(err)
    end
  end)
  return engine
end

function M.stop()
  if current then
    current:stop()
    current = nil
  end
end

function M.pause()
  return current ~= nil and current:pause()
end

function M.resume()
  return current ~= nil and current:resume()
end

function M.toggle_pause()
  if not current then
    return false
  end
  return current:is_paused() and current:resume() or current:pause()
end

function M.is_active()
  return current ~= nil and current:is_active()
end

local extractors = {
  ReadFromCursor = M.text_from_cursor,
  ReadSelection = M.text_of_selection,
  ReadLine = M.text_of_line,
}

local function run(name, args, report)
  local opts = {}
  local voice = vim.trim(args or '')
  if voice ~= '' then
    opts.voice = voice
  end
  local text = apply_rules(extractors[name](), vim.api.nvim_buf_get_name(0))
  M.read(text, opts, function(err)
    if err then
      notify(name .. ' failed: ' .. err, vim.log.levels.ERROR)
    elseif report then
      notify('Read text completed')
    end
  end)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts or {})

  local command = vim.api.nvim_create_user_command
  for name in pairs(extractors) do
    local range = name == 'ReadSelection' and { range = true } or {}
    command(name, function(o)
      run(name, o.args, false)
    end, vim.tbl_extend('force', { nargs = '?' }, range))
    command(name .. 'Async', function(o)
      run(name, o.args, true)
    end, vim.tbl_extend('force', { nargs = '?' }, range))
  end
  command('ReadTextStop', M.stop, {})
  command('ReadTextPause', M.pause, {})
  command('ReadTextResume', M.resume, {})
  command('ReadTextTogglePause', M.toggle_pause, {})
  command('ReadTextCheckConnection', function()
    local ok = require('plugins.read_text.providers').check(M.config)
    vim.notify(('%s: %s'):format(M.config.tts_provider, ok and 'OK' or 'not available'), ok and vim.log.levels.INFO or vim.log.levels.WARN)
  end, {})

  local function plug(mode, name, rhs)
    vim.keymap.set(mode, '<Plug>(read-text-' .. name .. ')', rhs, { silent = true })
  end
  -- ':<C-u>' leaves Visual mode first so '< and '> are set
  plug('n', 'from-cursor', '<Cmd>ReadFromCursor<CR>')
  plug('x', 'selection', ':<C-u>ReadSelection<CR>')
  plug('n', 'line', '<Cmd>ReadLine<CR>')
  plug('n', 'from-cursor-async', '<Cmd>ReadFromCursorAsync<CR>')
  plug('x', 'selection-async', ':<C-u>ReadSelectionAsync<CR>')
  plug('n', 'line-async', '<Cmd>ReadLineAsync<CR>')
  plug('n', 'stop', '<Cmd>ReadTextStop<CR>')
  plug('n', 'pause', '<Cmd>ReadTextPause<CR>')
  plug('n', 'resume', '<Cmd>ReadTextResume<CR>')
  plug('n', 'toggle-pause', '<Cmd>ReadTextTogglePause<CR>')
  plug('n', 'check-connection', '<Cmd>ReadTextCheckConnection<CR>')

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('ReadText', { clear = true }),
    callback = M.stop,
  })
end

return M
