--
-- PAPIS | TELESCOPE | ACTIONS
--
--
-- With some code from: https://github.com/nvim-telescope/telescope-bibtex.nvim

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Path = require("plenary.path")
local db = require("papis.sqlite-wrapper")

local utils = require("papis.utils")

local M = {}

--- This is very similar to the _get_parent function of plenary, but the latter
--- will not respect symlinks.
local get_parent = (function()
    local os = string.lower(jit.os)
    local sep = ""
    if os ~= "windows" then
      sep = "/"
    else
      sep = "\\"
    end
    local formatted = string.format("^(.+)%s[^%s]+", sep, sep)
    return function(path)
        return Path:new{path:match(formatted)}
    end
end)()


---This function inserts a formatted reference string at the cursor
---@param format_string string @The string to be inserted.
---       $F will be replaced with the absolute location of the first file
---       attached to the entry, $f with the relative path.
---@return function
M.ref_insert = function(format_string)
  return function(prompt_bufnr)
    local entry = string.format(format_string, action_state.get_selected_entry().id.ref)
    if action_state.get_selected_entry().id.files == nil then
        entry = entry:gsub("$F", "")
        entry = entry:gsub("$f", "")
    else
        local file_path = Path:new{action_state.get_selected_entry().id.files[1]}
        entry = entry:gsub("$F", file_path:normalize())
        entry = entry:gsub("$f", file_path:make_relative())
    end
    local info_path = Path:new{db.metadata:get_value({ entry = action_state.get_selected_entry().id.id}, "path")}
    entry = entry:gsub("$I", info_path:normalize())
    entry = entry:gsub("$i", info_path:make_relative())
    --- `get_parent` might work better w. sym-links
    local dir_path = get_parent(info_path:normalize())
    entry = entry:gsub("$D", dir_path:normalize())
    entry = entry:gsub("$d", dir_path:make_relative())
    actions.close(prompt_bufnr)
    vim.api.nvim_put({ entry }, "", false, true)
  end
end

---This function opens the files attached to the current entry
---@return function
M.open_file = function()
  return function(prompt_bufnr)
    local papis_id = action_state.get_selected_entry().id.papis_id
    actions.close(prompt_bufnr)
    utils:do_open_attached_files(papis_id)
  end
end

---This function opens the note attached to the current entry
---@return function
M.open_note = function()
  return function(prompt_bufnr)
    local papis_id = action_state.get_selected_entry().id.papis_id
    actions.close(prompt_bufnr)
    utils:do_open_text_file(papis_id, "note")
  end
end

---This function opens the info_file containing this entry's information
---@return function
M.open_info = function()
  return function(prompt_bufnr)
    local papis_id = action_state.get_selected_entry().id.papis_id
    actions.close(prompt_bufnr)
    utils:do_open_text_file(papis_id, "info")
  end
end

return M
