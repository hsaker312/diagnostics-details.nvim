---@class Setup_Opts
---@field diagnostics_error_highlight_group string?
---@field diagnostics_warn_highlight_group string?
---@field diagnostics_info_highlight_group string?
---@field diagnostics_hint_highlight_group string?
---@field default_text_highlight_group string?
---@field diagnostics_source_highlight_group string?
---@field diagnostics_code_highlight_group string?
---@field diagnostics_url_code_highlight_group string?
---@field diagnostics_url_highlight_group string?
---@field diagnostics_source_file_highlight_group string?
---@field unknown_diagnostics_source string?
---@field unknown_diagnostics_source_highlight_group string?
---@field max_window_width_fallback integer?
---@field max_window_height_fallback integer?
---@field max_window_width_percentage float?
---@field max_window_height_percentage float?
---@field auto_close_on_focus_lost boolean?
---@field open_key string|table<integer,string>|nil
---@field quit_key string|table<integer,string>|nil

---@class Diagnostics_Details
Diagnostics_Details = {}

---@type Utils
Utils = require("diagnostics-details.utils")

---@type Vim
Vim = require("diagnostics-details.vim")

Diagnostics_Details.show = Vim.show

---Toggle auto close diagnostics window when focus is lost
function Diagnostics_Details.toggle_persiste()
    Config.auto_close_on_focus_lost = not Config.auto_close_on_focus_lost
end

---@param opts Setup_Opts?
function Diagnostics_Details.setup(opts)
    vim.api.nvim_create_user_command("DiagnosticsDetailsOpenFloat", Diagnostics_Details.show, {})
    vim.api.nvim_create_user_command("DiagnosticsDetailsTogglePersiste", Diagnostics_Details.toggle_persiste, {})

    if type(opts) == "table" then
        Utils.process_opts(opts)
    end
end

return Diagnostics_Details
