# diagnostics-details.nvim

`diagnostics-details.nvim` is a Neovim plugin that enhances the default diagnostic window, providing more detailed information.

![Screenshot_20240531_221947](https://github.com/hsaker312/diagnostics-details.nvim/assets/168933530/d3a15297-d94c-4fd9-b6e0-d8614f463fb0)
![Screenshot_20240531_222148](https://github.com/hsaker312/diagnostics-details.nvim/assets/168933530/1c8b6a7b-e9e3-44f8-b6d7-0baf9a8cd171)
![Screenshot_20240531_222353](https://github.com/hsaker312/diagnostics-details.nvim/assets/168933530/be3b1b72-24aa-47cd-ba14-80a9c7360c36)

## Features

- Shows more details then vim.diagnostic.open_float()
- Open links and files directly from the diagnostics window
- Configurable highlight groups, keymaps and window dimensions

## Installation

```lua
{
  'hsaker312/diagnostics-details.nvim',
  config = function()
    require('diagnostics-details').setup({
      -- Your configuration here
    })
  end
}
```

## Usage

Show the diagnostics details window:

```lua
require('diagnostics-details').show()
```
or
```vim
:DiagnosticsDetailsOpenFloat
```

Toggle diagnostics details window persist:
```lua
require('diagnostics-details').toggle_persist()
```
or
```vim
:DiagnosticsDetailsTogglePersist
```

## Configuration

You can configure `diagnostics-details.nvim` by passing options to the `setup` function. Below are the available options with their default values:

| Field                                     | Type                        | Description                                                     | Default                           |
|-------------------------------------------|-----------------------------|-----------------------------------------------------------------|-----------------------------------|
| `diagnostics_error_highlight_group`       | `string?`                   | Highlight group for error diagnostics                           | `"DiagnosticFloatingError"`       |
| `diagnostics_warn_highlight_group`        | `string?`                   | Highlight group for warning diagnostics                         | `"DiagnosticFloatingWarn"`        |
| `diagnostics_info_highlight_group`        | `string?`                   | Highlight group for info diagnostics                            | `"DiagnosticFloatingInfo"`        |
| `diagnostics_hint_highlight_group`        | `string?`                   | Highlight group for hint diagnostics                            | `"DiagnosticFloatingHint"`        |
| `default_text_highlight_group`            | `string?`                   | Default highlight group for text                                | `"NormalFloat"`                   |
| `diagnostics_source_highlight_group`      | `string?`                   | Highlight group for diagnostics source                          | `"NormalFloat"`                   |
| `diagnostics_code_highlight_group`        | `string?`                   | Highlight group for diagnostics code                            | `"NormalFloat"`                   |
| `diagnostics_url_code_highlight_group`    | `string?`                   | Highlight group for diagnostics URL code<br/>Same as diagnostics_{severity}_highlight_group if nil                        | `nil`                             |
| `diagnostics_url_highlight_group`         | `string?`                   | Highlight group for diagnostics URL                             | `"Comment"`                       |
| `diagnostics_source_file_highlight_group` | `string?`                   | Highlight group for diagnostics source file                     | `"Underlined"`                    |
| `unknown_diagnostics_source`              | `string?`                   | Default text for unknown diagnostics source                     | `"Vim-Diagnostics"`               |
| `unknown_diagnostics_source_highlight_group` | `string?`                | Highlight group for unknown diagnostics source                  | `"Comment"`                       |
| `max_window_width_fallback`               | `integer?`                  | Fallback width for the diagnostics window                       | `100`                             |
| `max_window_height_fallback`              | `integer?`                  | Fallback height for the diagnostics window                      | `5`                               |
| `max_window_width_percentage`             | `float?`                    | Max width percentage for the diagnostics window (0.0 - 1.0)                 | `0.9`                             |
| `max_window_height_percentage`            | `float?`                    | Max height percentage for the diagnostics window (0.0 - 1.0)                | `0.65`                            |
| `auto_close_on_focus_lost`                | `boolean?`                  | Auto close diagnostics window when focus is lost                | `true`                            |
| `open_key`                                | `string? or table<integer, string>?` | Key(s) to open a link or file                              | `{"<CR>", "<2-LeftMouse>"}`       |
| `quit_key`                                | `string? or table<integer, string>?` | Key(s) to quit the diagnostics window                         | `{"q", "<esc>"}`                  |


## License

This project is licensed under the MIT License.




