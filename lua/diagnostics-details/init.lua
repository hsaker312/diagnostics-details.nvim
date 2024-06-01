---@class Diagnostics_Details
Diagnostics_Details = {}

---@type Vim
Vim = require("diagnostics-details.vim")

Diagnostics_Details.show = Vim.show

function Diagnostics_Details.setup()
    vim.api.nvim_create_user_command("DiagnosticsDetailsOpenFloat", Diagnostics_Details.show, {})
end

return Diagnostics_Details
