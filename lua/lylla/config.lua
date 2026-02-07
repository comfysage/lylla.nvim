---@module 'lylla.config'

---@class lylla.item
---@field fn fun(): any
---@field opts? { events?: string[] }

---@alias lylla.item.tuple {[1]: string, [2]?: string}

---@class lylla.config
---@field refresh_rate integer
---@field hls table<'normal'|'visual'|'command'|'insert', vim.api.keyset.highlight>
---@field modules (lylla.item|lylla.item.tuple|string)[]
---@field winbar any[]
---@field tabline (fun(): (lylla.item|lylla.item.tuple|string)[])|vim.NIL

local M, H = {}, {}

---@type lylla.config
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@text # Default ~
M.default = {
  refresh_rate = 300,
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
  tabline = vim.NIL,
}

---@type lylla.config
---@diagnostic disable-next-line: missing-fields
M.config = {}

---@return lylla.config
function M.get()
  return H.merge(M.default, M.config)
end

---@param cfg lylla.config
---@return lylla.config
function M.override(cfg)
  return H.merge(M.default, cfg)
end

---@param cfg lylla.config
function M.set(cfg)
  M.config = cfg
end

-- helpers ====================================================================

---@param tdefault lylla.config
---@param toverride lylla.config
---@return lylla.config
function H.merge(tdefault, toverride)
  return H.tmerge(tdefault, toverride)
end

---@private
---@generic T: table|any[]
---@param tdefault T
---@param toverride T
---@return T
H.tmerge = function(tdefault, toverride)
  if toverride == nil then
    return tdefault
  end

  -- do not merge lists
  if H.islist(tdefault) then
    return toverride
  end
  if vim.tbl_isempty(tdefault) then
    return toverride
  end

  return vim.iter(pairs(tdefault)):fold({}, function(tnew, k, v)
    if toverride[k] == nil then
      tnew[k] = v
      return tnew
    end
    if type(v) ~= type(toverride[k]) then
      tnew[k] = toverride[k]
      return tnew
    end
    if type(v) == "table" then
      tnew[k] = H.tmerge(v, toverride[k])
      return tnew
    end

    tnew[k] = toverride[k]
    return tnew
  end)
end

---@param t table
---@return boolean
H.islist = function(t)
  if type(t) ~= "table" then
    return false
  end

  for k, _ in ipairs(t) do
    return type(k) == "number"
  end

  -- non-numeric keys
  for _, _ in pairs(t) do
    return false
  end

  -- empty table
  return true
end

return M, H
