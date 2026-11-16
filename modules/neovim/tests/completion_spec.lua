-- Native completion (config/completion.lua)
local H = dofile(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/helper.lua')
H.rtp(H.dein .. '/L3MON4D3/LuaSnip')

local cmp = require('config.completion')
cmp.setup()

local dir = H.tmpdir()
H.write(dir .. '/words.txt', { 'xylophone', 'xylograph', 'zebra' })
vim.o.dictionary = dir .. '/words.txt'

local ls = require('luasnip')
ls.add_snippets('all', {
  ls.parser.parse_snippet({ trig = 'fori', desc = 'for loop' }, 'for ${1:i} in ${2:xs} do'),
  ls.parser.parse_snippet({ trig = 'hid', hidden = true }, 'hidden'),
  ls.parser.parse_snippet({ trig = '#inc', desc = 'include' }, '#include <${1:stdio.h}>'),
})

-- Fake server: answers after `delay` ms with items for the typed prefix.
local lsp_delay = 50
local lsp_items = function()
  return {
    { label = 'forLsp', kind = 3 },
    { label = 'fsnip', kind = 15, insertTextFormat = 2, insertText = 'fsnip(${1:arg})$0' },
  }
end
local client = H.fake_lsp({
  trigger_characters = { '#', '[' },
  complete = function(params)
    local items, incomplete = lsp_items(params)
    return items, lsp_delay, incomplete
  end,
})
local function attach()
  vim.lsp.buf_attach_client(0, client)
end

H.test('all sources share one popup, lsp appended when it arrives', {
  function()
    H.fresh({ 'foobar', '' })
    attach()
    H.feed('Af')
    return 300
  end,
  function()
    H.ok(H.has_item('fori', '[LS]'), 'luasnip item: ' .. vim.inspect(H.items()))
    H.ok(H.has_item('foobar'), 'buffer item')
    H.ok(H.has_item('forLsp'), 'lsp item')
  end,
})

H.test('hidden snippets are not offered', {
  function()
    H.fresh({ '' })
    H.feed('Ahi')
    return 100
  end,
  function()
    H.ok(not H.has_item('hid'), vim.inspect(H.items()))
  end,
})

H.test('duplicate word keeps the luasnip item', {
  function()
    H.fresh({ 'fori fori', '' })
    H.feed('Afo')
    return 150
  end,
  function()
    local foris = vim.tbl_filter(function(s)
      return vim.startswith(s, 'fori')
    end, H.items())
    H.eq({ 'fori [LS]' }, foris)
  end,
})

H.test('<C-y> on a luasnip item expands the snippet', {
  function()
    H.fresh({ '' })
    H.feed('Afor')
    return 150
  end,
  function()
    H.ok(H.has_item('fori', '[LS]'), vim.inspect(H.items()))
    -- select the luasnip item explicitly
    local idx
    for i, it in ipairs(H.matches()) do
      if it.menu == '[LS]' then
        idx = i - 1
      end
    end
    vim.api.nvim_select_popupmenu_item(idx, true, false, {})
    return 50
  end,
  function()
    H.feed('<C-y>')
    return 100
  end,
  function()
    H.eq('for i in xs do', H.line())
    H.ok(ls.in_snippet(), 'cursor is in the snippet')
  end,
})

H.test('inserting a luasnip item without <C-y> does not expand it', {
  function()
    H.fresh({ '' })
    H.feed('Afori')
    return 150
  end,
  function()
    H.feed('<Esc>')
    return 50
  end,
  function()
    H.eq('fori', H.line())
  end,
})

H.test('lsp snippet expands with vim.snippet on <C-y>', {
  function()
    H.fresh({ '' })
    attach()
    H.feed('Afsn')
    return 300
  end,
  function()
    local idx
    for i, it in ipairs(H.matches()) do
      if it.word == 'fsnip' then
        idx = i - 1
      end
    end
    H.ok(idx, vim.inspect(H.items()))
    vim.api.nvim_select_popupmenu_item(idx, true, false, {})
    return 50
  end,
  function()
    H.feed('<C-y>')
    return 100
  end,
  function()
    H.eq('fsnip(arg)', H.line())
  end,
})

-- Items shaped like obsidian.nvim's in-process LSP: decorated label, the
-- text only in textEdit/filterText, and always isIncomplete.
local function obsidian_link_items(params)
  local lnum, c = params.position.line, params.position.character
  local before = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]:sub(1, c)
  local start = before:find('%[%[[^%]]*$')
  if not start then
    return {}, true
  end
  local after = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]:sub(c + 1)
  local closing = after:match('^%]%]') and 2 or 0
  local range = {
    start = { line = lnum, character = start - 1 },
    ['end'] = { line = lnum, character = c + closing },
  }
  return {
    { label = 'Alpha', filterText = '[[Alpha', kind = 18, textEdit = { newText = '[[Alpha]]', range = range } },
    { label = 'Beta', filterText = '[[Beta', kind = 18, textEdit = { newText = '[[Beta]]', range = range } },
  }, true
