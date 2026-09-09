return {
    filetypes = { 'julia' },
    cmd = {
        'julia',
        '--startup-file=no',
        '--history-file=no',
        '--depwarn=no',
        '-e', [[
            using LanguageServer
            runserver()
        ]],
    },
    root_markers = { 'Project.toml', 'JuliaProject.toml', '.git' },
}
