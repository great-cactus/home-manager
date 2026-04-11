require("codecompanion").setup({
  language = "Japanese",
  system_prompt = {
    enabled = false,
  },
  rules = {
    default = {
      files = {}, -- Clear all default rules
    },
    opts = {
      chat = {
        enabled = false,
        autoload = false,
      },
      show_presets = false,
    },
  },
  display = {
    chat = {
      auto_scroll = false,
      show_header_separator = true,
    },
  },
  interactions = {
    inline = { adapter = "copilot" },
    agent = { adapter = "copilot" },
    chat = {
      adapter = "copilot",
      roles = {
        llm = function(adapter)
          return "  (" .. adapter.formatted_name .. ")"
        end,
        user = " ",
      },
    },
  },
  adapters = {
    copilot = function()
      return require("codecompanion.adapters").extend("copilot",
        {
          schema = {
            model = {
              default = "claude-opus-4.5",
            },
          },
        })
    end,
  },

  prompt_library = {
    -- Code operations (Japanese explanations)
    ["Explain"] = {
      strategy = "chat",
      description = "Explain code in Japanese",
      prompts = {
        {
          role = "user",
          content = "上記のコードを日本語で説明してください。",
        },
      },
    },
    ["Fix"] = {
      strategy = "chat",
      description = "Fix bugs",
      prompts = {
        {
          role = "user",
          content = "このコードには問題があります。バグを修正したコードを表示してください。コメントは英語で、説明は日本語でしてください。",
        },
      },
    },
    ["Optimize"] = {
      strategy = "chat",
      description = "Optimize code",
      prompts = {
        {
          role = "user",
          content = "モダンでシンプルにすることを目標とし、選択したコードを最適化し、最適化を反映したコードを表示してください。",
        },
      },
    },

    -- Translation prompts
    ["Jap2Eng"] = {
      strategy = "chat",
      description = "Japanese to English",
      prompts = {
        {
          role = "user",
          content = "上記の文章を日本語から英語に翻訳して下さい。もし主語、動詞、目的語などが不明瞭で明確な翻訳ができない場合は、私に追加の質問をし不明瞭な点を解消してから翻訳に取り掛かってください。",
        },
      },
    },
    ["Eng2Jap"] = {
      strategy = "chat",
      description = "English to Japanese",
      prompts = {
        {
          role = "user",
          content = "上記の文章を英語から日本語に翻訳して下さい。",
        },
      },
    },
    ["EngProofRead"] = {
      strategy = "chat",
      description = "Proofread English",
      prompts = {
        {
          role = "user",
          content = "上記の文章を文法の誤りを直し、ネイティブから見て自然な英語になるように校閲、推敲して下さい。このとき、並び替えたり別の表現を用いれば不要になる箇所は取り去り、必要十分な文章のみで英文を構成してください。",
        },
      },
    },

    -- Commit message
    ["Commit"] = {
      strategy = "chat",
      description = "Generate commit message",
      prompts = {
        {
          role = "user",
          content = "変更に対応するコミットメッセージを英語で記述して下さい。タイトルは最大50文字、メッセージは72文字で折り返し、メッセージ全体をgitcommit言語のコードブロックでラップして下さい。commitizeがあればその規則に従って下さい。",
        },
      },
    },
  },
})

-- Keymaps
local map = vim.keymap.set
map("n", "<leader>cce", ":CodeCompanion Explain<CR>", { desc = "Explain code" })
map("v", "<leader>cce", ":CodeCompanion Explain<CR>", { desc = "Explain code" })
map("n", "<leader>ccf", ":CodeCompanion Fix<CR>", { desc = "Fix code" })
map("v", "<leader>ccf", ":CodeCompanion Fix<CR>", { desc = "Fix code" })
map("n", "<leader>cco", ":CodeCompanion Optimize<CR>", { desc = "Optimize code" })
map("v", "<leader>cco", ":CodeCompanion Optimize<CR>", { desc = "Optimize code" })
map("n", "<leader>ccc", ":CodeCompanion Commit<CR>", { desc = "Generate commit" })
map("v", "<leader>ccje", ":CodeCompanion Jap2Eng<CR>", { desc = "Japanese to English" })
map("v", "<leader>ccej", ":CodeCompanion Eng2Jap<CR>", { desc = "English to Japanese" })
map("v", "<leader>ccep", ":CodeCompanion EngProofRead<CR>", { desc = "Proofread English" })
map("n", "<leader>ccq", function()
  local input = vim.fn.input("Quick Chat: ")
  if input ~= "" then
    vim.cmd("CodeCompanion " .. input)
  end
end, { desc = "Quick Chat" })
