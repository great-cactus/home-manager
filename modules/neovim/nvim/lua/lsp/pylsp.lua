return{
    settings = {
        pylsp = {
            configurationSources = {'pycodestyle'},
            plugins = {
                pycodestyle = {
                    enabled = true,
                    ignore = {'E201', 'E202', 'E203', 'E221', 'E226', 'E231', 'E241', 'E266', 'E302', 'E722'},
                    maxLineLength = 88
                },
                flake8 = {
                    enabled = false
                },
                rope_rename = {
                    enabled = false
                }
            }
        }
    }
}
