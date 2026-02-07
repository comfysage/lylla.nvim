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
  vim.validate("lst", lst, "table")
  vim.validate("maxdepth", maxdepth, "number")

  ---@param _t any[]
  ---@return integer
  local function _depth(_t)
    return vim.iter(ipairs(_t)):fold(1, function(maxd, _, v)
      if type(v) == "table" and vim.islist(v) then
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
      if type(v) ~= "table" or (not vim.islist(v)) or _depth(v) <= maxdepth then
        table.insert(result, v)
      else
        _flatten(v)
      end
    end
  end
  _flatten(lst)
  return result
end

function utils.fold(lst)
  vim.validate("lst", lst, "table")

  lst = utils.flatten(lst, 1)
  return vim.iter(ipairs(lst)):fold("", function(str, _, module)
    if type(module) == "string" and #module > 0 then
      return str .. module
    end
    if type(module) ~= "table" or #module == 0 then
      return str
    end
    local text = module[1]
    if text == nil or type(text) ~= "string" or #text == 0 then
      return str
    end
    local hl = module[2]
    if not hl then
      return string.format("%s%%*%s", str, text)
    end
    if type(hl) == "string" and #hl > 0 then
      return string.format("%s%%#%s#%s%%*", str, hl, text)
    elseif type(hl) == "table" and (hl.fg or hl.bg or hl.link) then
      local hl_name = string.format("@lylla.%s", vim.fn.sha256(vim.inspect(hl)))
      vim.schedule(function()
        vim.api.nvim_set_hl(0, hl_name, hl)
      end)
      return string.format("%s%%#%s#%s%%*", str, hl_name, text)
    end

    return string.format("%s%%*%s", str, text)
  end)
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
