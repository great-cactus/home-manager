-- Spell-check configuration
local spell_dir = vim.fn.expand('~/.local/share/nvim/spell')
local project_spell_file = {
    good  = '.spell/project.utf-8.add',      -- 正しい単語用
    wrong = '.spell/project.utf-8.bad.add'   -- 誤った単語用
}

-- グローバルスペルディレクトリの作成
if vim.fn.isdirectory(spell_dir) == 0 then
    vim.fn.mkdir(spell_dir, 'p')
end
-- スペルファイルの設定
vim.opt.spellfile = spell_dir .. '/en.utf-8.add'

-- プロジェクトローカルのスペルファイル作成関数
local function ensure_project_spellfile()
    local spell_dir = '.spell'
    if vim.fn.isdirectory(spell_dir) == 0 then
        vim.fn.mkdir(spell_dir, 'p')
    end
    -- 両方のファイルの存在確認と作成
    for _, file in pairs(project_spell_file) do
        if vim.fn.filereadable(file) == 0 then
            vim.fn.writefile({}, file)
        end
    end
end

-- ファイルから単語を追加/削除する汎用関数
local function manage_word_in_file(word, file, action, is_good)
    ensure_project_spellfile()

    local words = {}
    if vim.fn.filereadable(file) == 1 then
        words = vim.fn.readfile(file)
    end

    if action == "add" then
        -- 重複チェック
        for _, existing_word in ipairs(words) do
            if existing_word == word then
                return
            end
        end
        -- 新しい単語を追加
        table.insert(words, word)
        vim.fn.writefile(words, file)
        vim.cmd(string.format('silent! spell%s! %s', is_good and "good" or "bad", word))
    else -- remove
        local new_words = {}
        local found = false

        for _, existing_word in ipairs(words) do
            if existing_word ~= word then
                table.insert(new_words, existing_word)
            else
                found = true
            end
        end

        if found then
            vim.fn.writefile(new_words, file)
            vim.cmd(string.format('silent! spellundo! %s', word))
        end
    end
end

-- キーマッピング設定
-- zG: 正しい単語として追加
vim.keymap.set('n', 'zG', function()
    local word = vim.fn.expand('<cword>')
    manage_word_in_file(word, project_spell_file.good, "add", true)
end, { silent = true })

-- zuG: 正しい単語から削除
vim.keymap.set('n', 'zuG', function()
    local word = vim.fn.expand('<cword>')
    manage_word_in_file(word, project_spell_file.good, "remove", true)
end, { silent = true })

-- zW: 誤った単語として追加
vim.keymap.set('n', 'zW', function()
    local word = vim.fn.expand('<cword>')
    manage_word_in_file(word, project_spell_file.wrong, "add", false)
end, { silent = true })

-- zuW: 誤った単語から削除
vim.keymap.set('n', 'zuW', function()
    local word = vim.fn.expand('<cword>')
    manage_word_in_file(word, project_spell_file.wrong, "remove", false)
end, { silent = true })

-- プロジェクトスペルファイルを読み込む関数
local function load_project_spellfile()
    if vim.fn.filereadable(project_spell_file.good) == 1 then
        local words = vim.fn.readfile(project_spell_file.good)
        for _, word in ipairs(words) do
            if word ~= '' then
                vim.cmd('silent! spellgood! ' .. word)
            end
        end
    end
    if vim.fn.filereadable(project_spell_file.wrong) == 1 then
        local words = vim.fn.readfile(project_spell_file.wrong)
        for _, word in ipairs(words) do
            if word ~= '' then
                vim.cmd('silent! spellbad! ' .. word)
            end
        end
    end
end

-- スペルチェックの切り替え（英語）
vim.keymap.set('n', '<leader>se', function()
    if vim.wo.spell then
        vim.wo.spell = false
        vim.notify('Spell check OFF', vim.log.levels.INFO, {})
    else
        vim.wo.spell = true
        vim.opt.spelllang = 'en_us,cjk'
        load_project_spellfile()
        vim.notify('Spell check ON (English)', vim.log.levels.INFO, {})
    end
end, { silent = true })

-- スペルチェックの切り替え（日本語）
-- vim.keymap.set('n', '<leader>sj', function()
--     if vim.wo.spell then
--         vim.wo.spell = false
--         vim.notify('Spell check OFF', vim.log.levels.INFO, {})
--     else
--         vim.wo.spell = true
--         vim.opt.spelllang = 'ja'
--         load_project_spellfile()
--         vim.notify('Spell check ON (Japanese)', vim.log.levels.INFO, {})
--     end
-- end, { silent = true })
