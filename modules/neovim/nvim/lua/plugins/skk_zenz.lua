-- Context-aware candidate order for skkelua.nvim with a zenz model
-- (Lua port of the llm/ feature of great-cactus/skkeleton feature/llm-zenz).
--
-- On henkanFirst the dictionary candidates are adjusted before they are shown:
--   1. split : an okurinasi reading whose tail may be okurigana or a particle
--              is looked up again ("ながい" -> "なが"+"い" -> 長い)
--   2. rerank: the first K candidates and the split ones are scored by
--              logP(candidate | context, reading) through llama-server's
--              echo+logprobs; the reading itself is scored as a baseline
--   3. fallback: when the reading beats every candidate, or the dictionary
--              has none, zenz generates one candidate greedily
-- Every step has a deadline; on any failure the dictionary order is kept.
local M = {}

M.opts = {
  endpoint = 'http://localhost:8081',
  timeout_ms = 1000,
  fallback = true,
  fallback_timeout_ms = 500,
  context_lines = 5,
  rerank_k = 5,
}

-- zenz v3 prompt markers: [<topic>]<left><right><yomi><output></s>
local MARKER_INPUT = '\u{ee00}'
local MARKER_OUTPUT = '\u{ee01}'
local MARKER_LEFT_CONTEXT = '\u{ee02}'
local MARKER_RIGHT_CONTEXT = '\u{ee07}'
-- Scored with the candidate, else a truncated "濃" ties with "濃い".
local EOS = '</s>'

local LEFT_CONTEXT_MAX_CHARS = 80
local RIGHT_CONTEXT_MAX_CHARS = 40
-- The fallback copies spellings defined in earlier sentences, so it gets a
-- wider left context that is not cut at sentence boundaries.
local FALLBACK_LEFT_CONTEXT_MAX_CHARS = 120
-- zenz-small copies characters from the context; a homophone spelled
-- differently in an earlier sentence would win, so the context is limited to
-- the sentence being converted.
local SENTENCE_BREAK = '[。．！？!?\n]'

local function chars(s)
  return vim.fn.split(s, [[\zs]])
end

