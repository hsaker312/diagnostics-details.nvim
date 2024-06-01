---@class Diagnostics_Parser
Diagnostics_Parser = {}

---@type Utils
Utils = require("diagnostics-details.utils")

---@type Config
Config = require("diagnostics-details.config")

---@class Diagnostics_Highlight
---@field highlight string
---@field line_num integer
---@field col_begin integer
---@field col_end integer

---@class Text_Object
---@field text string
---@field hl_group string

---@class Position
---@field line integer
---@field col integer

---@class Diagnostics_Range
---@field first Position
---@field last Position

---@class Diagnostics_Entry
---@field uri string
---@field text_objs Text_Object[]
---@field range? Diagnostics_Range
---@field children Diagnostics_Entry[]?


---@return Diagnostics_Entry[]
function Diagnostics_Parser.get_diagnostics_entries()
    ---@param diagnostic vim.Diagnostic
    ---@return string
    local function hl_group(diagnostic)
        if diagnostic.severity ~= nil then
            return Config.diagnostic_severity_highlight_group[diagnostic.severity]
        end

        return Config.default_text_highlight_group
    end

    ---@type Diagnostics_Entry[]
    local entries = {}
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })

    for _, diagnostic in ipairs(diagnostics) do
        ---@type Diagnostics_Entry
        local entry = {
            uri = Utils.posix_path(vim.api.nvim_buf_get_name(0)),
            text_objs = {},
            children = {},
        }

        table.insert(entries, entry)

        local source = diagnostic.source or ""

        if source:sub(#source, #source) == "." or source:sub(#source, #source) == ":" then
            source = source:sub(1, #source - 1)
        end

        if source ~= "" then
            entry.text_objs[1] = {
                text = Utils.format_entry_str(source) .. ": ",
                hl_group = Config.diagnostics_source_highlight_group,
            }
        else
            entry.text_objs[1] = {
                text = Config.unknown_diagnostics_source .. ": ",
                hl_group = Config.unknown_diagnostics_source_highlight_group,
            }
        end

        entry.text_objs[2] = {
            text = Utils.format_entry_str(diagnostic.message),
            hl_group = hl_group(diagnostic),
        }

        local code_str = Utils.format_entry_str(diagnostic.code)

        if code_str ~= "" then
            entry.text_objs[3] = {
                text = " [" .. code_str .. "]",
                hl_group = Config.diagnostics_code_highlight_group,
            }
        end

        entry.range = {
            first = {
                line = diagnostic.lnum + 1,
                col = diagnostic.col,
            },
            last = {
                line = diagnostic.end_lnum + 1,
                col = diagnostic.end_col,
            },
        }

        local user_data = diagnostic.user_data

        if user_data ~= nil and user_data.lsp ~= nil then
            local lsp = user_data.lsp

            if type(lsp.code) == "string" and lsp.codeDescription ~= nil then
                if type(lsp.codeDescription.href) == "string" then
                    ---@type Diagnostics_Entry
                    local child = {
                        uri = lsp.codeDescription.href,
                        text_objs = {},
                    }

                    table.insert(entry.children, child)

                    child.text_objs[1] = {
                        text = Utils.format_entry_str(lsp.code),
                        hl_group = Config.diagnostics_url_code_highlight_group or hl_group(diagnostic),
                    }

                    child.text_objs[2] = {
                        text = " (" .. Utils.format_entry_str(lsp.codeDescription.href) .. ")",
                        hl_group = Config.diagnostics_url_highlight_group,
                    }
                end
            end

            if type(lsp.relatedInformation) == "table" then
                local related_information = lsp.relatedInformation

                for _, information in pairs(related_information) do
                    local location = information.location
                    local message = information.message

                    if type(message) == "string" and type(location) == "table" then
                        if type(location.uri) == "string" then
                            ---@type Diagnostics_Entry
                            local child = {
                                uri = Utils.posix_path(location.uri),
                                text_objs = {},
                            }

                            table.insert(entry.children, child)

                            child.text_objs[1] = {
                                text = Utils.format_entry_str(child.uri:match("^.+/(.+)$")),
                                hl_group = Config.diagnostics_source_file_highlight_group,
                            }

                            child.text_objs[2] = {
                                text = "",
                                hl_group = Config.diagnostics_source_file_highlight_group,
                            }

                            if message ~= "" then
                                child.text_objs[3] = {
                                    text = ": ",
                                    hl_group = Config.default_text_highlight_group,
                                }

                                child.text_objs[4] = {
                                    text = Utils.format_entry_str(message),
                                    hl_group = hl_group(diagnostic),
                                }
                            end

                            local range = location.range

                            if type(range) == "table" then
                                local first = range.start
                                local last = range["end"]

                                if type(first) == "table" and type(last) == "table" then
                                    if type(first.line) == "number" and type(first.character) == "number" then
                                        child.text_objs[2].text = "("
                                            .. tostring(first.line + 1)
                                            .. ", "
                                            .. tostring(first.character + 1)
                                            .. ")"

                                        child.range = {
                                            first = {
                                                line = first.line + 1,
                                                col = first.character + 1,
                                            },
                                            last = {
                                                line = first.line + 1,
                                                col = first.character + 1,
                                            },
                                        }

                                        if type(last.line) == "number" and type(last.character) == "number" then
                                            child.range.last.line = last.line + 1
                                            child.range.last.col = last.character + 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return entries
end

return Diagnostics_Parser
