-- plugins/skk_zenz.lua: candidate order with a zenz model
local H = dofile(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/helper.lua')
local Z = require('plugins.skk_zenz')
local defaults = vim.deepcopy(Z.opts)

local function reset()
  Z.opts = vim.deepcopy(defaults)
end

H.test('hira_to_kata converts only hiragana', {
  function()
    H.eq('カンジABCー漢', Z.hira_to_kata('かんじABCー漢'))
    H.eq('ヴ', Z.hira_to_kata('ゔ'))
  end,
})

H.test('last_sentence / first_sentence cut at sentence breaks', {
  function()
    H.eq('川をわたるのは', Z.last_sentence('箸で食べた。川をわたるのは'))
    H.eq('two', Z.last_sentence('one\ntwo'))
    H.eq('no break', Z.last_sentence('no break'))
    H.eq('です。', Z.first_sentence('です。次の文'))
    H.eq('', Z.last_sentence('終わり。'))
  end,
})

H.test('build_prefix: markers, katakana reading, context limits', {
  function()
    local p = Z.build_prefix('前の文。左の文脈', '右の文脈。次', 'はし')
    H.eq('\u{ee02}左の文脈\u{ee07}右の文脈。\u{ee00}ハシ\u{ee01}', p)
    -- no right context -> no right marker
    H.eq('\u{ee02}左\u{ee00}ハシ\u{ee01}', Z.build_prefix('左', '', 'はし'))
    -- left context keeps the last 80 characters
    local long = string.rep('あ', 100)
    local left = Z.build_prefix(long, '', 'か'):match('\u{ee02}(.-)\u{ee00}')
    H.eq(80, vim.fn.strchars(left))
    -- the wide fallback context crosses sentences and drops newlines
    H.eq('\u{ee02}一。二三\u{ee00}カ\u{ee01}', Z.build_prefix('一。\n二三', '', 'か', true))
  end,
})

H.test('extract_context removes the pre-edit and splits at the cursor', {
  function()
    local lines = { '前の行', '川を▽はし', '後の行' }
    local line = lines[2]
    local ctx = Z.extract_context(lines, 2, #line, '▽')
    H.eq('前の行\n川を', ctx.before)
    H.eq('\n後の行', ctx.after)
    -- cursor in the middle; text after it is the right context
    ctx = Z.extract_context({ 'ab▽cdEF' }, 1, #'ab▽cd', '▽')
    H.eq('ab', ctx.before)
    H.eq('EF', ctx.after)
    -- only the last marker counts
    ctx = Z.extract_context({ '▽x▽y' }, 1, #'▽x▽y', '▽')
    H.eq('▽x', ctx.before)
  end,
})

H.test('split_candidates: okurigana and particle splits', {
  function()
    local dict = {
      okuriari = { ['ながi'] = { '長', '永' } },
      okurinasi = { ['きょう'] = { '今日', '京' } },
    }
    local lookup = function(t, w)
      return dict[t][w] or {}
    end
    local okuri_str = function(stem, tail)
      local first = vim.fn.strcharpart(tail, 0, 1)
      local map = { ['い'] = 'i', ['か'] = 'k' }
      return map[first] and (stem .. map[first]) or stem
    end
    H.eq({ '長い', '永い' }, Z.split_candidates(lookup, okuri_str, 'ながい', { '永井' }))
    H.eq({ '今日か', '京か' }, Z.split_candidates(lookup, okuri_str, 'きょうか', {}))
    -- existing surfaces (annotation stripped) are not repeated
    H.eq({ '永い' }, Z.split_candidates(lookup, okuri_str, 'ながい', { '長い;long' }))
    -- non-hiragana readings are not split
    H.eq({}, Z.split_candidates(lookup, okuri_str, 'abc', {}))
  end,
})

H.test('suffix_logprob sums the candidate span and rejects bad responses', {
  function()
    local json = { usage = { prompt_tokens = 4 }, choices = { { logprobs = { token_logprobs = { vim.NIL, -1, -0.5, -0.25 } } } } }
    H.eq(-0.75, Z.suffix_logprob(json, 2))
    H.eq(nil, Z.suffix_logprob(json, 4), 'empty span')
    H.eq(nil, Z.suffix_logprob({}, 1), 'no choices')
    json.choices[1].logprobs.token_logprobs[3] = vim.NIL
    H.eq(nil, Z.suffix_logprob(json, 1), 'missing logprob')
  end,
})

-- Fake provider: scores from a table, generation from a value
local function provider(scores, generated)
  return {
    calls = {},
    score = function(_, cands, _, baseline)
      local out = {}
      for _, c in ipairs(cands) do
        out[#out + 1] = { value = c, score = scores[c] or -99 }
      end
      if baseline and scores[baseline] then
        out[#out + 1] = { value = baseline, score = scores[baseline], baseline = true }
      end
      table.sort(out, function(a, b)
        return a.score > b.score
      end)
      return out
    end,
    generate = function()
      return generated or {}
    end,
  }
end

local function input(over)
  return vim.tbl_extend('force', {
    type = 'okurinasi',
    kana = 'はし',
    okuri = '',
    candidates = { '箸', '橋', '端' },
    split = false,
    lookup = function()
      return {}
    end,
    okuri_str = function(s)
      return s
    end,
    context = function()
      return { before = '川を', after = '' }
    end,
  }, over or {})
end

H.test('assist reranks the first K candidates and keeps the rest', {
  function()
    reset()
    Z.opts.rerank_k = 2
    local res = Z.assist(input({ candidates = { '箸', '橋', '端', '嘴' } }), provider({ ['橋'] = -1, ['箸'] = -3 }))
    H.eq({ '橋', '箸', '端', '嘴' }, res)
  end,
})

H.test('assist keeps the dictionary order when scoring fails', {
  function()
    reset()
    local failing = { score = function() error('down') end, generate = function() return {} end }
    H.eq({ '箸', '橋', '端' }, Z.assist(input(), failing))
    H.eq({ '箸', '橋', '端' }, Z.assist(input(), provider({}, nil) and { score = function() return {} end }))
  end,
})

H.test('assist: reading beats every candidate -> generated one first', {
  function()
    reset()
    local res = Z.assist(input(), provider({ ['はし'] = 0, ['橋'] = -1 }, { '端' }))
    H.eq({ '端', '橋', '箸' }, res)
  end,
})

H.test('assist: no dictionary candidates -> fallback generation', {
  function()
    reset()
    H.eq({ '新語' }, Z.assist(input({ candidates = {} }), provider({}, { '新語' })))
    Z.opts.fallback = false
    H.eq({}, Z.assist(input({ candidates = {} }), provider({}, { '新語' })))
    reset()
  end,
})

H.test('assist: single candidate is not scored', {
  function()
    reset()
    local p = provider({})
    p.score = function()
      error('must not be called')
    end
    H.eq({ '箸' }, Z.assist(input({ candidates = { '箸' } }), p))
  end,
})

H.test('assist: split candidates are scored with the others', {
  function()
    reset()
    local res = Z.assist(input({
      kana = 'ながい',
      candidates = { '永井', '長井' },
      split = true,
      lookup = function(t, w)
        return (t == 'okuriari' and w == 'ながi') and { '長' } or {}
      end,
      okuri_str = function(stem, tail)
        return tail == 'い' and stem .. 'i' or stem
      end,
    }), provider({ ['長い'] = -1, ['永井'] = -5, ['長井'] = -6 }))
    H.eq({ '長い', '永井', '長井' }, res)
  end,
})

-- >>> fake llama-server
local requests = {}
local function serve(handler)
  local server = vim.uv.new_tcp()
  server:bind('127.0.0.1', 0)
  server:listen(16, function()
    local client = vim.uv.new_tcp()
    server:accept(client)
    local buf = ''
    client:read_start(function(_, chunk)
      if not chunk then
        client:close()
        return
      end
      buf = buf .. chunk
      local head, body = buf:match('^(.-)\r\n\r\n(.*)$')
      local len = head and tonumber(head:match('[Cc]ontent%-[Ll]ength: (%d+)'))
      if not len or #body < len then
        return
      end
      local path = head:match('^POST (%S+)')
      -- Everything here runs in the luv callback (no vim.fn, no
      -- vim.schedule): the client waits with vim.wait(fast_only).
      local req = vim.json.decode(body)
      requests[#requests + 1] = { path = path, body = req }
      local status, resp, delay = handler(path, req)
      local function reply()
        local payload = vim.json.encode(resp)
        client:write(('HTTP/1.1 %d OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s'):format(status, #payload, payload))
        client:shutdown(function()
          client:close()
        end)
      end
      if delay then
        local timer = vim.uv.new_timer()
        timer:start(delay, 0, function()
          timer:close()
          reply()
        end)
      else
        reply()
      end
    end)
  end)
  return server, server:getsockname().port
end

-- One token per character; logprob of a character = table value or -5.
local char_lp = { ['橋'] = -0.1, ['箸'] = -3, ['端'] = -2 }
local function utf8_chars(s)
  local out = {}
  for ch in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
    out[#out + 1] = ch
  end
  return out
end
local server, port = serve(function(path, req)
  if path == '/tokenize' then
    return 200, { tokens = utf8_chars(req.content) }
  end
  if req.echo then
    local cps = utf8_chars(req.prompt)
    local lps = { vim.NIL }
    for i = 2, #cps do
      lps[i] = char_lp[cps[i]] or -0.01
    end
    return 200, { usage = { prompt_tokens = #cps }, choices = { { logprobs = { token_logprobs = lps } } } }
  end
  return 200, { choices = { { text = '  端る ' } } }
end)

H.test('score: zenz requests and ranking over HTTP', {
  function()
    reset()
    Z.opts.endpoint = 'http://127.0.0.1:' .. port
    requests = {}
    local scored = Z.score('P', { '箸', '橋', '端;edge' }, '', nil)
    H.eq({ '橋', '端;edge', '箸' }, vim.tbl_map(function(s)
      return s.value
    end, scored))
    H.eq('/tokenize', requests[1].path)
    local prompts = {}
    for _, r in ipairs(requests) do
      if r.body.echo then
        prompts[#prompts + 1] = r.body.prompt
        H.eq(0, r.body.max_tokens)
      end
    end
    table.sort(prompts)
    -- annotations are not scored; EOS is
    H.eq({ 'P橋</s>', 'P端</s>', 'P箸</s>' }, prompts)
  end,
})

H.test('generate: trims, drops the okurigana and the bare reading', {
  function()
    reset()
    Z.opts.endpoint = 'http://127.0.0.1:' .. port
    H.eq({ '端' }, Z.generate('P', 'はしる', 'る'))
    H.eq({}, Z.generate('P', '端る', ''))
  end,
})

H.test('score: a slow server is abandoned at the deadline', {
  function()
    reset()
    local slow, slow_port = serve(function()
      return 200, { tokens = { 1 } }, 2000
    end)
    Z.opts.endpoint = 'http://127.0.0.1:' .. slow_port
    Z.opts.timeout_ms = 200
    local t0 = vim.uv.hrtime()
    H.eq({}, Z.score('P', { 'a', 'b' }, '', nil))
    H.ok((vim.uv.hrtime() - t0) / 1e6 < 1000, 'returned near the deadline')
    slow:close()
    reset()
  end,
})

H.test('score: server down -> {}', {
  function()
    reset()
    Z.opts.endpoint = 'http://127.0.0.1:9'
    H.eq({}, Z.score('P', { 'a', 'b' }, '', nil))
    H.eq({}, Z.generate('P', 'か', ''))
  end,
})
-- <<< fake llama-server

H.test('live zenz server (skipped when not running)', {
  function()
    reset()
    -- the server has one slot: a backlog of earlier requests makes it slow
    local probe = vim.system({
      'curl', '-s', '-o', '/dev/null', '-w', '%{http_code} %{time_total}', '-m', '3',
      '-H', 'Content-Type: application/json', '-d', '{"prompt":"テスト","max_tokens":0,"echo":true,"logprobs":1}',
      Z.opts.endpoint .. '/v1/completions',
    }, { text = true }):wait()
    local code, secs = (probe.stdout or ''):match('^(%d+) ([%d.]+)')
    if code ~= '200' or tonumber(secs) > 0.5 then
      io.stdout:write(('\nSKIP live zenz: server at %s down or busy (%s)\n'):format(Z.opts.endpoint, probe.stdout or ''))
      return
    end
    local t0 = vim.uv.hrtime()
    local scored = Z.score(Z.build_prefix('川にかかる', 'をわたる。', 'はし'), { '箸', '橋', '端' }, '', 'はし')
    local ms = (vim.uv.hrtime() - t0) / 1e6
    H.ok(#scored > 0, ('score failed after %.0fms, opts %s'):format(ms, vim.inspect(Z.opts)))
    local res = Z.assist(input({
      candidates = { '箸', '橋', '端' },
      context = function()
        return { before = '川にかかる', after = 'をわたる。' }
      end,
    }))
    H.eq('橋', res[1], vim.inspect(res))
    res = Z.assist(input({
      context = function()
        return { before = 'ご飯を', after = 'で食べる。' }
      end,
    }))
    H.eq('箸', res[1], vim.inspect(res))
  end,
})

H.test('cleanup', {
  function()
    server:close()
  end,
})

H.run()
