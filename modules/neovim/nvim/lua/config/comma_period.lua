-- comma_period.lua
-- 日本語句読点スタイルのトグル（理系方式 ，． ↔ 文系方式 、。）
-- :ToggleCommaPeriod でグローバルに切り替え
-- BufWritePre で対象FileTypeのバッファを自動変換

local M = {}

-- グローバル状態: "humanities" (、。) or "science" (，．)
-- デフォルトは humanities
vim.g.comma_period_style = vim.g.comma_period_style or "humanities"

-- 変換マッピング
local CONVERT = {
  science    = { ["、"] = "，", ["。"] = "．" },
  humanities = { ["，"] = "、", ["．"] = "。" },
}

-- Treesitter: スキップすべきノードタイプ (数式・コード・引用)
local TS_SKIP_NODES = {
  -- LaTeX
  latex_environment = true,  -- \begin{equation}...\end{equation} 等
  math_environment = true,
  inline_formula = true,
  displayed_equation = true,
  text_mode = false,         -- テキストモードは変換対象
  generic_environment = true,
  verbatim_environment = true,
  code_fence_content = true,
  -- Markdown
  fenced_code_block = true,
  indented_code_block = true,
  code_span = true,
  block_quote = true,
  html_block = true,
  -- Typst
  code = true,
  math = true,
  raw_blck = true,
  raw_span = true,
  -- 共通
  source_block = true,
}

-- LaTeX: 数式・verbatim・引用のシンタックスグループ名パターン (synID フォールバック用)
local SYN_SKIP_PATTERNS = {
  "math",
  "Math",
  "verbatim",
  "Verbatim",
  "lstlisting",
  "minted",
  "code",
  "Code",
  "quote",
  "Quote",
  "block_quote",
  "BlockQuote",
}

--- Treesitterで指定位置がスキップ領域かどうか判定
---@param bufnr number
---@param row number 0-indexed
---@param col number 0-indexed
---@return boolean
local function ts_should_skip(bufnr, row, col)
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr, pos = { row, col } })
  if not ok or not node then
    return false
  end
  -- ノード自体とその祖先を辿ってスキップ対象か判定
  local current = node
  while current do
    if TS_SKIP_NODES[current:type()] then
      return true
    end
    current = current:parent()
  end
  return false
end

--- synIDで指定位置がスキップ領域かどうか判定
---@param bufnr number
---@param row number 1-indexed
---@param col number 1-indexed
---@return boolean
local function syn_should_skip(bufnr, row, col)
  -- synID は現在バッファでのみ動作するため、対象バッファに切り替わっている前提
  local syn_id = vim.fn.synID(row, col, 1)
  local syn_name = vim.fn.synIDattr(syn_id, "name")
  local trans_id = vim.fn.synIDtrans(syn_id)
  local trans_name = vim.fn.synIDattr(trans_id, "name")
  for _, pattern in ipairs(SYN_SKIP_PATTERNS) do
    if syn_name:find(pattern) or trans_name:find(pattern) then
      return true
    end
  end
  return false
end

--- 指定位置がスキップ領域かどうか判定 (Treesitter優先、synIDフォールバック)
---@param bufnr number
---@param row number 0-indexed
---@param col number 0-indexed
---@return boolean
local function should_skip(bufnr, row, col)
  -- Treesitter が有効か確認
  if vim.treesitter.highlighter.active[bufnr] then
    return ts_should_skip(bufnr, row, col)
  end
  -- synID フォールバック (1-indexed)
  return syn_should_skip(bufnr, row + 1, col + 1)
end

--- バッファ内の句読点を現在のスタイルに変換
---@param bufnr number
local function convert_buffer(bufnr)
  local style = vim.g.comma_period_style
  local map = CONVERT[style]
  if not map then
    return
  end

  -- 変換対象の文字パターン
  local pattern
  if style == "science" then
    pattern = "[、。]"
  else
    pattern = "[，．]"
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local changed = false

  for i, line in ipairs(lines) do
    local new_line = {}
    local pos = 1
    -- UTF-8 文字単位で走査
    while pos <= #line do
      local byte = line:byte(pos)
      local char_len
      if byte < 0x80 then
        char_len = 1
      elseif byte < 0xE0 then
        char_len = 2
      elseif byte < 0xF0 then
        char_len = 3
      else
        char_len = 4
      end

      local char = line:sub(pos, pos + char_len - 1)

      if char:find(pattern) then
        -- col は 0-indexed バイト位置
        local col = pos - 1
        local row = i - 1
        if should_skip(bufnr, row, col) then
          new_line[#new_line + 1] = char
        else
          new_line[#new_line + 1] = map[char] or char
        end
      else
        new_line[#new_line + 1] = char
      end

      pos = pos + char_len
    end

    local result = table.concat(new_line)
    if result ~= line then
      lines[i] = result
      changed = true
    end
  end

  if changed then
    -- カーソル位置を保存・復元
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    pcall(vim.api.nvim_win_set_cursor, 0, cursor)
  end
end

--- :ToggleCommaPeriod コマンドの実装
local function toggle()
  if vim.g.comma_period_style == "science" then
    vim.g.comma_period_style = "humanities"
  else
    vim.g.comma_period_style = "science"
  end

  -- 現在のバッファを即座に変換
  convert_buffer(vim.api.nvim_get_current_buf())

  -- 通知
  local labels = {
    science    = "理系方式（，．）",
    humanities = "文系方式（、。）",
  }
  vim.notify("句読点: " .. labels[vim.g.comma_period_style], vim.log.levels.INFO)
end

function M.setup()
  vim.api.nvim_create_user_command("ToggleCommaPeriod", toggle, {
    desc = "Toggle Japanese punctuation style (science ，． ↔ humanities 、。)",
  })
end

--- BufWritePre から呼ばれる自動変換エントリポイント
function M.fix_punctuation()
  convert_buffer(vim.api.nvim_get_current_buf())
end

return M
