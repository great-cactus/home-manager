-- Completion with blink.cmp (config/completion.lua and its sources)
local H = dofile(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/helper.lua')
H.rtp(H.dein .. '/L3MON4D3/LuaSnip', H.blink)

local dir = H.tmpdir()
H.write(dir .. '/words.txt', { 'Xylem', 'xylograph', 'xylophone', 'zebra' })
vim.o.dictionary = dir .. '/words.txt'

local ls = require('luasnip')
ls.add_snippets('all', {
  ls.parser.parse_snippet({ trig = 'fori', desc = 'for loop' }, 'for ${1:i} in ${2:xs} do'),
})

local cmp = require('config.completion')
cmp.setup()
local blink = require('blink.cmp')

-- Fake server: answers after `lsp_delay` ms with lsp_items(params).
local lsp_delay = 30
local lsp_items = function()
  return { { label = 'forLsp', kind = 3 } }
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

local function menu()
  return vim.inspect(H.menu())
end

-- >>> ranking
H.test('every source shares one menu', {
  function()
    H.fresh({ 'foobar', '' })
    attach()
    H.feed('Afo')
    return 300
  end,
  function()
    H.ok(H.in_menu('fori', 'snippets'), menu())
    H.ok(H.in_menu('foobar', 'buffer'), menu())
    H.ok(H.in_menu('forLsp', 'lsp'), menu())
  end,
})

H.test('one fuzzy score ranks the items of all sources', {
  function()
    lsp_items = function()
      return { { label = 'fxbxzxqux', kind = 6 }, { label = 'fbzLsp', kind = 6 } }
    end
    H.fresh({ 'foobarbaz fbzword', '' })
    attach()
    H.feed('Afbz')
    return 300
  end,
  function()
    -- a contiguous match beats a scattered one whatever the source
    local lsp_best, buffer_best = H.rank('fbzLsp', 'lsp'), H.rank('fbzword', 'buffer')
    local scattered = H.rank('fxbxzxqux', 'lsp')
    H.ok(lsp_best and buffer_best and scattered, menu())
    H.ok(lsp_best < scattered and buffer_best < scattered, menu())
    H.ok(H.rank('foobarbaz', 'buffer'), 'fuzzy match from buffer words: ' .. menu())
  end,
})

H.test('path items come first after a "/"', {
  function()
    H.write(dir .. '/sub/alpha.txt', { 'x' })
    H.write(dir .. '/sub/alps.txt', { 'x' })
    H.fresh({ 'alpine alpaca', '' })
    H.feed('A' .. dir .. '/sub/al')
    return 300
  end,
  function()
    H.ok(H.rank('alpha.txt', 'path') == 1 or H.rank('alps.txt', 'path') == 1, menu())
  end,
})

H.test('path: relative to the buffer directory', {
  function()
    H.fresh({ '' })
    vim.cmd.file(dir .. '/sub/note.md')
    H.feed('Asee ./al')
    return 300
  end,
  function()
    H.ok(H.in_menu('alpha.txt', 'path'), menu())
  end,
})
-- <<< ranking

-- >>> dict
H.test('dict: English words with at least 3 characters', {
  function()
    H.fresh({ '' })
    H.feed('Axyl')
    return 200
  end,
  function()
    H.ok(H.in_menu('xylophone', 'dict'), menu())
    H.ok(H.in_menu('Xylem', 'dict'), 'case-insensitive: ' .. menu())
    H.ok(not H.in_menu('zebra', 'dict'), menu())
  end,
})

H.test('dict: words of the same first two letters', {
  function()
    local dict = require('config.completion_dict')
    H.eq({ 'Xylem', 'xylograph', 'xylophone' }, dict.words_for(dir .. '/words.txt', 'XYlo'))
    H.eq({}, dict.words_for(dir .. '/words.txt', 'q'))
    H.eq({}, dict.words_for(dir .. '/missing.txt', 'xyl'))
  end,
})
-- <<< dict

-- >>> rg
local proj = dir .. '/proj'
H.write(proj .. '/.git/HEAD', { 'ref: refs/heads/main' })
H.write(proj .. '/a.py', { 'frobnicate_widget = 1', 'frobnicate_other = 2' })

H.test('rg: project words', {
  function()
    vim.cmd.cd(proj)
    H.fresh({ '' })
    H.feed('Afrob')
    return 500
  end,
  function()
    H.ok(H.in_menu('frobnicate_widget', 'rg'), menu())
    H.ok(H.in_menu('frobnicate_other', 'rg'), menu())
  end,
})

H.test('rg: needs at least 3 characters', {
  function()
    H.fresh({ '' })
    H.feed('Afr')
    return 300
  end,
  function()
    H.ok(not H.in_menu('frobnicate_widget', 'rg'), menu())
  end,
})

H.test('rg: no search outside a project or on a Windows mount', {
  function()
    local rg = require('config.completion_rg')
    H.eq(proj, rg.root(proj))
    H.eq(nil, rg.root('/mnt/c/Users/x'))
    H.eq(nil, rg.root(vim.env.HOME))
    H.eq(nil, rg.root('/'))
  end,
})

H.test('rg: cancelling kills the search', {
  function()
    local rg = require('config.completion_rg').new({})
    local cancel = rg:get_completions({ get_keyword = function() return 'frob' end }, function() end)
    H.ok(type(cancel) == 'function', 'returns a cancel function')
    cancel()
    return 300
  end,
})
-- <<< rg

-- >>> lsp
H.test("skkelua's own client is left to SKK mode", {
  function()
    H.fresh({ '' })
    local skk = H.fake_lsp({ name = 'skkelua', complete = function() return { { label = 'fooSkk', kind = 1 } }, 0 end })
    vim.lsp.buf_attach_client(0, skk)
    lsp_items = function()
      return { { label = 'fooLsp', kind = 6 } }
    end
    attach()
    H.feed('Afoo')
    return 300
  end,
  function()
    H.ok(H.in_menu('fooLsp', 'lsp'), menu())
    H.ok(not H.in_menu('fooSkk', 'lsp'), menu())
    for _, c in ipairs(vim.lsp.get_clients({ name = 'skkelua' })) do
      c:stop(true)
    end
    H.feed('<Esc>', 'nt')
    -- a stopping client would leave the next requests unanswered
    vim.wait(1000, function()
      return #vim.lsp.get_clients({ name = 'skkelua' }) == 0
    end)
  end,
})

H.test('obsidian [[link: textEdit replaces the auto-paired brackets', {
  function()
    lsp_items = function(params)
      local lnum, c = params.position.line, params.position.character
      local line = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]
      local start = line:sub(1, c):find('%[%[[^%]]*$')
      if not start then
        return {}, true
      end
      local closing = line:sub(c + 1):match('^%]%]') and 2 or 0
      local range = { start = { line = lnum, character = start - 1 }, ['end'] = { line = lnum, character = c + closing } }
      return { { label = 'Alpha', filterText = '[[Alpha', kind = 18, textEdit = { newText = '[[Alpha]]', range = range } } }, true
    end
    H.fresh({ 'see [[]]' }, { filetype = 'markdown' })
    attach()
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
    H.feed('iA')
    return 300
  end,
  function()
    H.ok(H.in_menu('Alpha', 'lsp'), menu())
    H.feed('<Tab><C-y>')
    return 200
  end,
  function()
    H.eq('see [[Alpha]]', H.line())
  end,
})
-- <<< lsp

