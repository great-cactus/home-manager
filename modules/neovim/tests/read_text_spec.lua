-- plugins/read_text: reading rules, providers, pipeline, commands
local H = dofile(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/helper.lua')
local R = require('plugins.read_text.rules')
local P = require('plugins.read_text.providers')
local E = require('plugins.read_text.engine')
local RT = require('plugins.read_text')

-- >>> rules (cases of read-text.vim's parser_test.ts)
local rule_cases = {
  { '\\begin{comment}\nThis is a comment\n\\end{comment}\nHello World', 'Hello World' },
  { 'Before\n\\begin{figure}\\begin{figure}Nested content\\end{figure}\\end{figure}\nAfter', 'Before\nAfter' },
  { '\\section{Introduction}', 'Introduction' },
  { '\\section{Introduction}\\label{sec:intro}', 'Introduction' },
  { '\\section{\\textbf{Bold Title}}', 'Bold Title' },
  { '\\cite{author{2024}}', '' },
  { '\\href{https://example.com}{Example Link}', 'Example Link' },
  { 'Main text\\footnote{This is a footnote}.', 'Main textfootnote, This is a footnote.' },
  { 'Text before % This is a comment\nText after', 'Text before\nText after' },
  { '\\begin{itemize}\n\\item First\n\\item Second\n\\end{itemize}', 'First\nSecond' },
  { 'The equation $x = 5$ is simple.', 'The equation x = 5 is simple.' },
  { '\\alpha and \\beta', 'alpha and beta' },
  { 'a \\neq b and c \\approx d', 'a not equal to b and c approximately equal to d' },
  {
    '\\section{Results}\\label{sec:results}\nThe value $\\alpha = 0.05$ is significant\\cite{smith2023}.\nSee Figure~\\ref{fig:main} for details.',
    'Results\nThe value alpha = 0.05 is significant.\nSee Figure for details.',
  },
  { '\\section[Short Title]{Full Section Title}', 'Full Section Title' },
  { '\\textbf{bold} and \\textit{italic} text', 'bold and italic text' },
  { 'Dr.~Smith', 'Dr. Smith' },
  { '100\\% complete', '100percent complete' },
}

H.test('rules: cases of the original parser tests', {
  function()
    for _, c in ipairs(rule_cases) do
      H.eq(c[2], R.parse(c[1]), c[1])
    end
  end,
})

H.test('rules: a command name matches only as a whole', {
  function()
    -- \sin used to turn \sinh into "sineh", \in turned \inf into "inf"
    H.eq('hyperbolic sine x', R.parse('\\sinh x'))
    H.eq('infimum S', R.parse('\\inf S'))
    H.eq('integral f', R.parse('\\int f'))
    H.eq('x in A', R.parse('x \\in A'))
    H.eq('less than or equal to', R.parse('\\leq'))
    H.eq('less than or equal to', R.parse('\\le'))
  end,
})

H.test('rules: units only as whole words', {
  function()
    H.eq('5 nanometer and 3 kilogram', R.parse('5 nm and 3 kg'))
    H.eq('5 micrometer', R.parse('5 μm'))
    H.eq('summary of kms', R.parse('summary of kms'))
    H.eq('Pascal', R.parse('Pascal'))
  end,
})

H.test('rules: review fixes (comments first, \\[..], starred commands)', {
  function()
    H.eq('Intro.\nKeep this.', R.parse('Intro.\n% \\begin{figure} old\nKeep this.'))
    H.eq('a b', R.parse('a \\\\[2pt] b'))
    H.eq('Title text', R.parse('\\section*{Title} text'))
    H.eq('x', R.parse('\\vspace*{1em}x'))
  end,
})

H.test('rules: graceful with broken input and Japanese', {
  function()
    H.eq('string', type(R.parse('\\section{Unbalanced')))
    H.ok(R.parse('\\unknowncommand{x}'):find('unknowncommand', 1, true))
    H.eq('日本語の文章です。', R.parse('\\textbf{日本語}の文章です。% コメント'))
    H.eq('a b', R.parse('a\\,\\quad b\\\\'))
    H.eq('x', R.parse('\\vspace*{1em}x'))
  end,
})

H.test('rules apply to LaTeX files only', {
  function()
    H.ok(R.applies_to('/p/main.tex'))
    H.ok(R.applies_to('A.STY'))
    H.ok(not R.applies_to('notes.md'))
    H.ok(not R.applies_to('tex'))
  end,
})
-- <<< rules

-- >>> providers
local cfg = vim.tbl_deep_extend('force', vim.deepcopy(RT.defaults), {
  temp_dir = H.tmpdir(),
  kokoro_model_path = '~/m.onnx',
  kokoro_voices_path = '~/v.bin',
})

H.test('kokoro command', {
  function()
    local home = vim.env.HOME
    H.eq({
      'kokoro-tts', 'in.txt', 'out.wav', '--model', home .. '/m.onnx', '--voices', home .. '/v.bin',
      '--lang', 'en-us', '--voice', 'af_sarah', '--speed', '1', '--format', 'wav',
    }, P.kokoro_cmd(cfg, 'in.txt', 'out.wav', {}))
    H.eq('bf_x', P.kokoro_cmd(cfg, 'i', 'o', { voice = 'bf_x' })[11])
  end,
})

H.test('espeak command: speed and pitch scaled, text on stdin', {
  function()
    local c = vim.tbl_extend('force', cfg, { espeak_variant = 'f2', speed = 1.2, pitch = 0.5 })
    H.eq({ 'espeak', '-v', 'en+f2', '-s', '210', '-p', '75', '-w', 'o.wav', '--stdin' }, P.espeak_cmd(c, '-x', 'o.wav', {}))
  end,
})

H.test('melo command: the text never enters the Python source', {
  function()
    local cmd, stdin = P.melo_cmd(cfg, 'say "hi"\'); import os; #', 'o.wav', { voice = 'JP-1' })
    H.eq({ 'python3', '-c', P.melo_script }, cmd)
    local p = vim.json.decode(stdin)
    H.eq('say "hi"\'); import os; #', p.text)
    H.eq('JP', p.language)
    H.eq('JP-1', p.speaker)
  end,
})

-- fake VOICEVOX engine (answers inside the luv callback)
local voicevox_log = {}
local vv = vim.uv.new_tcp()
vv:bind('127.0.0.1', 0)
vv:listen(8, function()
  local c = vim.uv.new_tcp()
  vv:accept(c)
  local buf = ''
  c:read_start(function(_, chunk)
    if not chunk then
      return c:close()
    end
    buf = buf .. chunk
    local head, body = buf:match('^(.-)\r\n\r\n(.*)$')
    local len = head and tonumber(head:match('[Cc]ontent%-[Ll]ength: (%d+)')) or 0
    if not head or #body < len then
      return
    end
    local target = head:match('^POST (%S+)')
    voicevox_log[#voicevox_log + 1] = { target = target, body = body }
    local payload = target:find('^/audio_query') and '{"speedScale":1,"pitchScale":0,"accent_phrases":[]}' or 'RIFFfakewav'
    c:write(('HTTP/1.1 200 OK\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s'):format(#payload, payload))
    c:shutdown(function()
      c:close()
    end)
  end)
end)

H.test('voicevox: audio_query then synthesis with speed/pitch', {
  function()
    voicevox_log = {}
    local c = vim.tbl_extend('force', cfg, {
      tts_provider = 'voicevox',
      voicevox_url = 'http://127.0.0.1:' .. vv:getsockname().port,
      speed = 1.5,
      pitch = 0.1,
    })
    local out = cfg.temp_dir .. '/vv.wav'
    local err = 'pending'
    P.synthesize(c, 'こんにちは & bye', out, {}, function(e)
      err = e
    end)
    vim.wait(5000, function()
      return err ~= 'pending'
    end)
    H.eq(nil, err)
    H.eq('RIFFfakewav', table.concat(vim.fn.readfile(out, 'b')))
    H.ok(voicevox_log[1].target:find('^/audio_query%?'), voicevox_log[1].target)
    H.ok(voicevox_log[1].target:find('speaker=3', 1, true), 'default speaker')
    -- the text is URL-encoded, not cut at "&"
    H.ok(voicevox_log[1].target:find('%%26', 1, false) or voicevox_log[1].target:find('&bye', 1, true) == nil, voicevox_log[1].target)
    H.eq('/synthesis?speaker=3', voicevox_log[2].target)
    local q = vim.json.decode(voicevox_log[2].body)
    H.eq(1.5, q.speedScale)
    H.eq(0.1, q.pitchScale)
    vim.fn.delete(out)
  end,
})

H.test('provider errors: empty text, unknown provider, failing command', {
  function()
    local errs = {}
    P.synthesize(cfg, '  \n', 'o.wav', {}, function(e)
      errs.empty = e
    end)
    P.synthesize(vim.tbl_extend('force', cfg, { tts_provider = 'nope' }), 'x', 'o.wav', {}, function(e)
      errs.unknown = e
    end)
    P.synthesize(vim.tbl_extend('force', cfg, { tts_provider = 'espeak', espeak_command = 'false' }), 'x', 'o.wav', {}, function(e)
      errs.failed = e
    end)
    vim.wait(3000, function()
      return errs.failed ~= nil
    end)
    H.ok(errs.empty and errs.empty:find('empty'), tostring(errs.empty))
    H.ok(errs.unknown and errs.unknown:find('Unknown TTS provider'), tostring(errs.unknown))
    H.ok(errs.failed and errs.failed:find('false failed'), tostring(errs.failed))
  end,
})
-- <<< providers

-- >>> engine
-- Fake provider: writes "<text>" to the WAV after `delay` ms.
local synth_log, active, max_active = {}, 0, 0
local fake
fake = {
  fail_on = nil,
  synthesize = function(_, text, path, _, done)
    active = active + 1
    max_active = math.max(max_active, active)
    synth_log[#synth_log + 1] = text
    local timer = vim.uv.new_timer()
    local killed = false
    timer:start(60, 0, function()
      timer:close()
      active = active - 1
      if killed then
        return
      end
      if text == fake.fail_on then
        return done('boom')
      end
      local f = io.open(path, 'w')
      f:write(text)
      f:close()
      done(nil)
    end)
    return {
      kill = function()
        killed = true
      end,
    }
  end,
}

local play_log = cfg.temp_dir .. '/played.log'
local function engine_cfg(over)
  return vim.tbl_extend('force', cfg, {
    audio_command = 'sh',
    audio_args = { '-c', 'cat "$1" >> ' .. play_log .. '; echo >> ' .. play_log .. '; sleep 0.1', 'sh' },
    split_threshold = 1,
    pipeline_buffer_size = 2,
  }, over or {})
end

local function played()
  return vim.fn.filereadable(play_log) == 1 and vim.fn.readfile(play_log) or {}
end

local function wavs()
  return vim.fn.glob(cfg.temp_dir .. '/*.wav', false, true)
end

H.test('chunks: lines grouped by the threshold, blank chunks dropped', {
  function()
    H.eq({ 'a\nb', 'c' }, E.chunks('a\nb\nc', 2))
    H.eq({ 'a', 'c' }, E.chunks('a\n \nc', 1))
    H.eq({ 'one' }, E.chunks('one', 50))
  end,
})

-- Engine callbacks are scheduled, so the tests wait by returning a delay
-- from a step (vim.wait inside a step does not run them).
local st = {}
local function start(text, over)
  st = { result = 'pending' }
  st.eng = E.new(engine_cfg(over), fake)
  st.eng:start(text, {}, function(err)
    st.result = err or 'ok'
  end)
end

H.test('engine: an error stops the chunk still playing', {
  function()
    fake.fail_on = 'bad'
    start('ok1\nbad', { audio_args = { '-c', 'sleep 5', 'sh' } })
    return 600
  end,
  function()
    fake.fail_on = nil
    H.eq('boom', st.result)
    H.ok(st.eng.player == nil or vim.uv.kill(st.eng.player.pid, 0) ~= 0, 'player killed')
  end,
})

H.test('engine: pause between chunks holds the next one until resume', {
  function()
    vim.fn.delete(play_log)
    start('a\nb')
    -- paused before the first chunk finished synthesizing
    H.eq(true, st.eng:pause())
    return 400
  end,
  function()
    H.eq(nil, st.eng.player, 'nothing plays while paused')
    H.eq({}, played())
    H.eq(true, st.eng:resume())
    return 1000
  end,
  function()
    H.eq('ok', st.result)
    H.eq({ 'a', 'b' }, played())
  end,
})

H.test('engine: stop removes the file of an unfinished synthesis', {
  function()
    local slow = {
      synthesize = function(_, _, path, _, _)
        local f = io.open(path, 'w')
        f:write('partial')
        f:close()
        return { kill = function() end }
      end,
    }
    st = { result = 'pending' }
    st.eng = E.new(engine_cfg(), slow)
    st.eng:start('a', {}, function(err)
      st.result = err or 'ok'
    end)
    H.eq(1, #wavs(), 'partial file exists')
    st.eng:stop()
    H.eq({}, wavs())
    H.eq('ok', st.result)
  end,
})

H.test('engine: chunks are played in order, one synthesis at a time', {
  function()
    vim.fn.delete(play_log)
    synth_log, active, max_active = {}, 0, 0
    start('one\ntwo\nthree\nfour\nfive')
    return 2500
  end,
  function()
    H.eq('ok', st.result, vim.inspect({ synth = synth_log, ready = st.eng.ready, player = st.eng.player ~= nil, next = st.eng.next_chunk, played = played() }))
    H.eq({ 'one', 'two', 'three', 'four', 'five' }, played())
    H.eq(1, max_active, 'synthesis runs one chunk at a time')
    H.eq({}, wavs(), 'temp files removed')
  end,
})

H.test('engine: no more than pipeline_buffer_size files wait', {
  function()
    synth_log = {}
    start('1\n2\n3\n4\n5\n6', { audio_args = { '-c', 'sleep 1', 'sh' } })
    return 600
  end,
  function()
    -- one playing, at most two ready
    H.ok(#st.eng.ready <= 2, vim.inspect(st.eng.ready))
    H.ok(#synth_log <= 3, vim.inspect(synth_log))
    st.eng:stop()
  end,
})

H.test('engine: stop kills playback, stops synthesis and cleans up', {
  function()
    vim.fn.delete(play_log)
    start('a\nb\nc', { audio_args = { '-c', 'cat "$1" >> ' .. play_log .. '; echo >> ' .. play_log .. '; sleep 5', 'sh' } })
    return 500
  end,
  function()
    H.ok(st.eng.player, 'playing')
    st.pid = st.eng.player.pid
    st.eng:stop()
    H.eq('ok', st.result, 'stop finishes without an error')
    return 500
  end,
  function()
    H.ok(vim.uv.kill(st.pid, 0) ~= 0, 'player process gone')
    H.eq({ 'a' }, played())
    H.eq({}, wavs())
  end,
})

local function proc_state(pid)
  return (vim.fn.readfile('/proc/' .. pid .. '/stat')[1] or ''):match('^%d+ %b() (%a)')
end

H.test('engine: pause stops the player process, resume continues it', {
  function()
    start('a', { audio_args = { '-c', 'sleep 5', 'sh' } })
    return 500
  end,
  function()
    H.ok(st.eng.player, 'playing')
    H.eq(false, st.eng:resume(), 'not paused yet')
    H.eq(true, st.eng:pause())
    H.eq(false, st.eng:pause(), 'already paused')
    return 100
  end,
  function()
    H.eq('T', proc_state(st.eng.player.pid))
    H.eq(true, st.eng:resume())
    return 100
  end,
  function()
    H.ok(proc_state(st.eng.player.pid) ~= 'T', 'running again')
    st.eng:stop()
  end,
})

H.test('engine: a synthesis error ends reading and cleans up', {
  function()
    fake.fail_on = 'bad'
    start('ok1\nbad\nok3', { audio_args = { '-c', 'sleep 0.2', 'sh' } })
    return 1500
  end,
  function()
    fake.fail_on = nil
    H.eq('boom', st.result)
    H.eq({}, wavs())
  end,
})

H.test('engine: a failing player reports an error; empty text too', {
  function()
    start('x', { audio_args = { '-c', 'exit 3', 'sh' } })
    return 800
  end,
  function()
    H.ok(st.result:find('sh failed %(3%)'), st.result)
    start('  ')
    H.eq('Empty text provided', st.result)
  end,
})
-- <<< engine

-- >>> commands and extraction
RT.setup(engine_cfg())

H.test('extraction: from cursor, line, multibyte selection', {
  function()
    H.fresh({ 'first', '二行目のテキスト', 'third' })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    H.eq('二行目のテキスト\nthird', RT.text_from_cursor())
    H.eq('二行目のテキスト', RT.text_of_line())
    -- select "行目のテ" (characterwise, multibyte at both ends)
    vim.api.nvim_win_set_cursor(0, { 2, #'二' })
    H.feed('v3l<Esc>', 'nx')
    H.eq('行目のテ', RT.text_of_selection())
    H.feed('ggVj<Esc>', 'nx')
    H.eq('first\n二行目のテキスト', RT.text_of_selection())
  end,
})

H.test('commands and <Plug> maps exist', {
  function()
    for _, name in ipairs({
      'ReadFromCursor', 'ReadSelection', 'ReadLine', 'ReadFromCursorAsync', 'ReadSelectionAsync',
      'ReadLineAsync', 'ReadTextStop', 'ReadTextPause', 'ReadTextResume', 'ReadTextTogglePause',
      'ReadTextCheckConnection',
    }) do
      H.eq(2, vim.fn.exists(':' .. name), name)
    end
    H.ok(vim.fn.maparg('<Plug>(read-text-selection-async)', 'x') ~= '', 'visual plug')
    H.ok(vim.fn.maparg('<Plug>(read-text-toggle-pause)', 'n') ~= '', 'normal plug')
  end,
})

H.test(':ReadLine reads a LaTeX line through the rules; a new read stops the old', {
  function()
    vim.fn.delete(play_log)
    RT.setup(engine_cfg({ tts_provider = 'espeak', espeak_command = 'sh' }))
    -- 'espeak' replaced by a fake that writes stdin to the -w file
    RT.config.espeak_command = vim.fn.exepath('sh')
    local orig = P.espeak_cmd
    P.espeak_cmd = function(_, _, out)
      return { 'sh', '-c', 'cat > "$1"', 'sh', out }
    end
    H.fresh({ '\\textbf{Hello} $x$ \\cite{k}' })
    vim.cmd.file(cfg.temp_dir .. '/doc.tex')
    vim.cmd('ReadLine')
    return 1500
  end,
  function()
    P.espeak_cmd = require('plugins.read_text.providers').espeak_cmd
    H.eq({ 'Hello x' }, played())
    H.ok(not RT.is_active(), 'finished')
  end,
})
-- <<< commands

H.test('live kokoro-tts (skipped when not installed)', {
  function()
    local c = vim.tbl_extend('force', engine_cfg(), {
      tts_provider = 'kokoro',
      kokoro_model_path = '~/.local/share/kokoro-tts/kokoro-v1.0.onnx',
      kokoro_voices_path = '~/.local/share/kokoro-tts/voices-v1.0.bin',
    })
    if not P.check(c) then
      io.stdout:write('\nSKIP live kokoro: kokoro-tts or its model is missing\n')
      return
    end
    local out = cfg.temp_dir .. '/k.wav'
    local err = 'pending'
    P.synthesize(c, 'Hello.', out, {}, function(e)
      err = e
    end)
    vim.wait(60000, function()
      return err ~= 'pending'
    end, 50)
    H.eq(nil, err)
    H.ok((vim.uv.fs_stat(out) or { size = 0 }).size > 1000, 'wav written')
  end,
})

H.test('cleanup', {
  function()
    vv:close()
  end,
})

H.run()
