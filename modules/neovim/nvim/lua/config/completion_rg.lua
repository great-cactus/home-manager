-- blink.cmp source: words of the project, searched with ripgrep.
local M = {}

M.max_count = 20

-- Project root of `dir`, or nil where rg would be too slow or too broad:
-- rg over a DrvFs mount (/mnt/c on WSL) is too slow for completion.
function M.root(dir)
  local root = vim.fs.root(dir, '.git') or dir
  if root:match('^/mnt/%a/') or root == vim.env.HOME or root == '/' then
    return nil
  end
  return root
end

local function pattern(keyword)
  return [[\b]] .. keyword:gsub('[%^%$%.%*%+%?%(%)%[%]{}|\\]', '\\%0') .. [[\w+]]
end

local has_rg -- cached: executable() walks PATH on every call

function M.new(opts)
  return setmetatable({ opts = opts or {} }, { __index = M })
end

function M:enabled()
  if has_rg == nil then
    has_rg = vim.fn.executable('rg') == 1
  end
  return has_rg
end

function M:get_completions(ctx, callback)
  local keyword = ctx.get_keyword()
  local root = M.root(vim.fn.getcwd())
  if not root then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end
  local ok, proc = pcall(vim.system, {
    'rg', '--no-config', '--only-matching', '--no-filename', '--no-line-number',
    '--smart-case', '--max-count', tostring(M.max_count), '--max-columns', '300',
    '-e', pattern(keyword), '.',
  }, { cwd = root, text = true }, vim.schedule_wrap(function(res)
    local kind = require('blink.cmp.types').CompletionItemKind.Text
    local seen, items = {}, {}
    for word in (res.stdout or ''):gmatch('[^\n]+') do
      if word ~= keyword and not seen[word] then
        seen[word] = true
        items[#items + 1] = { label = word, kind = kind }
      end
    end
    -- --max-count truncates, so a longer keyword may find other words
    callback({ items = items, is_incomplete_forward = true, is_incomplete_backward = true })
  end))
  if not ok then
    callback({ items = {} })
    return
  end
  return function()
    pcall(proc.kill, proc, 'sigterm')
  end
end

return M
