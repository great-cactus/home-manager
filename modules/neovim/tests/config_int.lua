-- Integration: the installed configuration (run without --clean).
local H = dofile(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/helper.lua')

local function startup_errors()
  local msgs = vim.api.nvim_exec2('messages', { output = true }).output
  local errs = {}
  for line in msgs:gmatch('[^\n]+') do
    if line:match('^E%d+') or line:match('[Ee]rror') then
      errs[#errs + 1] = line
    end
  end
  return errs
end

local function wait_lsp(name, ms)
  return vim.wait(ms, function()
    return #vim.lsp.get_clients({ bufnr = 0, name = name }) > 0
  end, 50)
end

H.test('no errors after startup and the deferred plugins', {
  function()
    return 1500
  end,
  function()
    H.eq({}, startup_errors())
    H.eq('', vim.v.errmsg)
  end,
})

H.test('conceallevel is 2 once the first redraw is done', {
  function()
    H.eq(2, vim.go.conceallevel, 'global')
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      H.eq(2, vim.wo[win].conceallevel, 'window ' .. win)
    end
  end,
})

H.test('blink.cmp is set up on InsertEnter with the Rust matcher', {
  function()
    H.fresh({ '' })
    H.feed('i', 'nt')
    return 300
  end,
  function()
    H.feed('<Esc>', 'nt')
    H.ok(package.loaded['blink.cmp'], 'blink.cmp loaded')
    H.eq('rust', require('blink.cmp.fuzzy').implementation_type)
    H.eq(false, vim.o.autocomplete, 'builtin autocomplete is off')
    H.eq(1, vim.fn.filereadable(vim.o.dictionary), 'dictionary ' .. vim.o.dictionary)
    H.ok(vim.fn.readfile(vim.o.dictionary, '', 1)[1] ~= nil, 'dictionary is not empty')
  end,
})

H.test('blink.cmp: buffer words in the menu', {
  function()
    H.fresh({ 'blinkword', '' })
    H.feed('Ablin')
    return 500
  end,
  function()
    H.ok(H.in_menu('blinkword', 'buffer'), vim.inspect(H.menu()))
    H.feed('<C-e><Esc>', 'nt')
  end,
})

H.test('blink.cmp: terminal words while typing a command', {
  function()
    vim.cmd('enew! | terminal')
    vim.cmd.startinsert()
    return 1000
  end,
  function()
    H.feed('echo blinkterminalword<CR>')
    return 1000
  end,
  function()
    H.feed('blinkt')
    return 800
  end,
  function()
    local menu = H.menu()
    H.feed('<C-u><C-\\><C-n>', 'nt')
    vim.cmd('bwipeout!')
    H.ok(vim.tbl_contains(menu, 'blinkterminalword buffer'), vim.inspect(menu))
  end,
})

H.test('blink.cmp: cmdline completion on <Tab>', {
  function()
    H.fresh({ '' })
    -- ':' and ';' are swapped in normal mode
    H.feed(';echo<Tab>')
    return 500
  end,
  function()
    local menu = H.menu()
    H.feed('<C-u><Esc>', 'nt')
    H.ok(vim.tbl_contains(menu, 'echo cmdline') or vim.tbl_contains(menu, 'echoerr cmdline'), vim.inspect(menu))
  end,
  function()
    -- the next tests :edit files; the modified scratch buffer would block them
    vim.cmd('enew!')
  end,
})

H.test('ddc and pum.vim are gone', {
  function()
    for _, name in ipairs({ 'ddc.vim', 'pum.vim', 'ddc-ui-pum', 'ddc-source-lsp' }) do
      H.eq(nil, vim.fn['dein#get'](name)[1] and name or next(vim.fn['dein#get'](name)) and name, 'dein entry ' .. name)
    end
    H.eq(0, vim.fn.exists('*ddc#enable'))
  end,
})

H.test('python: lsp items after a trigger character', {
  function()
    local dir = H.tmpdir()
    H.write(dir .. '/m.py', { 'import os', '' })
    vim.cmd.edit(dir .. '/m.py')
    H.ok(wait_lsp('pylsp', 15000), 'pylsp attached')
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    H.feed('Aos.pa')
    return 3000
  end,
  function()
    H.ok(H.in_menu('path', 'lsp'), vim.inspect(H.menu()))
  end,
})

H.test('python: LuaSnip snippets are offered after InsertEnter', {
  function()
    H.feed('<Esc>', 'nt')
    return 50
  end,
  function()
    H.ok(package.loaded.luasnip, 'luasnip loaded on InsertEnter')
    H.feed('o' .. 'ifmain')
    return 500
  end,
  function()
    H.ok(H.in_menu('ifmain', 'snippets'), vim.inspect(H.menu()))
    H.feed('<Esc>', 'nt')
  end,
})

H.test('obsidian: [[ offers vault notes', {
  function()
    local vault = vim.env.OBSIDIAN_PATH
    H.ok(vault and vault ~= '', 'OBSIDIAN_PATH is set')
    local scratch = vault .. '/Output/.claude-completion-test.md'
    H.write(scratch, { '' })
    vim.cmd.edit(scratch)
    H.ok(wait_lsp('obsidian-ls', 15000), 'obsidian-ls attached')
    H.eq({}, startup_errors(), 'messages after opening a vault note')
    local msgs = vim.api.nvim_exec2('messages', { output = true }).output
    H.ok(not msgs:find('conceallevel', 1, true), 'no conceallevel warning: ' .. msgs)
    -- let the vault index finish
    return 8000
  end,
  function()
    -- as typed: blink.cmp misses keys queued with the InsertEnter that loads it
    H.feed('ggA')
    return 300
  end,
  function()
    H.feed('[[Dash')
    return 3000
  end,
  function()
    local found = vim.iter(H.menu()):any(function(entry)
      return entry:find('Dashboard', 1, true) ~= nil
    end)
    H.ok(found, vim.inspect(H.menu()))
    H.feed('<C-e><Esc>', 'nt')
  end,
  function()
    vim.cmd('bwipeout!')
    vim.fn.delete(vim.env.OBSIDIAN_PATH .. '/Output/.claude-completion-test.md')
  end,
})

-- Run a separate Neovim on `file` and return what `probe` (Lua expression)
-- evaluates to after `ms`.
local function probe_startup(file, ms, probe)
  local out = vim.system({
    'nvim', '--headless', file,
    '-c', ('lua vim.defer_fn(function() io.stdout:write(vim.json.encode(%s)) vim.cmd("qa!") end, %d)'):format(probe, ms),
  }, { text = true }):wait(ms + 20000)
  local json = (out.stdout or ''):match('[%[{].*[%]}]')
  return json and vim.json.decode(json) or out.stdout
end

H.test('obsidian: a note given at startup is attached after the first redraw', {
  function()
    local note = vim.env.OBSIDIAN_PATH .. '/Output/.claude-startup-test.md'
    H.write(note, { '# startup', '', 'text' })
    local res = probe_startup(note, 6000, [[{
      buffer = vim.b.obsidian_buffer or false,
      lsp = #vim.lsp.get_clients({ bufnr = 0, name = 'obsidian-ls' }),
      cr = vim.fn.maparg('<CR>', 'n', false, true).buffer or 0,
      conceal = vim.wo.conceallevel,
      msgs = vim.api.nvim_exec2('messages', { output = true }).output,
    }]])
    vim.fn.delete(note)
    H.ok(type(res) == 'table', vim.inspect(res))
    H.eq(true, res.buffer, 'b:obsidian_buffer')
    H.eq(1, res.lsp, 'obsidian-ls attached once')
    H.eq(1, res.cr, 'buffer-local <CR> smart action')
    H.eq(2, res.conceal, 'conceallevel')
    H.ok(not res.msgs:find('rror'), res.msgs)
  end,
})

H.test('skkelua: popup off while SKK is on', {
  function()
    H.fresh({ 'kanji' })
    H.feed('o<C-j>')
    return 500
  end,
  function()
    H.ok(require('skkelua').is_enabled(), 'SKK on')
    H.eq(false, require('config.completion').enabled(), 'blink.cmp off in SKK')
    H.feed('ka')
    return 200
  end,
  function()
    H.eq('か', H.line())
    H.feed('<C-j>')
    return 200
  end,
  function()
    H.ok(not require('skkelua').is_enabled(), 'SKK off')
    H.eq(true, require('config.completion').enabled(), 'blink.cmp back after SKK')
    H.feed('<Esc>', 'nt')
  end,
})

H.test('skkelua: <C-j> in normal mode enters insert with SKK on', {
  function()
    H.fresh({ '' })
    H.feed('<C-j>')
    return 300
  end,
  function()
    H.eq('i', vim.api.nvim_get_mode().mode)
    H.ok(require('skkelua').is_enabled(), 'SKK on')
    H.feed('<C-j><Esc>', 'mt')
  end,
})

H.test('skkelua: dictionaries and the learned words of skkeleton', {
  function()
    vim.fn['dein#source']('skkelua.nvim')
    require('skkelua').initialize()
    local cfg = require('skkelua').get_config()
    H.eq(vim.fn.expand('~/.skkeleton'), cfg.userDictionary)
    H.eq(1, vim.fn.filereadable(cfg.globalDictionaries[1][1]), vim.inspect(cfg.globalDictionaries))
    H.ok(vim.tbl_contains(require('skkelua').get_candidates('かんじ', 'okurinasi'), '漢字'), 'SKK-JISYO.L')
  end,
})

H.test('skkelua: conversion and egg-like newline', {
  function()
    H.fresh({ '' })
    H.feed('A<C-j>Kanji ')
    return 1500
  end,
  function()
    H.ok(H.line():find('▼', 1, true), 'converting: ' .. H.line())
    H.feed('<CR>')
    return 200
  end,
  function()
    H.eq(1, vim.api.nvim_buf_line_count(0), 'Enter only commits')
    H.ok(not H.line():find('▼', 1, true) and not H.line():find('▽', 1, true), H.line())
    H.ok(H.line() ~= '', 'committed text')
    H.feed('<C-j><Esc>', 'mt')
  end,
})

H.test('skkelua: cmdline input', {
  function()
    H.fresh({ '' })
    -- ':' and ';' are swapped in normal mode
    H.feed(';<C-j>ka')
    return 300
  end,
  function()
    local line = vim.fn.getcmdline()
    H.feed('<C-j><C-u><Esc>', 'mt')
    H.eq('か', line)
  end,
})

H.test('skkelua: conversion candidates in the completion menu', {
  function()
    H.fresh({ '' })
    H.feed('A<C-j>Kanji')
    return 1000
  end,
  function()
    local found = vim.iter(H.matches()):any(function(it)
      return it.abbr == '漢字' or it.word:find('漢字', 1, true) ~= nil
    end)
    local items = vim.inspect(vim.tbl_map(function(it)
      return it.abbr
    end, H.matches()))
    H.feed('<C-e><C-g><C-j><Esc>', 'mt')
    H.ok(found, items)
  end,
})

-- zenz picks the homophone that fits the sentence
-- (the cursor is put between `before` and `after`)
local zenz_up
local function zenz_case(before, after, expected)
  return {
    function()
      if zenz_up == nil then
        -- the server has one slot: a backlog of earlier requests makes it slow
        local endpoint = require('plugins.skk_zenz').opts.endpoint
        local res = vim.system({
          'curl', '-s', '-o', '/dev/null', '-w', '%{http_code} %{time_total}', '-m', '3',
          '-H', 'Content-Type: application/json', '-d', '{"prompt":"テスト","max_tokens":0,"echo":true,"logprobs":1}',
          endpoint .. '/v1/completions',
        }, { text = true }):wait()
        local code, secs = (res.stdout or ''):match('^(%d+) ([%d.]+)')
        zenz_up = code == '200' and tonumber(secs) <= 0.5
      end
      if not zenz_up then
        io.stdout:write('\nSKIP zenz server is down or busy\n')
        return
      end
      H.fresh({ before .. after })
      vim.api.nvim_win_set_cursor(0, { 1, #before })
      H.feed('i<C-j>Hashi ')
      return 2500
    end,
    function()
      if not zenz_up then
        return
      end
      local line = H.line()
      H.ok(line:find('▼' .. expected, 1, true), line)
      H.feed('<C-g><C-j><Esc>', 'mt')
      -- let these keys run before the next test moves the cursor
      return 300
    end,
  }
end
H.test('skkelua + zenz: 川にかかる|をわたる。 -> 橋', zenz_case('川にかかる', 'をわたる。', '橋'))
H.test('skkelua + zenz: ご飯を|で食べる。 -> 箸', zenz_case('ご飯を', 'で食べる。', '箸'))
H.test('skkelua + zenz: the dictionary alone puts 箸 and 橋 in one order', {
  function()
    vim.fn['dein#source']('skkelua.nvim')
    require('skkelua').initialize()
    local cands = require('skkelua').get_candidates('はし', 'okurinasi')
    local i, j = vim.fn.index(cands, '橋'), vim.fn.index(cands, '箸')
    H.ok(i >= 0 and j >= 0, vim.inspect(cands))
    -- so one of the two cases above passes only through the zenz order
  end,
})

H.test('migemo: /nihongo finds 日本語 (SKK-JISYO-based dictionary)', {
  function()
    H.fresh({ 'first line', 'これは日本語の文' })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    H.feed('/nihongo<CR>')
    return 300
  end,
  function()
    H.eq({ 2, #'これは' }, vim.api.nvim_win_get_cursor(0))
    H.eq(require('config.migemo_search').dict_path, require('luamigemo').active_dict_path())
    H.eq(0, vim.fn.exists('*kensaku#query'), 'kensaku is gone')
  end,
})

H.test('read_text: configured provider, commands and leader maps', {
  function()
    local rt = require('plugins.read_text')
    H.eq('kokoro', rt.config.tts_provider)
    H.eq('mpv', rt.config.audio_command)
    H.eq(20, rt.config.split_threshold)
    H.eq(2, vim.fn.exists(':ReadFromCursorAsync'))
    H.ok(vim.fn.maparg('<Space>rt', 'n'):find('read%-text%-from%-cursor%-async'), vim.fn.maparg('<Space>rt', 'n'))
    H.ok(vim.fn.maparg('<Space>rt', 'x'):find('read%-text%-selection%-async'), vim.fn.maparg('<Space>rt', 'x'))
    H.ok(not next(vim.fn['dein#get']('read-text.vim')), 'read-text.vim is gone')
  end,
})

H.test('denops and deno are gone', {
  function()
    H.ok(not next(vim.fn['dein#get']('denops.vim')), 'no dein entry')
    H.eq(0, vim.fn.exists('*denops#server#status'))
    H.eq(0, vim.fn.executable('deno'), 'deno is not installed by home-manager')
    local procs = vim.system({ 'pgrep', '-P', tostring(vim.fn.getpid()), '-a' }, { text = true }):wait().stdout or ''
    H.ok(not procs:find('deno'), procs)
  end,
})

H.test('skkeleton is gone', {
  function()
    H.eq(0, vim.fn.exists('*skkeleton#config'))
    H.ok(not next(vim.fn['dein#get']('skkeleton')), 'no dein entry')
  end,
})

H.run()
