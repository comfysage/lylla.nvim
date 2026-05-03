local M = {}

local lzrq = function(modname)
  return vim.defaulttable(function(k)
    return require(modname)[k]
  end)
end

local config = lzrq("lylla.config")

---@param cfg? lylla.config
function M.setup(cfg)
  ---@diagnostic disable-next-line: assign-type-mismatch
  cfg = cfg or {}
  config.set(config.override(cfg))
end

-- helpers

---@param fn fun(): string|any[]
---@param opts? { events: string[] }
---@return table
function M.component(fn, opts)
  local t = {}
  t.fn = fn
  t.opts = opts
  return t
end

return M
