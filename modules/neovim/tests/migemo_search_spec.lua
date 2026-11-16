-- config/migemo_search.lua: romaji search with luamigemo
local H = dofile(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/helper.lua')
H.rtp(H.dein .. '/delphinus/luamigemo')

local S = require('config.migemo_search')
S.setup()

local function matches(pattern, text)
  return vim.fn.match(text, pattern) >= 0
end

H.test('convert: romaji query becomes a migemo regex', {
  function()
    local q = S.convert('kensaku')
    H.ok(q and vim.startswith(q, '\\m'), tostring(q))
    H.ok(matches(q, 'これは検索です'), q)
    H.ok(matches(q, 'けんさく'), 'hiragana')
    H.ok(matches(q, 'ケンサク'), 'katakana')
    H.ok(matches(q, 'kensaku'), 'the romaji itself')
  end,
})

H.test('convert: non-romaji queries are left alone', {
  function()
    H.eq(nil, S.convert('foo_bar'))
    H.eq(nil, S.convert('test'))
    H.eq(nil, S.convert('a.*b'))
    H.eq(nil, S.convert(''))
  end,
})

H.test('convert: a leading flag is kept', {
  function()
    local q = S.convert('\\cnihongo')
    H.ok(vim.startswith(q, '\\c\\m'), q)
    H.ok(matches(q, '日本語'), q)
  end,
})

H.test('/ search finds Japanese with romaji', {
  function()
    H.fresh({ 'first line', 'これは検索のテスト' })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    H.feed('/kensaku<CR>')
    return 100
  end,
  function()
    H.eq({ 2, #'これは' }, vim.api.nvim_win_get_cursor(0))
  end,
})

H.test('? search backwards', {
  function()
    H.fresh({ '日本語の文', 'last line' })
    H.feed('?nihongo<CR>')
    return 100
  end,
  function()
    H.eq({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
  end,
})

H.test('buffers without Japanese search the plain text', {
  function()
    H.fresh({ 'alpha', 'kensaku here' })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    H.feed('/kensaku<CR>')
    return 100
  end,
  function()
    H.eq({ 2, 0 }, vim.api.nvim_win_get_cursor(0))
    H.eq('kensaku', vim.fn.getreg('/'))
  end,
})

H.test(': command line <CR> is untouched', {
  function()
    H.fresh({ '検索' })
    vim.g.migemo_test = nil
    H.feed(':let g:migemo_test = "kensaku"<CR>')
    return 100
  end,
  function()
    H.eq('kensaku', vim.g.migemo_test)
  end,
})

H.test('search offsets and regexes are not converted', {
  function()
    H.fresh({ '検索', 'kensaku/e' })
    H.eq(nil, S.convert('kensaku/e'))
    H.eq(nil, S.convert('ken.saku'))
  end,
})

H.test('<CR> with the cursor inside the query converts all of it', {
  function()
    H.fresh({ 'first line', 'これは検索のテスト' })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    H.feed('/kensaku<Left><Left><CR>')
    return 100
  end,
  function()
    H.eq({ 2, #'これは' }, vim.api.nvim_win_get_cursor(0))
  end,
})

H.run()
