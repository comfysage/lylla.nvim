---@module 'lylla.config'

---@class lylla.config
---@field refresh_rate integer
---@field events string[]
---@field prefix string
---@field hls table<'normal'|'visual'|'command'|'insert', vim.api.keyset.highlight>
---@field modules any[]
---@field winbar any[]

local utils = require("lylla.utils")

local M = {}

---@param fn fun(): string[]
---@param opts? { events: string[] }
---@return table
local function component(fn, opts)
  local t = { _type = "component" }
  t.fn = fn
  t.opts = opts
  return t
end

---@type lylla.config
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@text # Default ~
M.default = {
  refresh_rate = 300,
  events = {
    "WinEnter",
    "BufEnter",
    "BufWritePost",
    "SessionLoadPost",
    "FileChangedShellPost",
    "VimResized",
    "Filetype",
    "CursorMoved",
    "CursorMovedI",
    "ModeChanged",
    "CmdlineEnter",
  },
  prefix = "▌",
  hls = {},
  modules = {
    component(function()
      local prefix = require("lylla.config").get().prefix
      local modehl = utils.get_modehl()
      return {
        { prefix, modehl },
        { "[" .. vim.api.nvim_get_mode().mode .. "]", modehl },
      }
    end, {
      events = { "ModeChanged", "CmdlineEnter" },
    }),
    { " " },
    component(function()
      return {
        utils.getfilepath(),
        utils.getfilename(),
        { " " },
      }
    end, {
      events = {
        "WinEnter",
        "BufEnter",
        "BufWritePost",
        "FileChangedShellPost",
        "Filetype",
      },
    }),
    { " " },
    component(function()
      return { utils.get_searchcount() }
    end),
    { "%=" },
    {},
    { "%=" },
    component(function()
      return {
        { { "lsp :: " }, { utils.get_client() or "none" } },
        { " | ", "NonText" },
        { { "fmt :: " }, { utils.get_fmt() or "none" } },
        { " | ", "NonText" },
      }
    end, { events = { "FileType" } }),
    { "%p%%" },
    { " | ", "NonText" },
    { "%L lines" },
    { " | ", "NonText" },
    { "%l:%c" },
    { " " },
  },
  winbar = {
    component(function()
      local prefix = require("lylla.config").get().prefix
      local modehl = utils.get_modehl()
      return {
        { prefix, modehl },
      }
    end, {
      events = { "ModeChanged", "CmdlineEnter" },
    }),
    { " " },
    component(function()
      return {
        utils.getfilepath(),
        utils.getfilename(),
        { " " },
      }
    end, {
      events = {
        "WinEnter",
        "BufEnter",
        "BufWritePost",
        "FileChangedShellPost",
        "Filetype",
      },
    }),
    { " " },
    component(function()
      return { utils.get_searchcount() }
    end),
  },
}

---@type lylla.config
---@diagnostic disable-next-line: missing-fields
M.config = {}

---@private
---@generic T: table|any[]
---@param tdefault T
---@param toverride T
---@return T
local function tmerge(tdefault, toverride)
  if toverride == nil then
    return tdefault
  end

  if vim.islist(tdefault) then
    return toverride
  end
  if vim.tbl_isempty(tdefault) then
    return toverride
  end

  return vim.iter(pairs(tdefault)):fold({}, function(tnew, k, v)
    if toverride[k] == nil or type(v) ~= type(toverride[k]) then
      tnew[k] = v
      return tnew
    end
    if type(v) == "table" then
      tnew[k] = tmerge(v, toverride[k])
      return tnew
    end

    tnew[k] = toverride[k]
    return tnew
  end)
end

---@param tdefault lylla.config
---@param toverride lylla.config
---@return lylla.config
function M.merge(tdefault, toverride)
  if vim.fn.has("nvim-0.11.0") == 1 then
    toverride =
      vim.tbl_deep_extend("keep", toverride, { editor = { float = { solid_border = vim.o.winborder == "solid" } } })
  end
  return tmerge(tdefault, toverride)
end

---@return lylla.config
function M.get()
  return M.merge(M.default, M.config)
end

---@param cfg lylla.config
---@return lylla.config
function M.override(cfg)
  return M.merge(M.default, cfg)
end

---@param cfg lylla.config
function M.set(cfg)
  M.config = cfg
end

return M
