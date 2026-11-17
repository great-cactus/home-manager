-- SKK input with skkelua.nvim (replaces denops-based skkeleton).
local M = {}

local dict_dir = vim.fn.expand('~/.cache/dein/repos/github.com/skk-dev/dict')

function M.setup()
  -- Before config(): it resolves the kana table to henkanFirst.
  require('plugins.skk_zenz').install({
    -- localhost, not 127.0.0.1: the server may listen on ::1 only
    endpoint = 'http://localhost:8081',
    timeout_ms = 1000,
    fallback = true,
    fallback_timeout_ms = 500,
    context_lines = 5,
    rerank_k = 5,
  })

  require('skkelua').config({
    globalDictionaries = { dict_dir .. '/SKK-JISYO.L' },
    sources = { 'skk_dictionary', 'google_japanese_input' },
    -- words learned with skkeleton
    userDictionary = vim.fn.expand('~/.skkeleton'),
    completionRankFile = vim.fs.joinpath(vim.fn.stdpath('state'), 'skkelua', 'rank'),
    completion = { enabled = true },
    registerConvertResult = true,
    eggLikeNewline = true,
  })

  -- The blink.cmp menu would fight the pre-edit (config.completion checks
  -- b:completion_disabled); skkelua's own candidates still come through its
  -- in-process LSP and the builtin popup.
  local group = vim.api.nvim_create_augroup('SkkCompletion', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'skkelua-enable-pre',
    callback = function()
      vim.b.completion_disabled = true
      local blink = package.loaded['blink.cmp']
      if blink then
        blink.hide()
      end
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'skkelua-disable-post',
    callback = function()
      vim.b.completion_disabled = nil
    end,
  })
end

return M
