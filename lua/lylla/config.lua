---@module 'lylla.config'

---@class lylla.item
---@field fn fun(): any
---@field opts? { events?: string[] }

---@alias lylla.item.tuple {[1]: string, [2]?: string}

---@class lylla.config
---@field refresh_rate integer
---@field events string[]
---@field hls table<'normal'|'visual'|'command'|'insert', vim.api.keyset.highlight>
---@field modules (lylla.item|lylla.item.tuple|string)[]
---@field winbar any[]

local M = {}

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
  hls = {},
  modules = {
    "%<%f %h%w%m%r",
    "%=",
    {
      fn = function()
        if vim.o.showcmdloc == "statusline" then
          return "%-10.S"
        end
        return ""
      end,
    },
    { " " },
    {
      fn = function()
        if not vim.b.keymap_name then
          return ""
        end
        return "<" .. vim.b.keymap_name .. ">"
      end,
    },
    { " " },
    {
      fn = function()
        if vim.bo.busy > 0 then
          return "◐ "
        end
        return ""
      end,
    },
    { " " },
    {
      fn = function()
        if not package.loaded["vim.diagnostic"] then
          return ""
        end
        return vim.diagnostic.status()
      end,
      opts = {
        events = { "DiagnosticChanged" },
      },
    },
    { " " },
    {
      fn = function()
        if not vim.o.ruler then
          return ""
        end
        if vim.o.rulerformat == "" then
          return "%-14.(%l,%c%V%) %P"
        end
        return vim.o.rulerformat
      end,
    },
  },
  winbar = {},
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
