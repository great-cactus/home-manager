-- ==========================================================
-- Smart Scroll with Prefix (sj / sk)
-- ==========================================================
-- Press sj/sk to start, then j/k to continue scrolling.
-- Any other key exits the scroll mode.

local M = {}

-- time_scale: scroll time multiplier
--   > 1.0 = slower (throttle delay = key_repeat * time_scale ms)
--   < 1.0 = faster (lines per press = floor(1 / time_scale))
--   1.0   = base speed
M.time_scale = 1.0
-- key_repeat: base repeat interval in seconds (throttle unit)
M.key_repeat  = 0.05
M.cursor_pos  = 0.25

local last_scroll_ms = 0

local function smart_scroll(direction)
  local now      = vim.uv.now()  -- milliseconds
  local delay_ms = math.floor(M.key_repeat * M.time_scale * 1000)
  if now - last_scroll_ms < delay_ms then return end
  last_scroll_ms = now

  local win_height = vim.api.nvim_win_get_height(0)
  local lines  = math.max(1, math.floor(1 / M.time_scale))
  local offset = math.floor(win_height * M.cursor_pos)

  local move_cmd = direction > 0 and 'j' or 'k'

  vim.cmd('normal! ' .. lines .. move_cmd .. 'zt')
  if offset > 0 then
    vim.cmd('normal! ' .. offset .. '\25') -- \25 = <C-y>
  end
end

function M.setup(opts)
  if opts and opts.time_scale ~= nil then
    M.time_scale = math.max(0.01, opts.time_scale)
  end
  if opts and opts.key_repeat ~= nil then
    M.key_repeat = opts.key_repeat
  end
  if opts and opts.cursor_pos ~= nil then
    M.cursor_pos = opts.cursor_pos
  end

  -- Entry points: sj / sk
  vim.keymap.set('n', 'sj', '<Cmd>lua require("config.smart_scroll").scroll(1)<CR><Plug>(smart-scroll)', { remap = true })
  vim.keymap.set('n', 'sk', '<Cmd>lua require("config.smart_scroll").scroll(-1)<CR><Plug>(smart-scroll)', { remap = true })

  -- Loop: after <Plug>(smart-scroll), j/k continues
  vim.keymap.set('n', '<Plug>(smart-scroll)j', '<Cmd>lua require("config.smart_scroll").scroll(1)<CR><Plug>(smart-scroll)', { remap = true })
  vim.keymap.set('n', '<Plug>(smart-scroll)k', '<Cmd>lua require("config.smart_scroll").scroll(-1)<CR><Plug>(smart-scroll)', { remap = true })

  -- Exit: any other key
  vim.keymap.set('n', '<Plug>(smart-scroll)', '<Nop>', { remap = false })
end

function M.scroll(direction)
  smart_scroll(direction)
end

return M
