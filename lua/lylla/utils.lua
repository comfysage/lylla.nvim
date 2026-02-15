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

local sfmt = "%s%%*%s"
local sfmt_inherit = "%s%s"
-- str, hl_name, text
local hlfmt = "%s%%#%s#%s"
local hlfmt_inherit = "%s%%$%s$%s"

---@param str string
---@param text string
---@param inherit boolean
---@param hl? string
---@return string
local function strfmt(str, text, inherit, hl)
  if hl then
    return string.format(inherit and hlfmt_inherit or hlfmt, str, hl, text)
  end
  return string.format(inherit and sfmt_inherit or sfmt, str, text)
end

function utils.fold(lst)
  vim.validate("lst", lst, "table")

  lst = utils.flatten(lst, 1)
  ---@type string|false
  local section = false
  return vim.iter(ipairs(lst)):fold("", function(str, _, module)
    local inherit = not not section
    if type(module) == "string" and #module > 0 then
      return strfmt(str, module, inherit)
    end
    if type(module) ~= "table" then
      return str
    end
    if module.section ~= nil and (type(module.section) == "string" or module.section == false) then
      section = module.section
      if section then
        return string.format("%s%%#%s#", str, module.section)
      end
      return str
    end
    local text = module[1]
    if text == nil or type(text) ~= "string" or #text == 0 then
      return str
    end
    local hl = module[2]
    if not hl then
      return strfmt(str, text, inherit)
    end
    if type(hl) == "string" and #hl > 0 then
      return strfmt(str, text, inherit, hl)
    elseif type(hl) == "table" and (hl.fg or hl.bg or hl.link) then
      inherit = inherit or hl.inherit
      hl.inherit = nil
      local hl_name = hl.link
      if not hl_name then
        hl_name = utils.create_hl(hl)
      end
      return strfmt(str, text, inherit, hl_name)
    elseif type(hl) == "table" and hl.inherit then
      return strfmt(str, text, true)
    end

    return strfmt(str, text, inherit)
  end)
end

---@param hl_name string
---@return vim.api.keyset.highlight
function utils.reverse_hl(hl_name)
  local hl = vim.api.nvim_get_hl(0, { name = hl_name })
  if vim.tbl_isempty(hl) or (not hl.fg and not hl.bg and not hl.link) then
    return {}
  end
  if hl.link then
    return utils.reverse_hl(hl.link)
  end
  local rev = vim.deepcopy(hl)
  rev.fg = hl.bg
  rev.bg = hl.fg
  ---@diagnostic disable-next-line: return-type-mismatch
  return rev
end

---@param hl vim.api.keyset.highlight
function utils.create_hl(hl)
  local hl_name = string.format("@lylla.%s", vim.fn.sha256(vim.inspect(hl)))
  vim.schedule(function()
    vim.api.nvim_set_hl(0, hl_name, hl)
  end)
  return hl_name
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
  local hl_name = utils.get_modehl_name("normal")

  if string.match(mode, "^[vVs]") then
    hl_name = utils.get_modehl_name("visual")
  elseif string.match(mode, "^c") then
    hl_name = utils.get_modehl_name("command")
  elseif string.match(mode, "^[irRt]") then
    hl_name = utils.get_modehl_name("insert")
  end

  return hl_name, utils.create_hl(utils.reverse_hl(hl_name))
end

return utils
