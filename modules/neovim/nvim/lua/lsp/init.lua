-- このファイルの存在するディレクトリ
local dirname = vim.fn.stdpath('config') .. '/lua/lsp'

-- 設定したlspを保存する配列
local lsp_names = {}

for file, ftype in vim.fs.dir(dirname) do
  if (ftype == 'file' or ftype == 'link') and vim.endswith(file, '.lua') and file ~= 'init.lua' then
    local lsp_name = file:sub(1, -5) -- fname without '.lua'
    local ok, result = pcall(require, 'lsp.' .. lsp_name)
    if ok then
      vim.lsp.config(lsp_name, result)
      table.insert(lsp_names, lsp_name)
    else
      vim.notify('Error loading LSP: ' .. lsp_name .. '\n' .. result, vim.log.levels.WARN)
    end
  end
end

vim.lsp.enable(lsp_names)
