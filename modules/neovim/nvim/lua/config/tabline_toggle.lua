-- Tabline toggle on tab switch
-- Show tabline only when switching tabs, hide on next action

local M = {}
local hide_autocmd_id = nil

local function hide_tabline()
  vim.opt.showtabline = 0
  if hide_autocmd_id then
    pcall(vim.api.nvim_del_autocmd, hide_autocmd_id)
    hide_autocmd_id = nil
  end
end

local function show_tabline_temporarily()
  vim.opt.showtabline = 2

  if hide_autocmd_id then
    pcall(vim.api.nvim_del_autocmd, hide_autocmd_id)
    hide_autocmd_id = nil
  end

  vim.defer_fn(function()
    hide_autocmd_id = vim.api.nvim_create_autocmd(
      { "CursorMoved", "CursorMovedI", "InsertEnter", "CmdlineEnter", "TextChanged" },
      {
        once = true,
        callback = hide_tabline,
        desc = "Hide tabline after tab switch",
      }
    )
  end, 50)
end

function M.setup()
  vim.opt.showtabline = 0

  vim.keymap.set("n", "<C-n>", function()
    vim.cmd("tabnext")
    show_tabline_temporarily()
  end, { noremap = true, silent = true, desc = "Next tab with tabline preview" })

  vim.keymap.set("n", "<C-p>", function()
    vim.cmd("tabprevious")
    show_tabline_temporarily()
  end, { noremap = true, silent = true, desc = "Previous tab with tabline preview" })
end

return M
