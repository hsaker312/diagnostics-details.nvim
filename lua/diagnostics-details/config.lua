---@class Config
Config = {}

---@type string[]
Config.diagnostic_severity_highlight_group = {
    "DiagnosticFloatingError",
    "DiagnosticFloatingWarn",
    "DiagnosticFloatingInfo",
    "DiagnosticFloatingHint",
}

Config.default_text_highlight_group = "NormalFloat"
Config.diagnostics_source_highlight_group = Config.default_text_highlight_group
Config.diagnostics_code_highlight_group = Config.default_text_highlight_group
---@type string?
Config.diagnostics_url_code_highlight_group = nil
Config.diagnostics_url_highlight_group = "Comment"
Config.diagnostics_source_file_highlight_group = "Underlined"

Config.unknown_diagnostics_source = "Vim-Diagnostics"
Config.unknown_diagnostics_source_highlight_group = "Comment"

Config.max_window_width_fallback = 100
Config.max_window_height_fallback = 5

Config.max_window_width_percentage = 0.9
Config.max_window_height_percentage = 0.65

Config.auto_close_on_focus_lost = true

---@type string[]
Config.open_key = {"<CR>", "<2-LeftMouse>"}

---@type string[]
Config.quit_key = {"q", "<esc>"}

return Config
