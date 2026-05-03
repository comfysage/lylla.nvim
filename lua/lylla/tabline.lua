vim.g.tablinefn = function()
  local tabfn = require("lylla.config").get().tabline
  if tabfn == vim.NIL or type(tabfn) ~= "function" then
    return
  end

  local utils = require("lylla.utils")

  return utils.fold(tabfn())
end

local M, H = {}, {}

M.setup = function()
  vim.o.tabline = "%!v:lua.vim.g.tablinefn()"
end

-- helpers ====================================================================

--- 0-indexed range interator
---@overload fun(i: integer, j: integer): Iter
---@overload fun(j: integer): Iter
function H.range(...)
  local args = { ... }

  local i, j
  if #args == 1 then
    i, j = 0, args[1]
  else
    i, j = args[1], args[2]
  end

  return vim.iter(setmetatable({
    idx = i,
  }, {
    __call = function(t)
      local index = t.idx + 1
      if index > j then
        return
      end
      t.idx = index
      return t.idx
    end,
  }))
end

function H.fortabwins(tabn, f)
  local buflist = vim.fn.tabpagebuflist(tabn)

  return H.range(vim.fn.tabpagewinnr(tabn, "$")):fold({}, function(t, i)
    local buf = buflist[i]
    table.insert(t, { f(i, i == vim.fn.tabpagewinnr(tabn), buf) })
    return t
  end)
end

function H.fortabs(f)
  return H.range(vim.fn.tabpagenr("$")):fold({}, function(t, i)
    table.insert(t, { f(i, i == vim.fn.tabpagenr()) })
    return t
  end)
end

return vim.defaulttable(function(k)
  return M[k] or H[k]
end)
