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

  -- The word popup of 'autocomplete' would fight the pre-edit; skkelua's
  -- own candidates still come through its in-process LSP.
  local group = vim.api.nvim_create_augroup('SkkCompletion', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'skkelua-enable-pre',
    callback = function()
      vim.b.completion_disabled = true
      vim.bo.autocomplete = false
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'skkelua-disable-post',
    callback = function()
      vim.b.completion_disabled = nil
      vim.bo.autocomplete = vim.bo.buftype == ''
    end,
  })
end

return M
