local function load_spellfile_words()
  local words = {}
  local spellfile = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

  -- Set up spellfile option and create directory if needed
  vim.fn.mkdir(vim.fn.fnamemodify(spellfile, ":h"), "p")
  vim.opt.spellfile = spellfile

  local file = io.open(spellfile, "r")
  if file then
    for word in file:lines() do
      if word ~= "" then
        table.insert(words, word)
      end
    end
    file:close()
  end

  return words
end

local function update_ltex_dictionary()
  local words = load_spellfile_words()
  local clients = vim.lsp.get_clients({ name = "ltex" })

  for _, client in ipairs(clients) do
    if client.server_capabilities then
      client.config.settings.ltex.dictionary["en-US"] = words
      client.notify("workspace/didChangeConfiguration", {
        settings = client.config.settings
      })
    end
  end
end


local function setup_ltex_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }

  -- Override spell commands to trigger ltex dictionary update
  local spell_commands = {
    { cmd = "zg"},
    { cmd = "zG"},
    { cmd = "zw"},
    { cmd = "zW"},
    { cmd = "zug"},
    { cmd = "zuw"},
    { cmd = "zuG"},
    { cmd = "zuW"},
  }

  for _, item in ipairs(spell_commands) do
    vim.keymap.set("n", item.cmd, function()
      local word = vim.fn.expand("<cword>")

      -- Capture messages by redirecting output
      local old_shortmess = vim.o.shortmess
      vim.o.shortmess = ""

      local output = vim.fn.execute("normal! " .. item.cmd, "silent!")

      vim.o.shortmess = old_shortmess

      -- Show message via vim.notify if there's output
      if output and output ~= "" then
        vim.notify(output:gsub("^%s*(.-)%s*$", "%1"), vim.log.levels.INFO)
      end

      vim.defer_fn(update_ltex_dictionary, 100)
    end, opts)
  end
end

return {
  filetypes = { 'tex', 'latex', 'plaintex', 'markdown' },
  init_options = { documentFormatting = true },
  settings = {
    ltex = {
      language = "en-US",
      dictionary = {
        ["en-US"] = load_spellfile_words(),
      },
      disabledRules = {},
      hiddenFalsePositives = {},
    },
  },
  on_attach = function(client, bufnr)
    setup_ltex_keymaps(bufnr)
  end,
}
