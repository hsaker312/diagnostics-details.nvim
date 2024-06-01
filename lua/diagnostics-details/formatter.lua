---@class Formatter
Formatter = {}

---@type Utils
Utils = require("diagnostics-details.utils")

---@param diagnostics_entries Diagnostics_Entry[]
---@param callback_maker fun(Diagnostics_Entry):fun()
---@return string[]
---@return Diagnostics_Highlight[]
---@return fun()[]
---@return integer
---@return integer
function Formatter.get_diagnostics_lines(diagnostics_entries, callback_maker)
    ---@type string[]
    local lines = {}

    ---@type Diagnostics_Highlight[]
    local highlights = {}

    ---@type fun()[]
    local callbacks = {}

    local lines_count = 0
    local tab = "   "
    local max_line_len = 0

    ---@param line string
    local function append_line(line)
        table.insert(lines, line)
        lines_count = lines_count + 1
        max_line_len = math.max(max_line_len, #lines[lines_count])
    end

    ---@param highlight Diagnostics_Highlight
    local function append_highlight(highlight)
        table.insert(highlights, highlight)
    end

    ---@param callback fun()
    local function append_callback(callback)
        table.insert(callbacks, callback)
    end

    ---@param entries Diagnostics_Entry[]
    ---@param current_tab string
    local function make_lines(entries, current_tab)
        for _, diagnostics_entry in ipairs(entries) do
            local line = current_tab

            for text_obj_index, text_obj in ipairs(diagnostics_entry.text_objs) do
                if text_obj.text:match("\n") == nil then
                    local line_len = #line
                    line = line .. Utils.format_diagnostics_str(text_obj.text)

                    append_highlight({
                        highlight = text_obj.hl_group,
                        line_num = lines_count,
                        col_begin = line_len,
                        col_end = #line,
                    })
                else
                    ---@type string[]
                    local text_lines = {}
                    local text_lines_count = 0

                    for text_line in text_obj.text:gmatch("([^\n]*)\n?") do
                        table.insert(text_lines, text_line)
                        text_lines_count = text_lines_count + 1
                    end

                    for text_index, text_line in ipairs(text_lines) do
                        local line_len = #line
                        line = line .. Utils.format_diagnostics_str(text_line)

                        append_highlight({
                            highlight = text_obj.hl_group,
                            line_num = lines_count,
                            col_begin = line_len,
                            col_end = #line,
                        })

                        if
                            text_index < (text_lines_count - 1)
                            or (
                                text_index == (text_lines_count - 1)
                                and diagnostics_entry.text_objs[text_obj_index + 1] == nil
                            )
                        then
                            append_line(line)
                            append_callback(callback_maker(diagnostics_entry))

                            line = current_tab:gsub(" ", ".") .. tab:gsub(" ", ".")
                        end
                    end
                end
            end

            append_line(line)
            append_callback(callback_maker(diagnostics_entry))

            if diagnostics_entry.children ~= nil then
                make_lines(diagnostics_entry.children, current_tab .. tab)
            end
        end
    end

    make_lines(diagnostics_entries, "")

    return lines, highlights, callbacks, lines_count, max_line_len
end

return Formatter
