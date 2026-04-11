-- one_sentence_per_line.lua (nvim >= 0.11)
-- 使い方:
--   対象行をビジュアル選択 → :'<,'>OneSentPerLine   (確認あり)
--                          → :'<,'>OneSentPerLine!  (一括)

local M = {}

local ABBREVS = vim.iter({
  "e.g", "i.e", "etc", "vs", "cf", "al",
  "dr", "mr", "mrs", "ms", "prof", "jr", "sr",
  "fig", "eq", "ref", "vol", "no", "rev", "ed",
  "approx", "resp", "incl", "dept",
}):fold({}, function(t, a)
  t[a] = true
  return t
end)

--- $...$ をプレースホルダーに退避し、分割判定から保護する
local function protect_math(text)
  local store = {}
  local protected = text:gsub("%$(.-)%$", function(inner)
    store[#store + 1] = "$" .. inner .. "$"
    return ("\x01%d\x01"):format(#store)
  end)
  return protected, store
end

local function restore_math(text, store)
  return (text:gsub("\x01(%d+)\x01", function(n)
    return store[tonumber(n)]
  end))
end

--- 文境界の候補位置を収集する
--- 判定: ピリオド + 閉じ記号* + 空白+ + 大文字、かつ直前の単語が略語でない
local function collect_splits(text)
  local splits, pos = {}, 1
  while true do
    local s, e, closing, spaces = text:find("%.([\"')%]]*)([~ ]+)%u", pos)
    if not s then break end
    local word = (text:sub(1, s - 1):match("(%S+)$") or ""):lower()
    if not ABBREVS[word] then
      local sp_start = s + 1 + #closing
      local sp_end = sp_start + #spaces - 1
      splits[#splits + 1] = { from = sp_start, to = sp_end }
    end
    pos = e
  end
  return splits
end

local function one_sentence_per_line(line1, line2, confirm)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  local text = vim.trim(table.concat(lines, " "):gsub("%s+", " "))

  local store
  text, store = protect_math(text)
  local splits = collect_splits(text)

  -- 後ろから置換（インデックスずれ防止）
  for i = #splits, 1, -1 do
    local sp = splits[i]
    if confirm then
      local ctx = ("…%s «HERE» %s…  (%d/%d)"):format(
        text:sub(math.max(1, sp.from - 40), sp.from - 1),
        text:sub(sp.to + 1, math.min(#text, sp.to + 40)),
        #splits - i + 1, #splits
      )
      local choice = vim.fn.confirm(ctx, "&Yes\n&No\n&All\n&Abort", 1)
      if choice == 2 then goto continue end
      if choice == 3 then confirm = false end
      if choice == 4 or choice == 0 then break end
    end
    text = text:sub(1, sp.from - 1) .. "\n" .. text:sub(sp.to + 1)
    ::continue::
  end

  text = restore_math(text, store)
  local new_lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(0, line1 - 1, line2, false, new_lines)
  vim.notify(("%d行 → %d文に整形"):format(line2 - line1 + 1, #new_lines))
end

function M.setup()
  vim.api.nvim_create_user_command("OneSentPerLine", function(opts)
    one_sentence_per_line(opts.line1, opts.line2, not opts.bang)
  end, { range = true, bang = true })
end

return M