-- >>> keymap
H.test('<Tab> indents at line start and after a space', {
  function()
    vim.bo.expandtab = false
    H.fresh({ '' })
    H.feed('A<Tab>x <Tab>', 'mtx')
    H.feed('<Esc>', 'nx')
    H.eq('\tx \t', H.line())
  end,
})

H.test('<Tab> selects and inserts the next item, <C-y> accepts it', {
  function()
    lsp_items = function()
      return {}
    end
    H.fresh({ 'alpha1', '' })
    H.feed('Aalp')
    return 200
  end,
  function()
    H.ok(blink.is_menu_visible(), 'menu visible')
    H.eq(nil, blink.get_selected_item(), 'nothing preselected')
    H.feed('<Tab>')
    return 100
  end,
  function()
    H.eq('alpha1', H.line(), 'inserted on select')
    H.feed('<C-y>')
    return 100
  end,
  function()
    H.ok(not blink.is_menu_visible(), 'menu closed')
    H.eq('alpha1', H.line())
  end,
})

H.test('<C-y> with nothing selected only closes the menu', {
  function()
    H.fresh({ 'alpha1', '' })
    H.feed('Aalp')
    return 200
  end,
  function()
    H.ok(blink.is_menu_visible(), 'menu visible')
    H.feed('<C-y>')
    return 100
  end,
  function()
    H.ok(not blink.is_menu_visible(), 'menu closed')
    H.eq('alp', H.line())
  end,
})

