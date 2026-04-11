local cmdline_content = ''
local is_confirm_substitute = false
local nohl_timer = nil

vim.api.nvim_create_autocmd('CmdLineEnter', {
    group = vim.api.nvim_create_augroup('SubstituteTrackEnter', {clear = true}),
    pattern = ':',
    callback = function()
        cmdline_content = ''
        is_confirm_substitute = false
        if nohl_timer then
            vim.fn.timer_stop(nohl_timer)
            nohl_timer = nil
        end
    end,
})

vim.api.nvim_create_autocmd('CmdlineLeave', {
    group = vim.api.nvim_create_augroup('SubstituteNohlOnLeave', {clear = true}),
    pattern = ':',
    callback = function()
        cmdline_content = vim.fn.getcmdline()

        -- cフラグ付きの置換コマンドかチェック
        local has_confirm_flag = cmdline_content:match("/.*c") or cmdline_content:match("/.*gc") or cmdline_content:match("/.*cg")

        if (cmdline_content:match("^'<,'>s/") or
           cmdline_content:match("^'<,'>S") or
           cmdline_content:match("^'<,'>substitute/") or
           cmdline_content:match("^%%s/") or
           cmdline_content:match("^s/") or
           cmdline_content:match("^%d+,%d+s/") or  -- 行番号範囲指定
           cmdline_content:match("^%.,%$s/") or    -- 現在行から最終行
           cmdline_content:match("^%.,%%s/")) then  -- その他の範囲指定

            if has_confirm_flag then
                is_confirm_substitute = true
            else
                vim.defer_fn(function()
                    vim.cmd('noh')
                end, 0)
            end
        end
    end,
})

-- 確認付き置換の完了を検知（デバウンス付き）
vim.api.nvim_create_autocmd({'CursorMoved', 'InsertEnter'}, {
    group = vim.api.nvim_create_augroup('SubstituteConfirmComplete', {clear = true}),
    callback = function()
        if is_confirm_substitute then
            -- 既存のタイマーをキャンセル
            if nohl_timer then
                vim.fn.timer_stop(nohl_timer)
            end

            -- 新しいタイマーを設定（500ms後に実行）
            nohl_timer = vim.fn.timer_start(500, function()
                vim.cmd('noh')
                is_confirm_substitute = false
                nohl_timer = nil
            end)
        end
    end,
})
