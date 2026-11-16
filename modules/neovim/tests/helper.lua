-- Minimal test harness for headless Neovim.
--
-- A test is a list of steps run one after another on the main loop, so typed
-- keys (H.feed) and async callbacks are processed between steps. A step may
-- return a delay in ms before the next step starts.
local H = {}

local repo = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
H.repo = repo
H.dein = vim.fn.expand('~/.cache/dein/repos/github.com')

local tests = {}
local only = vim.env.TEST_ONLY

function H.rtp(...)
  for _, dir in ipairs({ ... }) do
    vim.opt.runtimepath:prepend(dir)
    vim.opt.packpath:prepend(dir)
  end
end

-- The repo's Lua modules (config.*, plugins.*, lsp.*); integration tests
-- use the installed configuration only.
if vim.env.TEST_INSTALLED ~= '1' then
  H.rtp(repo .. '/nvim')
end

function H.test(name, steps)
  if not only or name:find(only, 1, true) then
    tests[#tests + 1] = { name = name, steps = steps }
  end
end

function H.feed(keys, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), mode or 'mt', false)
end

function H.eq(expected, actual, msg)
  if not vim.deep_equal(expected, actual) then
    error(('%sexpected %s, got %s'):format(msg and (msg .. ': ') or '', vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

function H.ok(cond, msg)
  if not cond then
    error(msg or 'assertion failed', 2)
  end
end

-- Popup items that match the typed text (what is displayed)
function H.matches()
  return vim.fn.complete_info({ 'matches' }).matches or {}
end

-- Index of the first displayed item with this word/menu, for
-- nvim_select_popupmenu_item()
function H.index_of(word, menu)
  for i, it in ipairs(H.matches()) do
    if (word == nil or it.word == word) and (menu == nil or it.menu == menu) then
      return i - 1
    end
  end
end

-- "word menu" of every displayed item
function H.items()
  return vim.tbl_map(function(it)
    return it.menu ~= '' and (it.word .. ' ' .. it.menu) or it.word
  end, H.matches())
end

function H.has_item(word, menu)
  for _, it in ipairs(H.matches()) do
    if it.word == word and (menu == nil or it.menu == menu) then
      return true
    end
  end
  return false
end

function H.line()
  return vim.api.nvim_get_current_line()
end

-- Leave insert mode and start a scratch buffer with the given lines; the
-- cursor is put at the end of the last line.
function H.fresh(lines, opts)
  opts = opts or {}
  vim.cmd('stopinsert')
  vim.cmd('enew!')
  vim.bo.bufhidden = 'wipe'
  if opts.filetype then
    vim.bo.filetype = opts.filetype
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines or { '' })
  local last = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, { last, #vim.api.nvim_buf_get_lines(0, last - 1, last, false)[1] })
end

function H.tmpdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  return dir
end

function H.write(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  vim.fn.writefile(lines, path)
end

-- In-process fake language server.
--   opts.complete(params) -> items, delay_ms, isIncomplete
--   opts.trigger_characters
function H.fake_lsp(opts)
  local function server(dispatchers)
    local closing = false
    return {
      request = function(method, params, cb)
        if method == 'initialize' then
          cb(nil, {
            capabilities = {
              completionProvider = { triggerCharacters = opts.trigger_characters or {} },
            },
          })
        elseif method == 'textDocument/completion' then
          local items, delay, incomplete = opts.complete(params)
          vim.defer_fn(function()
            cb(nil, { isIncomplete = incomplete or false, items = items })
          end, delay or 0)
        else
          cb(nil, nil)
        end
        return true, math.random(1, 1e9)
      end,
      notify = function()
        return true
      end,
      is_closing = function()
        return closing
      end,
      terminate = function()
        closing = true
      end,
    }
  end
  local id = vim.lsp.start({
    name = opts.name or 'fake',
    cmd = server,
    root_dir = vim.fn.getcwd(),
    offset_encoding = opts.offset_encoding,
  })
  vim.wait(500, function()
    return #vim.lsp.get_clients({ bufnr = 0, id = id }) > 0
  end)
  return id
end

function H.run()
  local failed, passed = 0, 0
  local function finish()
    io.stdout:write(('\n%d passed, %d failed\n'):format(passed, failed))
    vim.cmd(failed > 0 and 'cquit 1' or 'qall!')
  end
  local function run_test(i)
    local t = tests[i]
    if not t then
      return finish()
    end
    local function step(j)
      local s = t.steps[j]
      if not s then
        passed = passed + 1
        io.stdout:write('\nPASS ' .. t.name .. '\n')
        io.stdout:flush()
        return vim.schedule(function()
          run_test(i + 1)
        end)
      end
      local ok, res = pcall(s)
      if not ok then
        failed = failed + 1
        io.stdout:write(('\nFAIL %s (step %d)\n  %s\n'):format(t.name, j, tostring(res)))
        io.stdout:flush()
        H.feed('<Esc>', 'nt')
        return vim.defer_fn(function()
          run_test(i + 1)
        end, 20)
      end
      vim.defer_fn(function()
        step(j + 1)
      end, type(res) == 'number' and res or 0)
    end
    step(1)
  end
  vim.schedule(function()
    run_test(1)
  end)
end

return H