local function tail_chars(s, n)
  local cs = chars(s)
  return table.concat(cs, '', math.max(1, #cs - n + 1))
end

local function head_chars(s, n)
  return table.concat(chars(s), '', 1, math.min(n, vim.fn.strchars(s)))
end

local function is_break(c)
  return vim.fn.match(c, SENTENCE_BREAK) == 0
end

local function strip_annotation(c)
  return (c:gsub(';.*$', ''))
end

--- Text after the last sentence break.
function M.last_sentence(s)
  local cs = chars(s)
  for i = #cs, 1, -1 do
    if is_break(cs[i]) then
      return table.concat(cs, '', i + 1)
    end
  end
  return s
end

--- Text up to and including the first sentence break.
function M.first_sentence(s)
  local cs = chars(s)
  for i, c in ipairs(cs) do
    if is_break(c) then
      return table.concat(cs, '', 1, i)
    end
  end
  return s
end

function M.hira_to_kata(s)
  local out = {}
  for _, cp in ipairs(vim.fn.str2list(s)) do
    out[#out + 1] = (cp >= 0x3041 and cp <= 0x3096) and cp + 0x60 or cp
  end
  return vim.fn.list2str(out)
end

function M.build_prefix(before, after, kana, wide_left)
  local left = wide_left and tail_chars((before:gsub('\n', '')), FALLBACK_LEFT_CONTEXT_MAX_CHARS)
    or tail_chars(M.last_sentence(before), LEFT_CONTEXT_MAX_CHARS)
  local right = head_chars(M.first_sentence(after), RIGHT_CONTEXT_MAX_CHARS)
  local right_part = right ~= '' and (MARKER_RIGHT_CONTEXT .. right) or ''
  return MARKER_LEFT_CONTEXT .. left .. right_part .. MARKER_INPUT .. M.hira_to_kata(kana) .. MARKER_OUTPUT
end

--- Context around the cursor; the pre-edit from `marker` ("▽はし") on is
--- removed from the text before the cursor.
---@param lines string[] lines from the first context line to the last
---@param row integer index of the cursor line in `lines`
---@param col integer byte offset of the cursor in that line
function M.extract_context(lines, row, col, marker)
  local line = lines[row] or ''
  local before_cursor, after_cursor = line:sub(1, col), line:sub(col + 1)
  if marker ~= '' then
    local idx = before_cursor:find(marker, 1, true)
    local last
    while idx do
      last = idx
      idx = before_cursor:find(marker, idx + 1, true)
    end
    if last then
      before_cursor = before_cursor:sub(1, last - 1)
    end
  end
  local before = vim.list_slice(lines, 1, row - 1)
  before[#before + 1] = before_cursor
  local after = { after_cursor }
  vim.list_extend(after, vim.list_slice(lines, row + 1))
  return { before = table.concat(before, '\n'), after = table.concat(after, '\n') }
end

function M.buffer_context(marker)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local first = math.max(1, row - M.opts.context_lines)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, row + M.opts.context_lines, false)
  return M.extract_context(lines, row - first + 1, col, marker)
end

-- >>> split
local MAX_TAIL_CHARS = 3
local PER_KEY_LIMIT = 3
local SPLIT_CANDIDATES_LIMIT = 4
local PARTICLES = {}
for _, p in ipairs({ 'か', 'が', 'は', 'を', 'に', 'で', 'と', 'も', 'の', 'へ', 'や', 'ね', 'よ', 'から', 'まで', 'より' }) do
  PARTICLES[p] = true
end

--- Candidates from reading the tail as okurigana or a particle.
---@param lookup fun(type_: string, word: string): string[]
---@param okuri_str fun(stem: string, tail: string): string dictionary key "ながi"
function M.split_candidates(lookup, okuri_str, reading, existing)
  if vim.fn.match(reading, [[^[ぁ-ゖー]\+$]]) ~= 0 then
    return {}
  end
  local cs = chars(reading)
  local seen, out = {}, {}
  for _, c in ipairs(existing) do
    seen[strip_annotation(c)] = true
  end
  local function add(stems, tail)
    for i = 1, math.min(#stems, PER_KEY_LIMIT) do
      local surface = strip_annotation(stems[i]) .. tail
      if not seen[surface] then
        seen[surface] = true
        out[#out + 1] = surface
      end
    end
  end
  for t = 1, math.min(MAX_TAIL_CHARS, #cs - 1) do
    local stem = table.concat(cs, '', 1, #cs - t)
    local tail = table.concat(cs, '', #cs - t + 1)
    if cs[#cs - t + 1] ~= 'っ' or t > 1 then
      local key = okuri_str(stem, tail)
      -- characters that cannot be okurigana (ー) get no romaji letter
      if #key == #stem + 1 and key:match('[a-z]$') then
        add(lookup('okuriari', key), tail)
      end
    end
    if PARTICLES[tail] then
      add(lookup('okurinasi', stem), tail)
    end
  end
  return vim.list_slice(out, 1, SPLIT_CANDIDATES_LIMIT)
end
-- <<< split

-- >>> zenz client
--- POST JSON bodies in parallel; returns the decoded responses (nil for a
--- failed or late one) once all finished or `timeout_ms` passed.
function M.post_all(path, bodies, timeout_ms)
  local results, pending, procs = {}, #bodies, {}
  for i, body in ipairs(bodies) do
    local ok, proc = pcall(vim.system, {
      'curl', '-sS', '--fail', '-m', tostring(timeout_ms / 1000),
      '-H', 'Content-Type: application/json', '--data-binary', '@-',
      M.opts.endpoint .. path,
    }, { stdin = vim.json.encode(body), text = true }, function(res)
      if res.code == 0 then
        local okj, decoded = pcall(vim.json.decode, res.stdout)
        results[i] = okj and decoded or nil
      end
      pending = pending - 1
    end)
    if ok then
      procs[#procs + 1] = proc
    else
      pending = pending - 1
    end
  end
  -- fast_only: skkelua converts under textlock; running scheduled callbacks
  -- here would let them fail with E565
  vim.wait(timeout_ms, function()
    return pending <= 0
  end, 5, true)
  if pending > 0 then
    for _, proc in ipairs(procs) do
      pcall(proc.kill, proc, 'sigterm')
    end
  end
  return results
end

--- Sum of logprobs of the tokens after the prefix ([n_prefix, prompt_tokens)).
function M.suffix_logprob(json, n_prefix)
  local choice = json and json.choices and json.choices[1]
  local lps = choice and choice.logprobs and choice.logprobs.token_logprobs
  local n_prompt = json and json.usage and json.usage.prompt_tokens
  if type(lps) ~= 'table' or type(n_prompt) ~= 'number' or n_prompt <= n_prefix or #lps < n_prompt then
    return nil
  end
  local sum = 0
  for i = n_prefix + 1, n_prompt do
    if type(lps[i]) ~= 'number' then
      return nil
    end
    sum = sum + lps[i]
  end
  return sum
end

--- Score candidates (and optionally the reading as a baseline); returns
--- { value, score, baseline } sorted best first, or {} on failure.
function M.score(prefix, candidates, okuri, baseline_reading)
  local targets = {}
  for _, c in ipairs(candidates) do
    targets[#targets + 1] = { value = c, surface = strip_annotation(c) .. okuri }
  end
  if baseline_reading then
    targets[#targets + 1] = { value = baseline_reading, surface = baseline_reading, baseline = true }
  end
  local bodies = { { content = prefix, add_special = false, parse_special = true } }
  local tokenized = M.post_all('/tokenize', bodies, M.opts.timeout_ms)[1]
  local n_prefix = tokenized and type(tokenized.tokens) == 'table' and #tokenized.tokens
  if not n_prefix then
    return {}
  end
  bodies = vim.tbl_map(function(t)
    return { prompt = prefix .. t.surface .. EOS, max_tokens = 0, echo = true, logprobs = 1, temperature = 0 }
  end, targets)
  local responses = M.post_all('/v1/completions', bodies, M.opts.timeout_ms)
  local scored = {}
  for i, t in ipairs(targets) do
    local sum = M.suffix_logprob(responses[i], n_prefix)
    if not sum then
      return {}
    end
    scored[#scored + 1] = { value = t.value, score = sum, baseline = t.baseline }
  end
  table.sort(scored, function(a, b)
    return a.score > b.score
  end)
  return scored
end

--- Greedy conversion of the reading; returns {} or { candidate }.
function M.generate(prefix, kana, okuri)
  local body = { prompt = prefix, max_tokens = 16, temperature = 0 }
  local json = M.post_all('/v1/completions', { body }, M.opts.fallback_timeout_ms)[1]
  local text = vim.trim(vim.tbl_get(json or {}, 'choices', 1, 'text') or '')
  if text == '' or text == kana then
    return {}
  end
  if okuri ~= '' and vim.endswith(text, okuri) then
    text = text:sub(1, #text - #okuri)
  end
  return text == '' and {} or { text }
end
-- <<< zenz client

--- Final candidate order.
---@param input { type: string, kana: string, okuri: string, candidates: string[], split: boolean, lookup: function, okuri_str: function, context: fun(): {before: string, after: string} }
---@param provider? { score: function, generate: function } defaults to zenz
function M.assist(input, provider)
  provider = provider or M
  local dict = input.candidates
  local split = {}
  if input.split and input.type == 'okurinasi' and #dict > 0 then
    local ok, res = pcall(M.split_candidates, input.lookup, input.okuri_str, input.kana, dict)
    split = ok and res or {}
  end

  local ctx
  local function context()
    ctx = ctx or input.context()
    return ctx
  end
  local function generate()
    local c = context()
    local ok, res = pcall(provider.generate, M.build_prefix(c.before, c.after, input.kana, true), input.kana, input.okuri)
    return ok and res or {}
  end

  if #dict == 0 then
    return M.opts.fallback and generate() or {}
  end

  local k = M.opts.rerank_k
  local to_score = vim.list_extend(vim.list_slice(dict, 1, k), split)
  local order = vim.list_extend(vim.deepcopy(dict), split)
  if #to_score < 2 then
    return order
  end

  local c = context()
  local ok, scored = pcall(provider.score, M.build_prefix(c.before, c.after, input.kana), to_score, input.okuri, input.kana)
  if not ok or #scored == 0 then
    return order
  end
  order = {}
  for _, s in ipairs(scored) do
    if not s.baseline then
      order[#order + 1] = s.value
    end
  end
  vim.list_extend(order, vim.list_slice(dict, k + 1))

  if scored[1].baseline and M.opts.fallback then
    local g = generate()[1]
    if g then
      local rest = vim.tbl_filter(function(x)
        return strip_annotation(x) ~= g
      end, order)
      table.insert(rest, 1, g)
      return rest
    end
  end
  return order
end

--- Hook into skkelua: only the lookup made by henkanFirst is assisted.
--- Must run before require('skkelua').config(), which resolves the kana
--- table entries to these function objects.
function M.install(opts)
  M.opts = vim.tbl_extend('force', M.opts, opts or {})
  local henkan = require('skkelua.function.henkan')
  local Library = require('skkelua.dictionary').Library
  local orig_first, orig_lookup = henkan.henkan_first, Library.get_henkan_result
  local active = false

  henkan.henkan_first = function(...)
    active = true
    local ok, err = pcall(orig_first, ...)
    active = false
    if not ok then
      error(err, 0)
    end
  end

  Library.get_henkan_result = function(self, type_, word)
    local candidates = orig_lookup(self, type_, word)
    if not active then
      return candidates
    end
    active = false -- nested lookups (split) use the plain dictionary
    local state = require('skkelua.store').get_context().state
    local okuri = type_ == 'okuriari' and state.okuriFeed or ''
    local marker = require('skkelua.config').config.markerHenkan
    local ok, res = pcall(M.assist, {
      type = type_,
      kana = (state.henkanFeed or word) .. okuri,
      okuri = okuri,
      candidates = candidates,
      split = state.affix == nil and not state.directInput,
      lookup = function(t, w)
        return orig_lookup(self, t, w)
      end,
      okuri_str = require('skkelua.okuri').get_okuri_str,
      context = function()
        return M.buffer_context(marker)
      end,
    })
    return ok and res or candidates
  end
end

return M
