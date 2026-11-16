-- Text-to-speech providers: each writes one WAV file for a text.
--   synthesize(cfg, text, out_path, opts, done(err)) -> handle with :kill()
--   check(cfg) -> boolean (blocking; :ReadTextCheckConnection only)
local M = {}

local function expand(path)
  return vim.fn.expand(path)
end

--- Run commands one after another; done(err) after the last.
--- spec = { cmd, stdin (string or function evaluated when it starts), after(res) -> err }
local function run_chain(cmds, done)
  local current
  local killed = false
  local function step(i)
    if killed then
      return
    end
    local spec = cmds[i]
    if not spec then
      return done(nil)
    end
    local stdin = type(spec.stdin) == 'function' and spec.stdin() or spec.stdin
    local ok, proc = pcall(vim.system, spec.cmd, { stdin = stdin, text = true }, function(res)
      current = nil
      if killed then
        return
      end
      if res.code ~= 0 then
        local msg = vim.trim(res.stderr or '')
        return done(('%s failed (%d)%s'):format(spec.cmd[1], res.code, msg ~= '' and (': ' .. msg) or ''))
      end
      if spec.after then
        local err = spec.after(res)
        if err then
          return done(err)
        end
      end
      -- out of the luv callback: vim.system needs vim.fn to report a
      -- missing command
      vim.schedule(function()
        step(i + 1)
      end)
    end)
    if not ok then
      return done(tostring(proc))
    end
    current = proc
  end
  step(1)
  return {
    kill = function()
      killed = true
      if current then
        pcall(current.kill, current, 'sigterm')
      end
    end,
  }
end
M._run_chain = run_chain

-- >>> command builders (pure)
function M.kokoro_cmd(cfg, input_path, out_path, opts)
  return {
    cfg.kokoro_command, input_path, out_path,
    '--model', expand(cfg.kokoro_model_path),
    '--voices', expand(cfg.kokoro_voices_path),
    '--lang', cfg.kokoro_lang,
    '--voice', opts.voice or cfg.kokoro_voice,
    '--speed', tostring(opts.speed or cfg.speed),
    '--format', cfg.kokoro_format,
  }
end

function M.espeak_cmd(cfg, text, out_path, opts)
  local voice = opts.voice
  if not voice then
    voice = cfg.espeak_voice
    if cfg.espeak_variant ~= '' then
      voice = voice .. '+' .. cfg.espeak_variant
    end
  end
  local speed = opts.speed or cfg.speed
  local pitch = opts.pitch or cfg.pitch
  -- the text goes on stdin, so one starting with "-" is not an option
  return {
    cfg.espeak_command, '-v', voice,
    '-s', tostring(math.floor(175 * speed + 0.5)),
    '-p', tostring(math.floor(50 + pitch * 49 + 0.5)),
    '-w', out_path, '--stdin',
  }
end

-- The text and settings go in as JSON on stdin, never into the source.
M.melo_script = [=[
import json, sys
from melo.api import TTS
p = json.load(sys.stdin)
model = TTS(language=p["language"], device=p["device"])
ids = model.hps.data.spk2id
sid = ids[p["speaker"]] if p["speaker"] in ids else list(ids.values())[0]
model.tts_to_file(p["text"], sid, p["output"], speed=p["speed"])
]=]

function M.melo_cmd(cfg, text, out_path, opts)
  local speaker = opts.voice or cfg.melo_speaker
  local language = (opts.voice and opts.voice:match('^(%u+)')) or cfg.melo_language
  return { cfg.melo_python, '-c', M.melo_script },
    vim.json.encode({
      language = language,
      speaker = speaker,
      speed = opts.speed or cfg.speed,
      device = cfg.melo_device,
      text = text,
      output = out_path,
    })
end

--- audio_query, then synthesis of that query with speed/pitch set.
function M.voicevox_cmds(cfg, text, out_path, opts)
  local speaker = tostring(opts.voice or cfg.voicevox_speaker)
  local query
  return {
    {
      cmd = {
        'curl', '-sS', '--fail', '-X', 'POST', '-G',
        '--data-urlencode', 'text@-', '--data-urlencode', 'speaker=' .. speaker,
        cfg.voicevox_url .. '/audio_query',
      },
      stdin = text,
      after = function(res)
        local ok, decoded = pcall(vim.json.decode, res.stdout)
        if not ok or type(decoded) ~= 'table' then
          return 'VOICEVOX audio_query returned no query'
        end
        decoded.speedScale = opts.speed or cfg.speed
        decoded.pitchScale = opts.pitch or cfg.pitch
        query = vim.json.encode(decoded)
      end,
    },
    {
      cmd = {
        'curl', '-sS', '--fail', '-X', 'POST', '-H', 'Content-Type: application/json',
        '--data-binary', '@-', '-o', out_path, cfg.voicevox_url .. '/synthesis?speaker=' .. speaker,
      },
      stdin = function()
        return query
      end,
    },
  }
end
-- <<< command builders

function M.synthesize(cfg, text, out_path, opts, done)
  local name = cfg.tts_provider
  if vim.trim(text) == '' then
    return done(name .. ' synthesis failed: Text is empty or contains only whitespace')
  end
  if name == 'kokoro' then
    local input = out_path:gsub('%.wav$', '') .. '.txt'
    vim.fn.writefile(vim.split(text, '\n', { plain = true }), input)
    local handle = run_chain({ { cmd = M.kokoro_cmd(cfg, input, out_path, opts) } }, function(err)
      vim.uv.fs_unlink(input)
      done(err)
    end)
    return {
      kill = function()
        handle.kill()
        vim.uv.fs_unlink(input)
      end,
    }
  elseif name == 'espeak' then
    return run_chain({ { cmd = M.espeak_cmd(cfg, text, out_path, opts), stdin = text } }, done)
  elseif name == 'melo' then
    local cmd, stdin = M.melo_cmd(cfg, text, out_path, opts)
    return run_chain({ { cmd = cmd, stdin = stdin } }, done)
  elseif name == 'voicevox' then
    return run_chain(M.voicevox_cmds(cfg, text, out_path, opts), done)
  end
  return done('Unknown TTS provider: ' .. tostring(name))
end

function M.check(cfg)
  local function ok(cmd)
    local okp, res = pcall(function()
      return vim.system(cmd):wait(5000)
    end)
    return okp and res.code == 0
  end
  local name = cfg.tts_provider
  if name == 'voicevox' then
    return ok({ 'curl', '-sS', '--fail', '-m', '3', cfg.voicevox_url .. '/speakers' })
  elseif name == 'espeak' then
    return ok({ cfg.espeak_command, '--version' })
  elseif name == 'melo' then
    return ok({ cfg.melo_python, '-c', 'from melo.api import TTS' })
  elseif name == 'kokoro' then
    return ok({ cfg.kokoro_command, '--help' })
      and vim.uv.fs_stat(expand(cfg.kokoro_model_path)) ~= nil
      and vim.uv.fs_stat(expand(cfg.kokoro_voices_path)) ~= nil
  end
  return false
end

return M