end

local function obsidian_tag_items(params)
  local lnum, c = params.position.line, params.position.character
  local before = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]:sub(1, c)
  local hash = before:find('#[^%s]*$')
  if not hash then
    return {}, true
  end
  local range = { start = { line = lnum, character = hash - 1 }, ['end'] = { line = lnum, character = c } }
  return {
    { label = 'Tag: #PERMANENT', filterText = '#PERMANENT', kind = 14, textEdit = { newText = '#PERMANENT', range = range } },
  }, true
end

H.test('obsidian [[link: textEdit replaces the auto-paired brackets', {
  function()
    lsp_items = obsidian_link_items
    H.fresh({ 'see [[]]' }, { filetype = 'markdown' })
    attach()
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
    -- insert between the brackets
    H.feed('iA')
    return 300
  end,
  function()
    -- the word stops before the "]]" already in the buffer
    H.ok(H.has_item('[[Alpha'), vim.inspect(H.items()))
    H.ok(not H.has_item('[[Beta'), 'filtered by filterText: ' .. vim.inspect(H.items()))
    vim.api.nvim_select_popupmenu_item(H.index_of('[[Alpha'), true, false, {})
    return 50
  end,
  function()
    H.eq('see [[Alpha]]', H.line(), 'while selected')
    H.feed('<C-y>')
    return 150
  end,
  function()
    H.eq('see [[Alpha]]', H.line())
  end,
})

H.test("obsidian #tag: trigger character opens and accepts the tag", {
  function()
    lsp_items = obsidian_tag_items
    H.fresh({ '' }, { filetype = 'markdown' })
    attach()
    H.feed('Atext #')
    return 300
  end,
  function()
    H.ok(H.has_item('#PERMANENT'), vim.inspect(H.items()))
    H.feed('P')
    return 300
  end,
  function()
    H.ok(H.has_item('#PERMANENT'), 'still offered after typing: ' .. vim.inspect(H.items()))
    vim.api.nvim_select_popupmenu_item(H.index_of('#PERMANENT'), true, false, {})
    return 50
  end,
  function()
    H.feed('<C-y>')
    return 150
  end,
  function()
    H.eq('text #PERMANENT', H.line())
  end,
})

H.test('lsp_convert keeps items it cannot improve', {
  function()
    local te = function(newText, s, e, fmt)
      return {
        insertTextFormat = fmt,
        textEdit = { newText = newText, range = { start = { line = 0, character = s }, ['end'] = { line = 0, character = e } } },
      }
    end
    H.fresh({ 'ab]]cd' })
    vim.api.nvim_win_set_cursor(0, { 1, 2 }) -- before "]]"
    H.eq({}, cmp.lsp_convert({ label = 'x' }), 'no textEdit')
    H.eq({}, cmp.lsp_convert(te('abX]]', 0, 2)), 'range ends at the cursor')
    H.eq({ word = 'abX' }, cmp.lsp_convert(te('abX]]', 0, 4)), 'range covers "]]"')
    H.eq({}, cmp.lsp_convert(te('abX', 0, 4)), 'newText does not end with the covered text')
    H.eq({}, cmp.lsp_convert(te('ab]]$0', 0, 4, 2)), 'snippets are left to vim.snippet')
    H.eq({}, cmp.lsp_convert(te(']]', 2, 4)), 'never empties the word')
    local other_line = te('x]]', 0, 4)
    other_line.textEdit.range['end'].line = 1
    H.eq({}, cmp.lsp_convert(other_line), 'range ends on another line')
  end,
})

H.test("lsp_convert shows skkelua's display text", {
  function()
    H.fresh({ '' })
    H.eq({ info = '', abbr = '漢字' }, cmp.lsp_convert({ label = '▽かんじ漢字', data = { display = '漢字' } }))
  end,
})

