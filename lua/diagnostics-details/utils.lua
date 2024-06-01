---@class Utils
Utils = {}

---@type Config
Config = require("diagnostics-details.config")

---@param path string?
---@return string
function Utils.posix_path(path)
    if type(path) == "string" then
        local res = path:match("^%s*(.-)%s*$")
        res = res:gsub("\\", "/")
        return res
    end

    return ""
end

---@param value any
---@return string
function Utils.format_entry_str(value)
    if value == nil then
        return ""
    end

    local res = tostring(value):gsub("\r", "")

    return res
end

---@param str string
---@return string
function Utils.format_diagnostics_str(str)
    local res = str
        :gsub("\t", " ") --tab
        :gsub(string.char(194) .. string.char(160), " ") --U+C2A0
        :gsub("%s+", " ") --multi-space

    return res
end

---@param file string
---@return integer?
function Utils.get_file_buffer(file)
    local buffers = vim.api.nvim_list_bufs() -- Get a list of all buffer numbers

    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
            if vim.api.nvim_buf_get_name(buf) == file then
                return buf
            end
        end
    end
end

---comment
---@param buf integer
---@param lhs string
---@param rhs string
---@param opts vim.api.keyset.keymap
function Utils.set_buffer_keymap(buf, lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(buf, "n", lhs, rhs, opts)

    vim.api.nvim_buf_set_keymap(buf, "i", lhs, rhs, opts)

    vim.api.nvim_buf_set_keymap(buf, "v", lhs, rhs, opts)
end

---@param buf integer
---@param highlights Diagnostics_Highlight[]
function Utils.set_buffer_highlights(buf, highlights)
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

---comment
---@param main_win_id integer
---@param max_line_len integer
---@param lines_count integer
---@return Dimension
function Utils.diagnostics_window_dimension(main_win_id, max_line_len, lines_count)
    local main_win_width = vim.api.nvim_win_get_width(main_win_id)
    local main_win_height = vim.api.nvim_win_get_height(main_win_id)
    local cursor = vim.api.nvim_win_get_cursor(main_win_id)
    local main_win_current_line = cursor[1]
    local main_win_current_col = cursor[2]

    ---@class Dimension
    ---@field width integer
    ---@field height integer
    local res = {
        width = math.min(
            math.max(
                math.min(
                    math.floor(main_win_width * Config.max_window_width_percentage) - main_win_current_col,
                    max_line_len
                ),
                Config.max_window_width_fallback
            ),
            max_line_len
        ),
        height = math.min(
            math.max(
                math.min(
                    math.floor(main_win_height * Config.max_window_height_percentage) - main_win_current_line,
                    lines_count
                ),
                Config.max_window_height_fallback
            ),
            lines_count
        ),
    }

    return res
end

---@param opts Setup_Opts
function Utils.process_opts(opts)
    if type(opts.diagnostics_error_highlight_group) == "string" then
        Config.diagnostic_severity_highlight_group[1] = opts.diagnostics_error_highlight_group
    end

    if type(opts.diagnostics_warn_highlight_group) == "string" then
        Config.diagnostic_severity_highlight_group[2] = opts.diagnostics_warn_highlight_group
    end

    if type(opts.diagnostics_info_highlight_group) == "string" then
        Config.diagnostic_severity_highlight_group[3] = opts.diagnostics_info_highlight_group
    end

    if type(opts.diagnostics_hint_highlight_group) == "string" then
        Config.diagnostic_severity_highlight_group[4] = opts.diagnostics_hint_highlight_group
    end

    if type(opts.default_text_highlight_group) == "string" then
        Config.default_text_highlight_group = opts.default_text_highlight_group
        Config.diagnostics_source_highlight_group = Config.default_text_highlight_group
        Config.diagnostics_code_highlight_group = Config.default_text_highlight_group
    end

    if type(opts.diagnostics_source_highlight_group) == "string" then
        Config.diagnostics_source_highlight_group = opts.diagnostics_source_highlight_group
    end

    if type(opts.diagnostics_code_highlight_group) == "string" then
        Config.diagnostics_code_highlight_group = opts.diagnostics_code_highlight_group
    end

    if type(opts.diagnostics_url_code_highlight_group) == "string" then
        Config.diagnostics_url_code_highlight_group = opts.diagnostics_url_code_highlight_group
    end

    if type(opts.diagnostics_url_highlight_group) == "string" then
        Config.diagnostics_url_highlight_group = opts.diagnostics_url_highlight_group
    end

    if type(opts.diagnostics_source_file_highlight_group) == "string" then
        Config.diagnostics_source_file_highlight_group = opts.diagnostics_source_file_highlight_group
    end

    if type(opts.unknown_diagnostics_source) == "string" then
        Config.unknown_diagnostics_source = opts.unknown_diagnostics_source
    end

    if type(opts.unknown_diagnostics_source_highlight_group) == "string" then
        Config.unknown_diagnostics_source_highlight_group = opts.unknown_diagnostics_source_highlight_group
    end

    if type(opts.max_window_width_fallback) == "number" then
        Config.max_window_width_fallback = math.floor(opts.max_window_width_fallback)
    end

    if type(opts.max_window_height_fallback) == "number" then
        Config.max_window_height_fallback = math.floor(opts.max_window_height_fallback)
    end

    if type(opts.max_window_width_percentage) == "number" then
        if opts.max_window_width_percentage > 0 and opts.max_window_width_percentage <= 1 then
            Config.max_window_width_percentage = opts.max_window_width_percentage
        end
    end

    if type(opts.max_window_height_percentage) == "number" then
        if opts.max_window_height_percentage > 0 and opts.max_window_height_percentage <= 1 then
            Config.max_window_height_percentage = opts.max_window_height_percentage
        end
    end

    if type(opts.auto_close_on_focus_lost) == "boolean" then
        Config.auto_close_on_focus_lost = opts.auto_close_on_focus_lost
    end

    if type(opts.open_key) == "string" then
        Config.open_key = { opts.open_key }
    elseif type(opts.open_key) == "table" then
        for _, key in ipairs(opts.open_key) do
            local valid = true

            if type(key) ~= "string" then
                valid = false
                break
            end

            if valid then
                Config.open_key = opts.open_key
            end
        end
    end

    if type(opts.quit_key) == "string" then
        Config.quit_key = { opts.quit_key }
    elseif type(opts.quit_key) == "table" then
        for _, key in ipairs(opts.quit_key) do
            local valid = true

            if type(key) ~= "string" then
                valid = false
                break
            end

            if valid then
                Config.quit_key = opts.quit_key
            end
        end
    end
end

return Utils
