-- ==========================================================
-- Smart Scroll with Prefix (sj / sk)
-- ==========================================================
-- Press sj/sk to start, then j/k to continue scrolling.
-- Any other key exits the scroll mode.

local M = {}

local function smart_scroll(direction)
  local win_height = vim.api.nvim_win_get_height(0)
  local offset = math.floor(win_height / 4)

  local move_cmd = direction > 0 and 'j' or 'k'

  vim.cmd('normal! ' .. move_cmd .. 'zt')
  if offset > 0 then
    vim.cmd('normal! ' .. offset .. '\25') -- \25 = <C-y>
  end
end

function M.setup()
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
