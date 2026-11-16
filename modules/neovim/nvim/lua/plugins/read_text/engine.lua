-- Synthesis/playback pipeline: chunk i+1.. is synthesized while chunk i
-- plays, keeping at most `pipeline_buffer_size` WAV files ready.
local M = {}

local Engine = {}
Engine.__index = Engine

local counter = 0
local function temp_wav(cfg)
  counter = counter + 1
  vim.fn.mkdir(cfg.temp_dir, 'p')
  return ('%s/%s%s_%d_%d.wav'):format(cfg.temp_dir, cfg.file_prefix, cfg.tts_provider, vim.uv.os_getpid(), counter)
end

local function remove(cfg, path)
  if cfg.auto_cleanup then
    vim.uv.fs_unlink(path)
  end
end

--- Lines grouped by `threshold`; blank chunks dropped.
function M.chunks(text, threshold)
  local lines = vim.split(text, '\n', { plain = true })
  local out = {}
  for i = 1, #lines, threshold do
    local chunk = table.concat(lines, '\n', i, math.min(i + threshold - 1, #lines))
    if vim.trim(chunk) ~= '' then
      out[#out + 1] = chunk
    end
  end
  return out
end

---@param provider? table defaults to plugins.read_text.providers
function M.new(cfg, provider)
  return setmetatable({
    cfg = cfg,
    provider = provider or require('plugins.read_text.providers'),
    ready = {},
    next_chunk = 1,
    done = false,
  }, Engine)
end

--- End reading: whatever still runs is killed and its files removed, so
--- an error in one chunk does not leave the previous one playing.
function Engine:finish(err)
  if self.done then
    return
  end
  self.done = true
  if self.synth then
    self.synth.kill()
    self.synth = nil
    vim.uv.fs_unlink(self.synth_path)
  end
  if self.player then
    pcall(self.player.kill, self.player, 'sigcont')
    pcall(self.player.kill, self.player, 'sigterm')
  end
  self.paused = false
  for _, path in ipairs(self.ready) do
    remove(self.cfg, path)
  end
  self.ready = {}
  if self.on_done then
    self.on_done(err)
  end
end

function Engine:fill()
  if self.done or self.synth or self.next_chunk > #self.chunks or #self.ready >= self.cfg.pipeline_buffer_size then
    return
  end
  local text = self.chunks[self.next_chunk]
  self.next_chunk = self.next_chunk + 1
  local path = temp_wav(self.cfg)
  self.synth_path = path
  self.synth = self.provider.synthesize(self.cfg, text, path, self.opts, vim.schedule_wrap(function(err)
    self.synth = nil
    if self.done then
      return vim.uv.fs_unlink(path)
    end
    if err then
      vim.uv.fs_unlink(path)
      return self:finish(err)
    end
    self.ready[#self.ready + 1] = path
    self:play()
    self:fill()
  end)) or nil
end

function Engine:play()
  -- while paused between chunks the next one waits for resume()
  if self.done or self.player or self.paused then
    return
  end
  local path = table.remove(self.ready, 1)
  if not path then
    if not self.synth and self.next_chunk > #self.chunks then
      self:finish(nil)
    end
    return
  end
  local cmd = vim.list_extend(vim.deepcopy(self.cfg.audio_args), { path })
  table.insert(cmd, 1, self.cfg.audio_command)
  -- no pipes: a child left behind by a killed player would hold them open
  -- and delay the exit callback
  local ok, proc = pcall(vim.system, cmd, { stdout = false, stderr = false }, vim.schedule_wrap(function(res)
    self.player = nil
    remove(self.cfg, path)
    if self.done then
      return
    end
    if res.code ~= 0 and res.signal ~= 15 then
      return self:finish(('%s failed (%d)'):format(self.cfg.audio_command, res.code))
    end
    self:play()
    self:fill()
  end))
  if not ok then
    remove(self.cfg, path)
    return self:finish(tostring(proc))
  end
  self.player = proc
  -- a freed buffer slot lets the next chunk synthesize meanwhile
  self:fill()
end

---@param on_done fun(err?: string)
function Engine:start(text, opts, on_done)
  self.opts = opts or {}
  self.on_done = on_done
  if vim.trim(text) == '' then
    return self:finish('Empty text provided')
  end
  self.chunks = M.chunks(text, self.cfg.split_threshold)
  self:fill()
end

function Engine:stop()
  self:finish(nil)
end

--- Pauses the current chunk, or holds the next one while none plays.
function Engine:pause()
  if self.done or self.paused then
    return false
  end
  if self.player and not pcall(self.player.kill, self.player, 'sigstop') then
    return false
  end
  self.paused = true
  return true
end

function Engine:resume()
  if self.done or not self.paused then
    return false
  end
  if self.player and not pcall(self.player.kill, self.player, 'sigcont') then
    return false
  end
  self.paused = false
  self:play()
  return true
end

function Engine:is_paused()
  return self.paused == true
end

function Engine:is_active()
  return not self.done
end

return M