H.test('lsp_convert counts utf-16 positions on Japanese lines', {
  function()
    H.fresh({ '日本[[]]' })
    vim.api.nvim_win_set_cursor(0, { 1, #'日本[[' })
    -- utf-16: 日本 = 2 units, cursor at 4, "]]" ends at 6
    local item = {
      textEdit = { newText = '[[語]]', range = { start = { line = 0, character = 2 }, ['end'] = { line = 0, character = 6 } } },
    }
    H.eq({ word = '[[語' }, cmp.lsp_convert(item))
  end,
})

H.test('incomplete lsp results are requested again while typing', {
  function()
    lsp_items = function(params)
      local line = vim.api.nvim_buf_get_lines(0, params.position.line, params.position.line + 1, false)[1]
      local prefix = line:sub(1, params.position.character):match('%w*$')
      return { { label = prefix .. 'Tail', kind = 6 } }, true
    end
    H.fresh({ '' })
    attach()
    H.feed('Ab')
    return 200
  end,
  function()
    H.feed('ar')
    return 400
  end,
  function()
    H.ok(H.has_item('barTail'), vim.inspect(H.items()))
  end,
})

H.test('complete lsp results are filtered while typing', {
  function()
    lsp_items = function()
      return { { label = 'barTail', kind = 6 }, { label = 'bazTail', kind = 6 } }, false
    end
    H.fresh({ '' })
    attach()
    H.feed('Ab')
    return 200
  end,
  function()
    H.ok(H.has_item('bazTail'), vim.inspect(H.items()))
    H.feed('ar')
    return 300
  end,
  function()
    H.ok(H.has_item('barTail'), vim.inspect(H.items()))
    H.ok(not H.has_item('bazTail'), vim.inspect(H.items()))
  end,
})

H.test('fuzzy match from buffer words', {
  function()
    H.fresh({ 'foobarbaz', '' })
    H.feed('Afbz')
    return 150
  end,
  function()
    H.ok(H.has_item('foobarbaz'), vim.inspect(H.items()))
  end,
})

H.test('dictionary words', {
  function()
    H.fresh({ '' })
    H.feed('Axylo')
    return 150
  end,
  function()
    H.ok(H.has_item('xylophone'), vim.inspect(H.items()))
  end,
})

H.test('path: absolute directory listing', {
  function()
    H.write(dir .. '/sub/alpha.txt', { 'x' })
    H.write(dir .. '/sub/beta.txt', { 'x' })
    H.fresh({ '' })
    H.feed('A' .. dir .. '/sub/')
    return 200
  end,
  function()
    H.ok(H.has_item(dir .. '/sub/alpha.txt', '[File]'), vim.inspect(H.items()))
    H.ok(H.has_item(dir .. '/sub/beta.txt', '[File]'), vim.inspect(H.items()))
  end,
})

H.test('path: relative to the buffer directory', {
  function()
    H.fresh({ '' })
    vim.cmd.file(dir .. '/sub/note.md')
    H.feed('Asee ./al')
    return 200
  end,
  function()
    H.ok(H.has_item('./alpha.txt', '[File]'), vim.inspect(H.items()))
  end,
})

H.test('path: plain words are not treated as paths', {
  function()
    H.fresh({ '' })
    H.feed('Aalph')
    return 150
  end,
  function()
    for _, it in ipairs(H.matches()) do
      H.ok(it.menu ~= '[File]', vim.inspect(H.items()))
    end
  end,
})

H.test('rg: project words', {
  function()
    local proj = dir .. '/proj'
    H.write(proj .. '/.git/HEAD', { 'ref: refs/heads/main' })
    H.write(proj .. '/a.py', { 'frobnicate_widget = 1', 'frobnicate_other = 2' })
    vim.cmd.cd(proj)
    H.fresh({ '' })
    H.feed('Afrob')
    return 400
  end,
  function()
    H.ok(H.has_item('frobnicate_widget', '[rg]'), vim.inspect(H.items()))
    H.ok(H.has_item('frobnicate_other', '[rg]'), vim.inspect(H.items()))
  end,
})

H.test('rg: needs at least 3 characters', {
  function()
    H.fresh({ '' })
    H.feed('Afr')
    return 200
  end,
  function()
    for _, it in ipairs(H.matches()) do
      H.ok(it.menu ~= '[rg]', vim.inspect(H.items()))
    end
  end,
})

H.test('rg: a slow search is abandoned at the deadline', {
  function()
    cmp.rg_timeout_ms = 1
    H.fresh({ '' })
    local t0 = vim.uv.hrtime()
    local items = cmp.rg(0, 'frob')
    cmp.rg_timeout_ms = 150
    H.ok((vim.uv.hrtime() - t0) / 1e6 < 100, 'returned quickly')
    H.ok(type(items) == 'table')
  end,
})

H.test('<Tab> indents at line start and after a space', {
  function()
    vim.bo.expandtab = false
    H.fresh({ '' })
    H.feed('A<Tab>x <Tab>', 'mtx')
    H.feed('<Esc>', 'nx')
    H.eq('\tx \t', H.line())
  end,
})

H.test('<Tab> selects the next item when the popup is visible', {
  function()
    H.fresh({ 'alpha1 alpha2', '' })
    H.feed('Aalp')
    return 150
  end,
  function()
    H.ok(vim.fn.pumvisible() == 1, 'popup visible')
    H.feed('<Tab>')
    return 50
  end,
  function()
    H.ok(vim.fn.complete_info({ 'selected' }).selected >= 0, 'an item is selected')
  end,
})

H.test('<Tab> jumps inside a vim.snippet session', {
  function()
    H.fresh({ '' })
    H.feed('A', 'nt')
    return 20
  end,
  function()
    vim.snippet.expand('f(${1:a}, ${2:b})')
    return 20
  end,
  function()
    H.feed('<Tab>')
    return 50
  end,
  function()
    H.eq('f(a, b)', H.line())
    H.ok(vim.snippet.active({ direction = -1 }), 'moved to the second tabstop')
    vim.snippet.stop()
  end,
})

H.test('<C-e> closes the popup', {
  function()
    H.fresh({ 'alpha1', '' })
    H.feed('Aalp')
    return 150
  end,
  function()
    H.ok(vim.fn.pumvisible() == 1, 'popup visible')
    H.feed('<C-e>')
    return 50
  end,
  function()
    H.eq(0, vim.fn.pumvisible())
  end,
})

H.test('special buffers get no autocomplete', {
  function()
    H.fresh({ 'alpha1', '' })
    vim.bo.buftype = 'nofile'
    H.feed('Aalp')
    return 150
  end,
  function()
    H.eq(0, vim.fn.pumvisible())
  end,
})

H.test('trigger with a leading non-keyword part: no doubled "#"', {
  function()
    H.fresh({ '' })
    H.feed('A#in')
    return 150
  end,
  function()
    local idx = H.index_of('inc', '[LS]')
    H.ok(idx, vim.inspect(H.items()))
    vim.api.nvim_select_popupmenu_item(idx, true, false, {})
    return 50
  end,
  function()
    H.feed('<C-y>')
    return 100
  end,
  function()
    H.eq('#include <stdio.h>', H.line())
  end,
})

H.test('the leading part of a trigger must already be typed', {
  function()
    H.fresh({ '' })
    H.feed('Ain')
    return 150
  end,
  function()
    H.ok(not H.has_item('inc', '[LS]'), vim.inspect(H.items()))
  end,
})

H.test('<Tab> jumps through a LuaSnip snippet', {
  function()
    H.fresh({ '' })
    H.feed('A', 'nt')
    return 20
  end,
  function()
    ls.snip_expand(ls.get_snippets('all')[1])
    return 50
  end,
  function()
    H.eq('for i in xs do', H.line())
    H.feed('<Tab>')
    return 100
  end,
  function()
    -- the second placeholder "xs" is selected
    H.eq('s', vim.api.nvim_get_mode().mode)
    H.eq({ 1, #'for i in ' }, vim.api.nvim_win_get_cursor(0))
    H.feed('<S-Tab>')
    return 100
  end,
  function()
    H.eq({ 1, #'for ' }, vim.api.nvim_win_get_cursor(0))
    H.feed('<Esc>', 'nt')
    ls.unlink_current()
  end,
})

H.test('lsp_convert uses the UTF-8 offsets of obsidian-ls', {
  function()
    H.fresh({ '日本語 [[ab]] です' })
    local id = H.fake_lsp({ name = 'utf8', offset_encoding = 'utf-8', complete = function() return {}, 0 end })
    vim.lsp.buf_attach_client(0, id)
    vim.api.nvim_win_set_cursor(0, { 1, #'日本語 [[ab' })
    local item = {
      textEdit = { newText = '[[abc]]', range = { start = { line = 0, character = #'日本語 ' }, ['end'] = { line = 0, character = #'日本語 [[ab]]' } } },
    }
    H.eq({ word = '[[abc' }, cmp.lsp_convert(item))
    vim.lsp.stop_client(id, true)
  end,
})

H.run()
