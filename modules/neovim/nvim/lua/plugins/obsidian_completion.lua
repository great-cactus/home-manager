-- Freeze-free [[link]] / #tag completion for obsidian.nvim on a slow vault FS.
--
-- Cause: obsidian.nvim's tag and note sources read and parse every candidate
-- note with Note.from_file on the main thread (inside rg's stdout callback).
-- On a WSL /mnt/c (9p) mount one file read costs ~40ms, so a #tag request
-- blocks Neovim for minutes over ~2000 notes.
--
--   1. Prevent : a vault index built by ripgrep in child processes
--                (file names, frontmatter aliases/tags, inline #tags).
--                The main thread only parses rg output, a chunk per tick.
--                find_workspace matches roots lexically (no realpath per link).
--   2. Deadline: every completion request is answered within DEADLINE_MS;
--                late results are dropped.
--   3. Abort   : a debug-hook watchdog aborts synchronous Lua that exceeds
--                BUDGET_MS, so a runaway handler cannot freeze the editor.
--   4. Reset   : :ObsidianCompletionReset kills jobs and rebuilds the index.
local M = {}

local DEADLINE_MS = 2500
local BUDGET_MS = 1500
local RG_TIMEOUT_MS = 60000
local PARSE_CHUNK = 200
local MAX_LOADED_NOTES = 10
-- Edits made outside Neovim (e.g. the Obsidian app) fire no BufWritePost
local INDEX_TTL_MS = 5 * 60 * 1000

local EMPTY = { isIncomplete = true, items = {} }

local function warn(msg)
  vim.schedule(function()
    vim.notify("obsidian-completion: " .. msg, vim.log.levels.WARN)
  end)
end

--------------------------------------------------------------------------------
-- Watchdog: abort synchronous Lua exceeding a time budget.
-- JIT-compiled traces never call hooks, so the JIT is off while guarded.
--------------------------------------------------------------------------------
local guard_depth = 0

-- Stack marker: the hook raises only while this frame is live (no tail call).
local function sentinel(fn, ...)
  local result = { fn(...) }
  return unpack(result)
end

local function guarded(budget_ms, fn, ...)
  if guard_depth > 0 then
    return pcall(fn, ...)
  end
  local deadline = vim.uv.hrtime() + budget_ms * 1e6
  local prev_hook = { debug.gethook() }
  guard_depth = 1
  jit.off()
  jit.flush()
  -- Keep raising until the stack unwinds to our pcall, even through the
  -- plugin's own pcalls; never raise outside the guarded call.
  debug.sethook(function()
    if vim.uv.hrtime() <= deadline then
      return
    end
    for level = 2, math.huge do
      local info = debug.getinfo(level, "f")
      if not info then
        break
      elseif info.func == sentinel then
        error("aborted after " .. budget_ms .. "ms", 0)
      end
    end
    debug.sethook()
  end, "", 100)
  local result = { pcall(sentinel, fn, ...) }
  debug.sethook(unpack(prev_hook))
  jit.on()
  guard_depth = 0
  return unpack(result)
end

--------------------------------------------------------------------------------
-- Vault index
--------------------------------------------------------------------------------
-- notes: { [abs_path] = { stem, aliases } }, tags: { [normalized] = { name, count } }
local index = { notes = {}, tags = {}, ready = false, stale = true, building = false, jobs = {}, waiters = {}, gen = 0, built_at = 0 }

local function vault_dir()
  return vim.fs.normalize(tostring(Obsidian.dir))
end

local function rg_base()
  local args = { "rg", "--no-config", "--type-add", "md:*.qmd", "--type=md" }
  local templates = Obsidian.opts.templates and Obsidian.opts.templates.folder
  if templates then
    args[#args + 1] = "-g!" .. templates
  end
  return args
end

local function unquote(text)
  return vim.trim(text):gsub([[^(["'])(.*)%1$]], "%2")
end

-- Values of the top-level `tags` / `aliases` keys in a frontmatter block.
-- Handles `key: [a, b]`, `key: a` and block lists (`- a`); this is all the
-- index needs, and is ~100x faster than a full YAML parse per note.
local function frontmatter_lists(text)
  local lists, key = { tags = {}, aliases = {} }, nil
  for line in vim.gsplit(text, "\r?\n") do
    local k, rest = line:match("^([%w_]+):%s*(.-)%s*$")
    if k then
      key = lists[k:lower()] and k:lower() or nil
      if key and rest ~= "" then
        local inline = rest:match("^%[(.*)%]$")
        for item in vim.gsplit(inline or rest, inline and "," or "\n", { plain = true }) do
          lists[key][#lists[key] + 1] = unquote(item)
        end
      end
    elseif key then
      local item = line:match("^%s*%-%s+(.-)%s*$")
      if item then
        lists[key][#lists[key] + 1] = unquote(item)
      end
    end
  end
  return lists
end

local function add_tag(tags, name)
  name = tostring(name):gsub("^#", "")
  -- Obsidian rejects purely numeric tags
  if name == "" or name:find("%s") or not name:find("%D") then
    return
  end
  local key = name:lower()
  local entry = tags[key]
  if entry then
    entry.count = entry.count + 1
  else
    tags[key] = { name = name, count = 1 }
  end
end

-- Process `items` PARSE_CHUNK at a time, yielding to the event loop between chunks.
local function each_chunked(items, fn, done, gen)
  local i = 1
  local function step()
    if gen ~= index.gen then
      return
    end
    local last = math.min(i + PARSE_CHUNK - 1, #items)
    for j = i, last do
      pcall(fn, items[j])
    end
    i = last + 1
    if i <= #items then
      vim.schedule(step)
    else
      done()
    end
  end
  vim.schedule(step)
end

local function parse_frontmatter(notes, tags)
  return function(line)
    local data = vim.json.decode(line)
    if data.type ~= "match" then
      return
    end
    local note = notes[vim.fs.normalize(vim.fs.joinpath(vault_dir(), data.data.path.text))]
    if not note then
      return
    end
    local lists = frontmatter_lists(data.data.lines.text)
    for _, alias in ipairs(lists.aliases) do
      if alias ~= "" then
        note.aliases[#note.aliases + 1] = alias
      end
    end
    for _, tag in ipairs(lists.tags) do
      add_tag(tags, tag)
    end
  end
end

local function finish_build(gen, notes, tags)
  if gen ~= index.gen then
    return
  end
  index.notes, index.tags = notes, tags
  index.ready, index.building, index.jobs = true, false, {}
  index.built_at = vim.uv.now()
  local waiters = index.waiters
  index.waiters = {}
  for _, cb in ipairs(waiters) do
    local ok, err = guarded(BUDGET_MS, cb)
    if not ok then
      warn(tostring(err))
    end
  end
end

-- Run rg jobs in parallel; on_all receives { [name] = stdout } once all exit.
local function run_jobs(gen, specs, on_all)
  local outputs, pending = {}, vim.tbl_count(specs)
  for name, args in pairs(specs) do
    local ok, job = pcall(vim.system, args, { cwd = vault_dir(), text = true, timeout = RG_TIMEOUT_MS }, function(obj)
      -- rg: 0 = matches, 1 = none, 2 = partial I/O error (e.g. NAME_MAX on /mnt/c)
      if gen == index.gen and (obj.code > 2 or obj.signal ~= 0) then
        warn(("rg (%s) failed: code=%d signal=%d"):format(name, obj.code, obj.signal))
      end
      outputs[name] = obj.stdout or ""
      pending = pending - 1
      if pending == 0 then
        vim.schedule(function()
          if gen == index.gen then
            on_all(outputs)
          end
        end)
      end
    end)
    if ok then
      index.jobs[#index.jobs + 1] = job
    else
      warn("cannot start rg: " .. tostring(job))
      outputs[name], pending = "", pending - 1
    end
  end
end

function M.build()
  if index.building then
    return
  end
  index.building, index.stale = true, false
  local gen = index.gen
  local base = rg_base()
  run_jobs(gen, {
    files = vim.list_extend(vim.deepcopy(base), { "--files" }),
    frontmatter = vim.list_extend(vim.deepcopy(base), { "--json", "-U", "-e", [[\A---\r?\n(?s:.*?)\r?\n---]] }),
    inline = vim.list_extend(vim.deepcopy(base), {
      "-o", "-N", "--no-filename", "-r", "$1",
      "-e", [[(?:^|\s)#([\p{L}\p{N}_/-]*[\p{L}_/-][\p{L}\p{N}_/-]*)]],
    }),
  }, function(out)
    local notes, tags = {}, {}
    for rel in vim.gsplit(out.files, "\n", { trimempty = true }) do
      local path = vim.fs.normalize(vim.fs.joinpath(vault_dir(), rel))
      notes[path] = { stem = vim.fn.fnamemodify(path, ":t:r"), aliases = {} }
    end
    local lines = vim.split(out.frontmatter, "\n", { trimempty = true })
    each_chunked(lines, parse_frontmatter(notes, tags), function()
      for tag in vim.gsplit(out.inline, "\n", { trimempty = true }) do
        add_tag(tags, tag)
      end
      finish_build(gen, notes, tags)
    end, gen)
  end)
end

-- Call cb once the index is usable; stale data is served while it rebuilds.
local function with_index(cb)
  if index.stale or vim.uv.now() - index.built_at > INDEX_TTL_MS then
    M.build()
  end
  if index.ready then
    cb()
  else
    index.waiters[#index.waiters + 1] = cb
  end
end

function M.reset()
  index.gen = index.gen + 1
  for _, job in ipairs(index.jobs) do
    pcall(job.kill, job, "sigkill")
  end
  index.notes, index.tags, index.jobs, index.waiters = {}, {}, {}, {}
  index.ready, index.building, index.stale = false, false, true
  M.build()
  vim.notify("obsidian-completion: index reset, rebuilding")
end

--------------------------------------------------------------------------------
-- Sources
--------------------------------------------------------------------------------
-- Drop-in for obsidian.completion.sources.tags.process_completion.
local function tag_completion(callback, request)
  local can_complete, term, in_frontmatter = require("obsidian.completion.tags").can_complete(request)
  if not (can_complete and term and #term >= Obsidian.opts.completion.min_chars) then
    return callback(EMPTY)
  end
  local query = term:gsub("^#", ""):lower()
  local cursor_before = request.cursor_before_line
  local hash_start = cursor_before:find("#[^%s]*$")
  local _, dash_end = cursor_before:find("%-%s")
  local insert_start = hash_start and (hash_start - 1) or dash_end or (#cursor_before - #term)
  local range = {
    start = { line = request.line, character = insert_start },
    ["end"] = { line = request.line, character = #cursor_before },
  }

  with_index(function()
    local items = {}
    for key, tag in pairs(index.tags) do
      if vim.startswith(key, query) then
        local text = in_frontmatter and tag.name or "#" .. tag.name
        items[#items + 1] = {
          label = "Tag: " .. text,
          sortText = tag.name,
          filterText = hash_start and "#" .. tag.name or tag.name,
          kind = vim.lsp.protocol.CompletionItemKind.Keyword,
          documentation = {
            kind = "markdown",
            value = ("`#%s` — %d occurrence%s"):format(tag.name, tag.count, tag.count == 1 and "" or "s"),
          },
          textEdit = { newText = text, range = range },
        }
      end
    end
    callback({ isIncomplete = true, items = items })
  end)
end

local function note_matches(note, needle)
  if needle == "" or note.stem:lower():find(needle, 1, true) then
    return true
  end
  for _, alias in ipairs(note.aliases) do
    if alias:lower():find(needle, 1, true) then
      return true
    end
  end
  return false
end

-- Index-backed stand-in for search.find_notes_async, used only while the refs
-- source runs. Names/aliases are matched instead of grepping note contents.
-- Contents are loaded only when headings/blocks are needed, for a few notes.
local function fast_find_notes(term, callback, opts)
  opts = opts or {}
  local note_opts = opts.notes or {}
  local needs_contents = note_opts.collect_anchor_links or note_opts.collect_blocks or note_opts.collect_sections
  local dir = opts.dir and vim.fs.normalize(tostring(opts.dir)) or vault_dir()
  local needle = (term or ""):lower()
  local Note = require("obsidian.note")

  with_index(function()
    local paths = {}
    for path, note in pairs(index.notes) do
      if vim.startswith(path, dir) and note_matches(note, needle) then
        paths[#paths + 1] = path
      end
    end
    table.sort(paths)
    if needs_contents and #paths > MAX_LOADED_NOTES then
      warn(("%d notes match; narrow the query to list headings/blocks"):format(#paths))
      return callback({})
    end
    local results = {}
    for _, path in ipairs(paths) do
      if needs_contents then
        local ok, note = pcall(Note.from_file, path, vim.tbl_extend("force", { max_lines = 2147483647 }, note_opts))
        if ok then
          results[#results + 1] = note
        end
      else
        results[#results + 1] = Note.new(nil, vim.deepcopy(index.notes[path].aliases), {}, path)
      end
    end
    callback(results)
  end)
end

--------------------------------------------------------------------------------
-- Wiring
--------------------------------------------------------------------------------
-- find_workspace realpath()s its argument; on /mnt/c that is ~400ms and the
-- refs source calls it for every candidate link. Match workspace roots
-- lexically first; only paths outside every root (e.g. via a symlink) fall
-- back to the realpath-based original.
local function lexical_find_workspace()
  local api = require("obsidian.api")
  local fs_util = require("obsidian.util.fs")
  local orig = api.find_workspace
  api.find_workspace = function(path)
    local normalized = vim.fs.normalize(tostring(path))
    local match, match_len = nil, -1
    for _, ws in ipairs(Obsidian.workspaces or {}) do
      local root = vim.fs.normalize(tostring(ws.root))
      if #root > match_len and fs_util.is_subpath(normalized, root) then
        match, match_len = ws, #root
      end
    end
    return match or orig(path)
  end
end

local function patch_sources()
  lexical_find_workspace()
  require("obsidian.completion.sources.tags").process_completion = tag_completion

  local refs = require("obsidian.completion.sources.refs")
  local search = require("obsidian.search")
  local orig_refs = refs.process_completion
  -- The refs source calls find_notes_async synchronously, so the swap is scoped.
  refs.process_completion = function(...)
    local orig_find = search.find_notes_async
    search.find_notes_async = fast_find_notes
    local result = { pcall(orig_refs, ...) }
    search.find_notes_async = orig_find
    if not result[1] then
      error(result[2], 0)
    end
    return unpack(result, 2)
  end
end

-- Answer every completion request within DEADLINE_MS, abort runaway handlers.
local function patch_handler()
  local handlers = require("obsidian.lsp.handlers")
  local orig = handlers["textDocument/completion"]
  handlers["textDocument/completion"] = function(params, callback, ...)
    local answered = false
    local timer = vim.uv.new_timer()
    local function respond(err, result)
      if answered then
        return
      end
      answered = true
      timer:stop()
      timer:close()
      callback(err, result)
    end
    -- The loop clock is stale after a long synchronous stretch
    vim.uv.update_time()
    timer:start(DEADLINE_MS, 0, vim.schedule_wrap(function()
      respond(nil, EMPTY)
    end))
    -- Answers delivered later by index waiters are guarded in finish_build.
    local ok, err = guarded(BUDGET_MS, orig, params, respond, ...)
    if not ok then
      warn(tostring(err))
      respond(nil, EMPTY)
    end
  end
end

function M.setup()
  patch_sources()
  patch_handler()

  local group = vim.api.nvim_create_augroup("ObsidianCompletionIndex", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.md",
    callback = function(args)
      if vim.startswith(vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf)), vault_dir()) then
        index.stale = true
      end
    end,
  })
  vim.api.nvim_create_user_command("ObsidianCompletionReset", M.reset, {
    desc = "Kill obsidian completion jobs and rebuild the vault index",
  })

  M.build()
end

M._index = index

return M
