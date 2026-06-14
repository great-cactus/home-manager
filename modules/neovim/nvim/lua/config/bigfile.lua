-- Large file optimization
-- Disables heavy features (treesitter, foldexpr, LSP, matchparen, etc.)
-- when a file exceeds the size/line-length threshold.

local M = {}

local defaults = {
  size = 1.5 * 1024 * 1024,  -- 1.5 MB
  line_length = 1000,         -- average chars/line (catches minified files)
}

function M.setup(opts)
  opts = vim.tbl_deep_extend('force', defaults, opts or {})

  -- Detect big files via vim.filetype.add (runs before FileType)
  vim.filetype.add({
    pattern = {
      ['.*'] = {
        function(path, buf)
          if not path or not buf or vim.bo[buf].filetype == 'bigfile' then
            return
          end
          local size = vim.fn.getfsize(path)
          if size <= 0 then return end
          if size > opts.size then return 'bigfile' end
          local lines = vim.api.nvim_buf_line_count(buf)
          if lines > 0 and (size - lines) / lines > opts.line_length then
            return 'bigfile'
          end
        end,
      },
    },
  })

  -- Disable heavy features for big files
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'bigfile',
    callback = function(ev)
      local buf = ev.buf
      vim.b[buf].large_file = true

      -- Disable treesitter highlight
      vim.treesitter.stop(buf)

      -- Disable fold computation
      vim.wo[0].foldmethod = 'manual'
      vim.wo[0].foldexpr = '0'

      -- Disable matchparen
      if vim.fn.exists(':NoMatchParen') == 2 then
        vim.cmd('NoMatchParen')
      end

      -- Disable swap/undo for memory
      vim.bo[buf].swapfile = false
      vim.bo[buf].undolevels = -1

      -- Limit search highlight time to prevent freeze
      vim.o.redrawtime = 200

      -- Limit syntax column for long lines
      vim.bo[buf].synmaxcol = 500

      -- Keep basic syntax via filetype detection
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          local ft = vim.filetype.match({ buf = buf }) or ''
          if ft ~= '' and ft ~= 'bigfile' then
            vim.bo[buf].syntax = ft
          end
        end
      end)

      vim.notify(
        'Big file detected — heavy features disabled',
        vim.log.levels.WARN
      )
    end,
  })

  -- Guard: skip treesitter.start for big files
  -- (called from init.lua FileType autocmd)
  local orig_ts_start = vim.treesitter.start
  vim.treesitter.start = function(buf, ...)
    buf = buf or vim.api.nvim_get_current_buf()
    if vim.b[buf].large_file then return end
    return orig_ts_start(buf, ...)
  end
end

return M
