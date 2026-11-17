-- blink.cmp source: English words of the word list ('dictionary').
--
-- The list has ~120k words, too many to hand to the fuzzy matcher on each
-- keystroke, so only the words sharing the first two letters of the
-- keyword (case-insensitive) are offered; blink.cmp ranks them.
local M = {}

local buckets = {} -- path -> { [two lowercase letters] = words }

local function load(path)
  if buckets[path] then
    return buckets[path]
  end
  local by_prefix = {}
  local ok, lines = pcall(vim.fn.readfile, path)
  for _, word in ipairs(ok and lines or {}) do
    local key = word:sub(1, 2):lower()
    if #key == 2 then
      by_prefix[key] = by_prefix[key] or {}
      table.insert(by_prefix[key], word)
    end
  end
  buckets[path] = by_prefix
  return by_prefix
end

function M.words_for(path, keyword)
  if #keyword < 2 then
    return {}
  end
  return load(path)[keyword:sub(1, 2):lower()] or {}
end

function M.new(opts)
  return setmetatable({ opts = opts or {} }, { __index = M })
end

function M:get_completions(ctx, callback)
  local kind = require('blink.cmp.types').CompletionItemKind.Text
  local path = self.opts.path or vim.o.dictionary
  local items = vim.tbl_map(function(word)
    return { label = word, kind = kind }
  end, M.words_for(path, ctx.get_keyword()))
  -- the bucket depends only on the first two letters
  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = true })
end

return M
