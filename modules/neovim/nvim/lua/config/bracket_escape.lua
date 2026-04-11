-- bracket-escape.lua
-- Insert modeで <C-l> を押して最も近い括弧の外側にカーソルを移動
-- ユーザー定義の文字ペアもサポート (A:B フォーマット)

local M = {}

-- カスタム文字ペアを解析する関数
local function parse_custom_pairs(custom_pairs)
  local pairs = {}
  
  if not custom_pairs then
    return pairs
  end
  
  for _, pair_str in ipairs(custom_pairs) do
    local open, close = pair_str:match('(.):(.)')
    if open and close then
      pairs[open] = close
      pairs[close] = open
    else
      vim.notify('Invalid pair format: ' .. pair_str .. '. Expected format: A:B', vim.log.levels.WARN)
    end
  end
  
  return pairs
end

-- matchpairsとカスタムペアから括弧のペアを取得する関数
local function get_bracket_pairs(custom_pairs)
  local matchpairs = vim.o.matchpairs
  local bracket_pairs = {}

  -- matchpairsから既存のペアを取得
  for pair in matchpairs:gmatch('[^,]+') do
    local open, close = pair:match('(.):(.)')
    if open and close then
      bracket_pairs[open] = close
      bracket_pairs[close] = open
    end
  end
  
  -- カスタムペアを追加
  local custom = parse_custom_pairs(custom_pairs)
  for open, close in pairs(custom) do
    bracket_pairs[open] = close
  end

  return bracket_pairs
end

-- 最も近い括弧の外側にカーソルを移動する関数
local function move_outside_nearest_bracket(custom_pairs)
  return function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local bracket_pairs = get_bracket_pairs(custom_pairs)

  -- 現在位置の文字をチェック
  local current_char = col < #line and line:sub(col + 1, col + 1) or ''

  -- 現在位置が閉じ括弧の場合、その直後に移動
  if bracket_pairs[current_char] and current_char:match('[%)}%]]') then
    vim.api.nvim_win_set_cursor(0, {row, col + 1})
    return
  end

  -- 現在位置から右側で最初に見つかる閉じ括弧を探す
  for i = col + 1, #line do
    local char = line:sub(i, i)
    if bracket_pairs[char] and char:match('[%)}%]]') then
      vim.api.nvim_win_set_cursor(0, {row, i})
      return
    end
  end
  end
end

-- セットアップ関数
function M.setup(opts)
  opts = opts or {}
  local keymap = opts.keymap or '<C-l>'
  local custom_pairs = opts.custom_pairs

  vim.keymap.set('i', keymap, move_outside_nearest_bracket(custom_pairs), {
    desc = 'Move outside nearest bracket',
    silent = true
  })
end

-- デフォルトでセットアップを実行
M.setup()

return M
