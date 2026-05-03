local log = require("lylla.log")
local utils = require("lylla.utils")

---@class (partial) lylla.proto
---@field wins table<integer, lylla.proto>
---@field win integer
---@field modules any[]
---@field winbar any[]
---@field initialized boolean?
---@field timer uv.uv_timer_t
---@field refreshau integer
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
---@field init fun(self)
function statusline:init()
  if self.initialized then
    return
  end

  local err, err_kind
  ---@diagnostic disable-next-line: assign-type-mismatch
  self.timer, err, err_kind = vim.uv.new_timer()
  if not self.timer or err then
    vim.notify(string.format("%s\n\t%s", err_kind, err), vim.log.levels.ERROR)
    return
  end

  local refresh = require("lylla.config").get().refresh_rate
  self.timer:start(0, refresh, function()
    self:refresh()
  end)

  self.refreshau = vim.api.nvim_create_augroup(("@lylla.refresh.%d"):format(self.win), { clear = true })

  local events = self:getevents()

  for i = 1, #events do
    local event = events[i]
    local eventname, eventpattern = unpack(vim.split(event, " "), 1, 2)
    ---@cast eventname vim.api.keyset.events?
    if eventname then
      vim.api.nvim_create_autocmd(eventname, {
        group = self.refreshau,
        pattern = eventpattern,
        callback = function(ev)
          self:refresh(ev)
        end,
      })
    end
  end

  self.initialized = true
end

---@class (partial) lylla.proto
---@field close fun(self)
function statusline:close()
  self.timer:stop()
  self.timer:close()
  pcall(vim.api.nvim_del_augroup_by_id, self.refreshau)
  statusline.wins[self.win] = nil
end

---@class (partial) lylla.proto
---@field getevents fun(self): string[]
function statusline:getevents()
  local t = vim.iter(ipairs(self.modules)):fold({}, function(acc, _, module)
    if type(module) == "table" and module.fn and type(module.fn) == "function" then
      if module.opts and module.opts.events then
        return vim.iter(module.opts.events):fold(acc, function(a, event)
          a[event] = true
          return a
        end)
      end
    end
    return acc
  end)

  return vim.tbl_keys(t)
end

local function refreshcomponent(self, fn, ev)
  do
    local ok, result = pcall(fn, self, ev)
    if not ok then
      log.error("[lylla] error occured on refresh:\n\t" .. result)
    end
  end
end

---@class (partial) lylla.proto
---@field refresh fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:refresh(ev)
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(self.win) then
      return
    end

    refreshcomponent(self, statusline.set, ev)
    refreshcomponent(self, statusline.setwinbar, ev)
  end)
end

---@class (partial) lylla.proto
---@field fold fun(ev?: vim.api.keyset.create_autocmd.callback_args, modules: any[]): string
function statusline.fold(ev, modules)
  if type(modules) ~= "table" or modules == nil then
    return ""
  end

  local lst = vim
    .iter(ipairs(modules))
    :map(function(_, module)
      if type(module) == "table" and module.fn and type(module.fn) == "function" then
        if module.opts and module.opts.events then
          -- refresh from timer
          if not ev and module.prev then
            return module.prev
          end
          -- refresh from non-match event
          if ev and not vim.tbl_contains(module.opts.events, ev.event) and module.prev then
            return module.prev
          end
        end
        do
          local ok, result = pcall(module.fn)
          if not ok then
            error(result)
          end
          module.prev = result
        end
        return module.prev
      end
      if type(module) == "function" then
        local ok, result = pcall(module)
        if not ok then
          error(result)
        end
        return result
      end
      return module
    end)
    :totable()
  return utils.fold(lst)
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
  if vim.bo[buf].buftype ~= "" then
    return
  end

  local ok, result = pcall(vim.api.nvim_win_call, self.win, function()
    return self:getwinbar(ev)
  end)
  assert(ok, string.format("error occured while trying to evaluate winbar:\n\t%s", result))
  ---@cast result string

  vim.wo[self.win].winbar = result
end

---@class (partial) lylla.proto
---@field set fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:set(ev)
  local ok, result = pcall(vim.api.nvim_win_call, self.win, function()
    return self:get(ev)
  end)
  assert(ok, string.format("error occured while trying to evaluate statusline:\n\t%s", result))
  ---@cast result string

  vim.wo[self.win].statusline = result
end

return statusline
