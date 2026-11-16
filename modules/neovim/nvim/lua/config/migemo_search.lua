-- Romaji search for Japanese text (replaces denops-based kensaku-search).
--
-- <CR> on a / or ? command line whose query is romaji turns the query into
-- a migemo regex (luamigemo), so "/kensaku" finds 検索. Only buffers that
-- contain Japanese are affected; a leading flag such as \c is kept.
local M = {}

-- romaji only (from rhysd/migemo-search.vim, as kensaku-search)
M.pattern = [[\c^\%(\\\a\)\=\zs\(\(\(\([bdfghjklmnpstrzwx]\)\4\=\)\=y\=\([ei]\|[aou]h\=\)\)\|\%(ss\=\|dd\=\)\=h[aiuo]\|cc\=h[aio]\|tt\=su\|n\|-\)\+$]]
local JAPANESE = '[ぁ-んァ-ヶ一-龠々]'

-- SKK-JISYO-based dictionary linked by Nix; luamigemo's bundled one when
-- missing
M.dict_path = vim.fn.stdpath('config') .. '/dict/migemo-compact-dict'

--- The command line with its romaji query replaced, or nil.
function M.convert(cmdline)
  local start = vim.fn.match(cmdline, M.pattern)
  if start < 0 then
    return nil
  end
  local luamigemo = require('luamigemo')
  local dict = vim.fn.filereadable(M.dict_path) == 1 and M.dict_path or nil
  local query = luamigemo.get(dict):query(cmdline:sub(start + 1), luamigemo.RXOP_VIM)
  return cmdline:sub(1, start) .. luamigemo.VIM_PREFIX .. query
end

function M.on_cr()
  local cr = vim.keycode('<CR>')
  local type_ = vim.fn.getcmdtype()
  if (type_ ~= '/' and type_ ~= '?') or vim.fn.search(JAPANESE, 'nw') == 0 then
    return cr
  end
  local ok, converted = pcall(M.convert, vim.fn.getcmdline())
  if not ok or not converted then
    return cr
  end
  -- <End> first: <C-u> only deletes the text before the cursor
  return vim.keycode('<End><C-u>') .. converted .. cr
end

function M.setup()
  -- replace_keycodes = false: the regex is typed literally
  vim.keymap.set('c', '<CR>', M.on_cr, { expr = true, replace_keycodes = false, desc = 'migemo search' })
end

return M
