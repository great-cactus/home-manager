-- obsidian.nvim on a slow mount (WSL /mnt/c): lexical path resolution and
-- no file watching.
--
-- obsidian.nvim resolves every vault path through Path.abspath, i.e.
-- vim.fn.resolve() + vim.uv.fs_realpath(), and does so many times while
-- entering a note (workspace lookup, note parsing, template dir, ...).
-- On a 9p/DrvFs mount each call costs 30-400 ms, so opening a note took
-- seconds. An NTFS vault has no symlinks, so inside the vault the real path
-- is the normalized absolute path; only existence needs a stat, and positive
-- stat results are cached briefly because the same path is checked
-- repeatedly within one event.
local M = {}

local STAT_TTL_MS = 2000

-- abs path -> { at = loop ms, stat = uv.fs_stat result }
local stat_cache = {}

local function cached_stat(abs)
  local now = vim.uv.now()
  local hit = stat_cache[abs]
  if hit and now - hit.at <= STAT_TTL_MS then
    return hit.stat
  end
  local stat = vim.uv.fs_stat(abs)
  if stat then
    stat_cache[abs] = { at = now, stat = stat }
  end
  return stat
end

local function in_vault(abs, root)
  return abs == root or vim.startswith(abs, root .. '/')
end

-- obsidian-ls forces the didChangeWatchedFiles capability on; Neovim then
-- walks the entire vault with fs_scandir to install watchers (~2 s on /mnt/c),
-- and inotify never fires on a DrvFs mount anyway. Advertise the Neovim
-- default (off on Linux) so the server's registration is ignored.
local function disable_file_watching()
  local obsidian_lsp = require('obsidian.lsp')
  local orig_start = obsidian_lsp.start
  obsidian_lsp.start = function(buf)
    local lsp_start = vim.lsp.start
    vim.lsp.start = function(config, opts)
      if config.name == 'obsidian-ls' then
        config.capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = false }
      end
      return lsp_start(config, opts)
    end
    local ok, result = pcall(orig_start, buf)
    vim.lsp.start = lsp_start
    if not ok then
      error(result, 0)
    end
    return result
  end
end

---@param vault_root string absolute path of the vault
function M.setup(vault_root)
  disable_file_watching()

  local Path = require('obsidian.path')
  local root = vim.fs.normalize(vault_root)
  local orig_abspath = Path.abspath
  local orig_stat = Path.stat

  Path.abspath = function(self)
    local abs = vim.fs.normalize(vim.fs.abspath(self.filename))
    if not in_vault(abs, root) then
      return orig_abspath(self)
    end
    return cached_stat(abs) and abs or nil
  end

  Path.stat = function(self)
    local abs = vim.fs.normalize(vim.fs.abspath(self.filename))
    if not in_vault(abs, root) then
      return orig_stat(self)
    end
    return cached_stat(abs)
  end
end

return M
