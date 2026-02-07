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

function H.fortabwins(tabn, f)
  local buflist = vim.fn.tabpagebuflist(tabn)

  return vim
    .iter(setmetatable({
      idx = 0,
    }, {
      __call = function(t)
        local i = t.idx + 1
        if i > vim.fn.tabpagewinnr(tabn, "$") then
          return
        end
        t.idx = i
        return t.idx
      end,
    }))
    :fold({}, function(t, i)
      local buf = buflist[i]
      table.insert(t, { f(i, i == vim.fn.tabpagewinnr(tabn), buf) })
      return t
    end)
end

function H.fortabs(f)
  return vim
    .iter(setmetatable({
      idx = 0,
    }, {
      __call = function(t)
        local i = t.idx + 1
        if i > vim.fn.tabpagenr("$") then
          return
        end
        t.idx = i
        return t.idx
      end,
    }))
    :fold({}, function(t, i)
      table.insert(t, { f(i, i == vim.fn.tabpagenr()) })
      return t
    end)
end

return vim.defaulttable(function(k)
  return M[k] or H[k]
end)
