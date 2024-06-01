---@class Utils
Utils = {}

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
            math.max(math.min(math.floor(main_win_width * 0.9) - main_win_current_col, max_line_len), 100),
            max_line_len
        ),
        height = math.min(
            math.max(math.min(math.floor(main_win_height * 0.65) - main_win_current_line, lines_count), 5),
            lines_count
        ),
    }

    return res
end

return Utils
