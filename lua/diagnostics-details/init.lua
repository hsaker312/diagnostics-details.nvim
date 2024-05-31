---@class Diagnostics_Details
Diagnostics_Details = {}

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

---@type integer
local main_win_id = 0

---@type integer?
local diagnostics_details_win_id = nil

---@type integer[]
local autocmds = {}

---@param path string?
---@return string
local function posix_path(path)
    if type(path) == "string" then
        local res = path:gsub("\\", "/")
        return res
    end

    return ""
end

---comment
---@param value any
---@return string
local function entry_str(value)
    if value == nil then
        return ""
    end

    local res = tostring(value):gsub("\r", "")

    return res
end

---@return Diagnostics_Entry[]
local function get_diagnostics_entries()
    ---@param diagnostic vim.Diagnostic
    ---@return string
    local function hl_group(diagnostic)
        if diagnostic.severity ~= nil then
            if diagnostic.severity == 1 then
                return "DiagnosticFloatingError"
            elseif diagnostic.severity == 2 then
                return "DiagnosticFloatingWarn"
            elseif diagnostic.severity == 3 then
                return "DiagnosticFloatingInfo"
            elseif diagnostic.severity == 4 then
                return "DiagnosticFloatingHint"
            end
        end

        return "NormalFloat"
    end

    ---@type Diagnostics_Entry[]
    local entries = {}
    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })

    for _, diagnostic in ipairs(diagnostics) do
        ---@type Diagnostics_Entry
        local entry = {
            uri = posix_path(vim.api.nvim_buf_get_name(0)),
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
                text = entry_str(source) .. ": ",
                hl_group = "NormalFloat",
            }
        else
            entry.text_objs[1] = {
                text = "vim diagnostics" .. ": ",
                hl_group = "Comment",
            }
        end

        entry.text_objs[2] = {
            text = entry_str(diagnostic.message),
            hl_group = hl_group(diagnostic),
        }

        entry.text_objs[3] = {
            text = " [" .. entry_str(diagnostic.code) .. "]",
            hl_group = "NormalFloat",
        }

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

        if user_data.lsp ~= nil then
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
                        text = entry_str(lsp.code),
                        hl_group = hl_group(diagnostic),
                    }

                    child.text_objs[2] = {
                        text = " (" .. entry_str(lsp.codeDescription.href) .. ")",
                        hl_group = "Comment",
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
                                uri = posix_path(location.uri),
                                text_objs = {},
                            }

                            table.insert(entry.children, child)

                            child.text_objs[1] = {
                                text = entry_str(child.uri:match("^.+/(.+)$")),
                                hl_group = "Underlined",
                            }

                            child.text_objs[2] = {
                                text = "",
                                hl_group = "Underlined",
                            }

                            if message ~= "" then
                                child.text_objs[3] = {
                                    text = ": ",
                                    hl_group = "NormalFloat",
                                }

                                child.text_objs[4] = {
                                    text = entry_str(message),
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

---comment
---@param file string
---@return integer?
local function get_file_buffer(file)
    local buffers = vim.api.nvim_list_bufs() -- Get a list of all buffer numbers

    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
            if vim.api.nvim_buf_get_name(buf) == file then
                return buf
            end
        end
    end
end

---@type fun()[]
local callbacks = {}

---@param diagnostics_entry Diagnostics_Entry
---@return fun()
local function make_line_callback(diagnostics_entry)
    return function()
        local file = diagnostics_entry.uri:gsub("file://", "")

        if file:match("^https?://[%w-_%.%?%.:/%+=&]+$") then
            if diagnostics_details_win_id ~= nil then
                vim.ui.open(diagnostics_entry.uri)
                return
            end
        end

        local file_buf = get_file_buffer(file)

        if file_buf == nil then
            vim.api.nvim_set_current_win(main_win_id)
            vim.api.nvim_command("edit " .. file)
        else
            vim.api.nvim_set_current_win(main_win_id)
            vim.api.nvim_win_set_buf(main_win_id, file_buf)
        end

        vim.schedule(function()
            if diagnostics_entry.range ~= nil then
                vim.api.nvim_command(
                    "call cursor("
                        .. tostring(diagnostics_entry.range.first.line)
                        .. ","
                        .. tostring(diagnostics_entry.range.first.col)
                        .. ")"
                )

                if
                    diagnostics_entry.range.last.line ~= diagnostics_entry.range.first.line
                    or (diagnostics_entry.range.last.col - diagnostics_entry.range.first.col) > 2
                then
                    vim.api.nvim_command("normal! v")

                    vim.api.nvim_win_set_cursor(
                        main_win_id,
                        { diagnostics_entry.range.last.line, diagnostics_entry.range.last.col }
                    )
                end
            end
        end)
    end
end

function Diagnostics_Details.diagnostics_line_callback()
    local line = vim.fn.line(".")

    if type(callbacks[line]) == "function" then
        callbacks[line]()
    end
end

---@return string[]
---@return Diagnostics_Highlight[]
---@return integer
---@return integer
local function get_diagnostics_lines()
    ---@type string[]
    local lines = {}

    ---@type Diagnostics_Highlight[]
    local highlights = {}

    callbacks = {}

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

    ---@param diagnostics_entries Diagnostics_Entry[]
    ---@param current_tab string
    local function make_lines(diagnostics_entries, current_tab)
        for _, diagnostics_entry in ipairs(diagnostics_entries) do
            local line = current_tab

            for _, text_obj in ipairs(diagnostics_entry.text_objs) do
                if text_obj.text:match("\n") == nil then
                    local line_len = #line
                    line = line .. text_obj.text

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
                        line = line .. text_line

                        append_highlight({
                            highlight = text_obj.hl_group,
                            line_num = lines_count,
                            col_begin = line_len,
                            col_end = #line,
                        })

                        if text_index < text_lines_count then
                            append_line(line)
                            append_callback(make_line_callback(diagnostics_entry))

                            line = current_tab .. tab
                        end
                    end
                end
            end

            append_line(line)
            append_callback(make_line_callback(diagnostics_entry))

            if diagnostics_entry.children ~= nil then
                make_lines(diagnostics_entry.children, current_tab .. tab)
            end
        end
    end

    make_lines(get_diagnostics_entries(), "")

    return lines, highlights, lines_count, max_line_len
end

---@param buf integer
---@param lines string[]
---@param highlights Diagnostics_Highlight[]
local function set_buffer_options(buf, lines, highlights)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.api.nvim_set_option_value("modifiable", false, {
        buf = buf,
    })

    vim.api.nvim_set_option_value("buftype", "nofile", {
        buf = buf,
    })

    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "<Cmd>lua Diagnostics_Details.diagnostics_line_callback()<CR>", {
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", "<Cmd>lua Diagnostics_Details.diagnostics_line_callback()<CR>", {
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(buf, "v", "<CR>", "<Cmd>lua Diagnostics_Details.diagnostics_line_callback()<CR>", {
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(
        buf,
        "n",
        "<2-LeftMouse>",
        "<Cmd>lua Diagnostics_Details.diagnostics_line_callback()<CR>",
        {
            noremap = true,
            silent = true,
        }
    )

    vim.api.nvim_buf_set_keymap(
        buf,
        "i",
        "<2-LeftMouse>",
        "<Cmd>lua Diagnostics_Details.diagnostics_line_callback()<CR>",
        {
            noremap = true,
            silent = true,
        }
    )

    vim.api.nvim_buf_set_keymap(
        buf,
        "v",
        "<2-LeftMouse>",
        "<Cmd>lua Diagnostics_Details.diagnostics_line_callback()<CR>",
        {
            noremap = true,
            silent = true,
        }
    )

    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<Cmd>quit<CR>", {
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(buf, "i", "q", "<Cmd>quit<CR>", {
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(buf, "v", "q", "<Cmd>quit<CR>", {
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(buf, "n", "<esc>", "<Cmd>quit<CR>", {
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(buf, "i", "<esc>", "<Cmd>quit<CR>", {
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(buf, "v", "<esc>", "<Cmd>quit<CR>", {
        noremap = true,
        silent = true,
    })

    for _, highlight in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(
            buf,
            -1,
            highlight.highlight,
            highlight.line_num,
            highlight.col_begin,
            highlight.col_end
        )
    end
end

function Diagnostics_Details.show()
    main_win_id = vim.api.nvim_get_current_win()

    local main_win_width = vim.api.nvim_win_get_width(main_win_id)
    local main_win_current_col = vim.api.nvim_win_get_cursor(main_win_id)[2]
    local lines, highlights, lines_count, max_line_len = get_diagnostics_lines()

    if lines_count > 0 then
        local buf = vim.api.nvim_create_buf(false, true)
        set_buffer_options(buf, lines, highlights)

        diagnostics_details_win_id = vim.api.nvim_open_win(buf, true, {
            relative = "cursor",
            row = 1,
            col = 1,
            width = math.min(
                math.max(math.min(math.floor(main_win_width * 0.9) - main_win_current_col, max_line_len), 100),
                max_line_len
            ),
            height = math.min(5, lines_count),
            style = "minimal",
            border = "rounded",
        })

        vim.api.nvim_set_option_value("number", false, {
            win = diagnostics_details_win_id,
        })

        vim.api.nvim_set_option_value("spell", false, {
            win = diagnostics_details_win_id,
        })

        table.insert(
            autocmds,
            vim.api.nvim_create_autocmd("CursorMoved", {
                callback = function()
                    if
                        diagnostics_details_win_id ~= nil
                        and vim.api.nvim_get_current_win() ~= diagnostics_details_win_id
                    then
                        vim.api.nvim_win_close(diagnostics_details_win_id, true)
                        diagnostics_details_win_id = nil
                        for _, autocmd in ipairs(autocmds) do
                            vim.api.nvim_del_autocmd(autocmd)
                        end
                        autocmds = {}
                    end
                end,
            })
        )

        table.insert(
            autocmds,
            vim.api.nvim_create_autocmd("WinClosed", {
                callback = function(event)
                    if diagnostics_details_win_id ~= nil then
                        if tonumber(event.match) == diagnostics_details_win_id then
                            diagnostics_details_win_id = nil
                            for _, autocmd in ipairs(autocmds) do
                                vim.api.nvim_del_autocmd(autocmd)
                            end
                            autocmds = {}
                        end
                    end
                end,
            })
        )
    end
end

function Diagnostics_Details.setup()
    vim.api.nvim_create_user_command("DiagnosticsDetailsOpenFloat", Diagnostics_Details.show, {})
end

return Diagnostics_Details