H.test('<C-e> closes the menu', {
  function()
    H.fresh({ 'alpha1', '' })
    H.feed('Aalp')
    return 200
  end,
  function()
    H.ok(blink.is_menu_visible(), 'menu visible')
    H.feed('<C-e>')
    return 100
  end,
  function()
    H.ok(not blink.is_menu_visible())
    H.eq('alp', H.line())
  end,
})

H.test('<Tab> opens the menu after a word', {
  function()
    H.fresh({ 'alpha1', '' })
    H.feed('Aal', 'nt')
    return 50
  end,
  function()
    blink.hide()
    H.feed('<Tab>')
    return 200
  end,
  function()
    H.ok(blink.is_menu_visible(), 'menu visible')
  end,
})

H.test('<C-y> on a snippet item expands it', {
  function()
    H.fresh({ '' })
    H.feed('Afori')
    return 200
  end,
  function()
    H.ok(H.in_menu('fori', 'snippets'), menu())
    local idx = H.rank('fori', 'snippets')
    blink.select_next({ count = idx })
    return 50
  end,
  function()
    H.feed('<C-y>')
    return 150
  end,
  function()
    H.eq('for i in xs do', H.line())
    H.ok(ls.in_snippet(), 'cursor is in the snippet')
    H.feed('<Esc>', 'nt')
    ls.unlink_current()
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
    blink.hide()
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
-- <<< keymap

-- >>> enabled
H.test('special buffers and SKK mode get no menu', {
  function()
    H.fresh({ 'alpha1', '' })
    vim.bo.buftype = 'nofile'
    H.eq(false, cmp.enabled(), 'nofile buffer')
    vim.bo.buftype = ''
    H.eq(true, cmp.enabled(), 'normal buffer')
    vim.b.completion_disabled = true
    H.eq(false, cmp.enabled(), 'SKK on')
    vim.b.completion_disabled = nil
  end,
})

H.test('cmdline and terminal completion are on', {
  function()
    local config = require('blink.cmp.config')
    H.ok(config.cmdline.enabled, 'cmdline')
    H.ok(config.term.enabled, 'term')
    H.eq({ 'select_next', 'fallback' }, config.term.keymap['<Tab>'], "terminal <Tab> falls back to the shell's")
  end,
})

H.test("terminal paths are relative to the shell's directory", {
  function()
    H.fresh({ '' })
    H.eq(vim.fn.expand('%:p:h'), cmp.cwd({ bufnr = vim.api.nvim_get_current_buf() }), 'file buffer')
    -- :terminal replaces the current buffer, which must be unmodified
    vim.cmd('enew! | terminal')
    return 200
  end,
  function()
    local buf = vim.api.nvim_get_current_buf()
    local expected = vim.uv.fs_readlink('/proc/' .. vim.b[buf].terminal_job_pid .. '/cwd') or vim.fn.getcwd()
    H.eq(expected, cmp.cwd({ bufnr = buf }))
    vim.cmd('bwipeout!')
  end,
})
-- <<< enabled

H.run()
