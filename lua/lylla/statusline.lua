local utils = require("lylla.utils")

---@class (partial) lylla.proto
---@field wins table<integer, lylla.proto>
---@field win integer
---@field modules any[]
---@field winbar any[]
local statusline = {}

statusline.wins = {}

---@class (partial) lylla.proto
---@field new fun(win: integer): lylla.proto
function statusline.new(win)
  if statusline.wins[win] then
    statusline.wins[win]:close()
  end
  local stl = setmetatable({
    win = win,
    modules = vim.deepcopy(require("lylla.config").get().modules, true),
    winbar = vim.deepcopy(require("lylla.config").get().winbar, true),
  }, { __index = statusline })
  statusline.wins[win] = stl
  return stl
end

---@class (partial) lylla.proto
---@field try_new fun(win: integer?): lylla.proto
function statusline.try_new(win)
  win = win or vim.api.nvim_get_current_win()

  if statusline.wins[win] then
    return statusline.wins[win]
  end
  return statusline.new(win)
end

---@class (partial) lylla.proto
---@field close fun(self)
function statusline:close()
  statusline.wins[self.win] = nil
end

---@param v any
---@return string?
local function display(v)
  if type(v) == "table" then
    return utils.fold(v)
  end
  if type(v) == "function" then
    local ok, result = pcall(v)
    if not ok then
      return
    end

    return display(result)
  end

  return tostring(v)
end

---@class (partial) lylla.proto
---@field fold fun(ev?: vim.api.keyset.create_autocmd.callback_args|true, modules: any[]): string
function statusline.fold(ev, modules)
  if type(modules) ~= "table" or modules == nil then
    return ""
  end

  local lst = vim
    .iter(ipairs(modules))
    :map(function(_, module)
      if type(module) ~= "table" then
        return display(module)
      end

      if not module.fn or type(module.fn) ~= "function" then
        return display(module)
      end

      if
        not (type(ev) == "boolean" and ev == true)
        and module.opts
        and module.opts.events
      then
        -- refresh from timer
        if not ev and module.prev then
          return module.prev
        end
        -- refresh from non-match event
        if
          ev
          and not vim.tbl_contains(module.opts.events, ev.event)
          and module.prev
        then
          return module.prev
        end
      end

      module.prev = display(module.fn)

      return module.prev
    end)
    :totable()
  return table.concat(lst)
end

---@class (partial) lylla.proto
---@field get fun(self, ev?: vim.api.keyset.create_autocmd.callback_args): string
function statusline:get(ev)
  return self.fold(ev, self.modules)
end

---@class (partial) lylla.proto
---@field getwinbar fun(self, ev?: vim.api.keyset.create_autocmd.callback_args): string
function statusline:getwinbar(ev)
  return self.fold(ev, self.winbar)
end

---@class (partial) lylla.proto
---@field setwinbar fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:setwinbar(ev)
  local buf = vim.api.nvim_win_get_buf(self.win)
  if vim.bo[buf].buftype ~= "" and vim.bo[buf].buftype ~= "nowrite" then
    return
  end

  local ok, result = pcall(vim.api.nvim_win_call, self.win, function()
    return self:getwinbar(ev)
  end)
  assert(
    ok,
    string.format(
      "error occured while trying to evaluate winbar:\n\t%s",
      result
    )
  )
  ---@cast result string

  vim.wo[self.win].winbar = result
end

---@class (partial) lylla.proto
---@field set fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:set(ev)
  local ok, result = pcall(vim.api.nvim_win_call, self.win, function()
    return self:get(ev)
  end)
  assert(
    ok,
    string.format(
      "error occured while trying to evaluate statusline:\n\t%s",
      result
    )
  )
  ---@cast result string

  vim.wo[self.win].statusline = result
end

return statusline
