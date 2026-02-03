local utils = {}

function utils.get_client()
  local buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
  local result = vim.iter(vim.lsp.get_clients({ bufnr = 0 })):find(function(
    client --[[@as vim.lsp.Client]]
  )
    return vim.iter(ipairs(client.config.filetypes)):any(function(_, ft)
      return ft == buf_ft
    end)
  end)
  if result then
    return result.config.name
  end
end

--- flatten list so all children have level of depth
---@param lst table
---@param maxdepth integer
function utils.flatten(lst, maxdepth)
  ---@param _t any[]
  ---@return integer
  local function _depth(_t)
    return vim.iter(_t):fold(1, function(maxd, v)
      if type(v) == "table" then
        local d = 1 + _depth(v)
        if d > maxd then
          return d
        end
      end
      return maxd
    end)
  end

  local result = {}
  ---@param _t any[]
  local function _flatten(_t)
    local n = #_t
    for i = 1, n do
      local v = _t[i]
      if type(v) ~= "table" or _depth(v) <= maxdepth then
        table.insert(result, v)
      else
        _flatten(v)
      end
    end
  end
  _flatten(lst)
  return result
end

function utils.getfilename()
  local _, default_file_hl = require("mini.icons").get("default", "file")

  local name = vim.fn.expand("%:t")

  local file_icon_raw, file_icon_hl

  if vim.bo.buftype ~= "" then
    local filetype = vim.bo.filetype
    file_icon_raw, file_icon_hl = require("mini.icons").get("filetype", filetype)
  else
    file_icon_raw, file_icon_hl = require("mini.icons").get("file", name)
  end

  return { { name, default_file_hl }, { " " }, { file_icon_raw, file_icon_hl } }
end

function utils.getfilepath()
  local path = vim.fn.expand("%:p:~:.")

  local file_path_list = {}
  local _ = string.gsub(path, "[^/]+", function(w)
    table.insert(file_path_list, w)
  end)

  local filepath = vim.iter(ipairs(file_path_list)):fold("", function(acc, i, fragment)
    if i == #file_path_list then
      return acc
    end
    acc = acc .. fragment .. "/"
    return acc
  end)

  return { filepath, "Directory" }
end

function utils.get_searchcount()
  local result = vim.fn.searchcount({ recompute = 1 })
  if vim.v.hlsearch ~= 1 then
    return ""
  end
  if vim.tbl_isempty(result) then
    return ""
  end
  local term = vim.fn.getreg("/")
  local display
  if result.incomplete == 1 then
    -- timed out
    display = "[?/??]"
  elseif result.incomplete == 2 then
    -- max count exceeded
    if result.total > result.maxcount and result.current > result.maxcount then
      display = string.format("[>%d/>%d]", result.current, result.total)
    elseif result.total > result.maxcount then
      display = string.format("[%d/>%d]", result.current, result.total)
    end
  end
  display = display or string.format("[%d/%d]", result.current, result.total)

  return { { string.format("/%s", term), "IncSearch" }, { " " }, { display, "MsgSeparator" } }
end

---@param mode string
---@return string
function utils.get_modehl_name(mode)
  return "@lylla." .. mode
end

---@return string
function utils.get_modehl()
  local mode = vim.api.nvim_get_mode().mode

  if string.match(mode, "^n") then
    return utils.get_modehl_name("normal")
  end

  if string.match(mode, "^[vVs]") then
    return utils.get_modehl_name("visual")
  end

  if string.match(mode, "^c") then
    return utils.get_modehl_name("command")
  end

  if string.match(mode, "^[irRt]") then
    return utils.get_modehl_name("insert")
  end

  return mode
end

return utils
