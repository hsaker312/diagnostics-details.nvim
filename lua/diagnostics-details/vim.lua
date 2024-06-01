---@class Vim
Vim = {}

---@type Utils
Utils = require("diagnostics-details.utils")

---@type Formatter
Formatter = require("diagnostics-details.formatter")

---@type Diagnostics_Parser
Diagnostics_Parser = require("diagnostics-details.diagnostics-parser")

---@type integer
local main_win_id = 0

---@type integer?
local diagnostics_details_win_id = nil

---@type fun()[]
local callbacks = {}

---@type integer[]
local autocmds = {}

function Vim.diagnostics_line_callback()
    local line = vim.fn.line(".")

    if type(callbacks[line]) == "function" then
        callbacks[line]()
    end
end

---@param diagnostics_entry Diagnostics_Entry
---@return fun()
local function make_line_callback(diagnostics_entry)
    return function()
        local file = diagnostics_entry.uri:gsub("file://", "")

        if file:match("^https?://[%w-_%.%?%.:/%+=&@#]+$") then
            vim.ui.open(diagnostics_entry.uri)
        else
            local file_buf = Utils.get_file_buffer(file)

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

    Utils.set_buffer_keymap(
        buf,
        "<CR>",
        "<Cmd>lua require('diagnostics-details.vim').diagnostics_line_callback()<CR>",
        {
            noremap = true,
            silent = true,
        }
    )

    Utils.set_buffer_keymap(
        buf,
        "<2-LeftMouse>",
        "<Cmd>lua require('diagnostics-details.vim').diagnostics_line_callback()<CR>",
        {
            noremap = true,
            silent = true,
        }
    )

    Utils.set_buffer_keymap(buf, "q", "<Cmd>quit<CR>", {
        noremap = true,
        silent = true,
    })

    Utils.set_buffer_keymap(buf, "<esc>", "<Cmd>quit<CR>", {
        noremap = true,
        silent = true,
    })

    Utils.set_buffer_highlights(buf, highlights)
end

local function set_diagnostics_window_options()
    vim.api.nvim_set_option_value("number", false, {
        win = diagnostics_details_win_id,
    })

    vim.api.nvim_set_option_value("spell", false, {
        win = diagnostics_details_win_id,
    })
end

local function diagnostics_window_close_handler()
    diagnostics_details_win_id = nil

    for _, autocmd in ipairs(autocmds) do
        vim.api.nvim_del_autocmd(autocmd)
    end

    autocmds = {}
end

local function initialize_autocmds()
    table.insert(
        autocmds,
        vim.api.nvim_create_autocmd("CursorMoved", {
            callback = function()
                if
                    diagnostics_details_win_id ~= nil
                    and vim.api.nvim_get_current_win() ~= diagnostics_details_win_id
                then
                    vim.api.nvim_win_close(diagnostics_details_win_id, true)
                    diagnostics_window_close_handler()
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
                        diagnostics_window_close_handler()
                    end
                end
            end,
        })
    )
end

function Vim.show()
    main_win_id = vim.api.nvim_get_current_win()

    local lines, highlights, callbacks_res, lines_count, max_line_len =
        Formatter.get_diagnostics_lines(Diagnostics_Parser.get_diagnostics_entries(), make_line_callback)
    callbacks = callbacks_res

    local diagnostics_window_dimension = Utils.diagnostics_window_dimension(main_win_id, max_line_len, lines_count)

    if lines_count > 0 then
        local buf = vim.api.nvim_create_buf(false, true)
        set_buffer_options(buf, lines, highlights)

        diagnostics_details_win_id = vim.api.nvim_open_win(buf, true, {
            relative = "cursor",
            row = 1,
            col = 1,
            width = diagnostics_window_dimension.width,
            height = diagnostics_window_dimension.height,
            style = "minimal",
            border = "rounded",
        })

        set_diagnostics_window_options()

        initialize_autocmds()
    end
end

return Vim
