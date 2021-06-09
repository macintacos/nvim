local set = vim.api.nvim_set_var

set("go_highlight_array_whitespace_error", 1)
set("go_highlight_extra_types", 1)
set("go_highlight_chan_whitespace_error", 1)
set("go_highlight_operators", 1)
set("go_highlight_functions", 1)
set("go_highlight_function_parameters", 1)
set("go_highlight_types", 1)
set("go_highlight_fields", 1)
set("go_highlight_build_constraints", 1)
set("go_highlight_generate_tags", 1)
set("go_highlight_variable_declarations", 1)
set("go_highlight_variable_assignments", 1)

set("go_fmt_fail_silently", 1)
set("go_def_mapping_enabled", 0)

-- TODO: Generate keymaps for this (or should it all just go to which-key?)