local utils = require("lylla.utils")

---@class lylla.proto
---@field wins table<integer, table>
---@field win integer
---@field modules any[]
---@field winbar any[]
---@field timer uv.uv_timer_t
---@field refreshau integer
local statusline = {}

statusline.wins = {}

---@class lylla.proto
---@field new fun(self, win): lylla.proto
function statusline:new(win)
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

---@class lylla.proto
---@field init fun(self)
function statusline:init()
  local err, err_kind
  ---@diagnostic disable-next-line: assign-type-mismatch
  self.timer, err, err_kind = vim.uv.new_timer()
  if not self.timer or err then
    vim.api.nvim_echo({ { err_kind }, { "\n\t" }, { err } }, true, { err = true })
    return
  end

  local refresh = require("lylla.config").get().refresh_rate
  self.timer:start(0, refresh, function()
    self:refresh()
  end)

  self.refreshau = vim.api.nvim_create_autocmd(require("lylla.config").get().events, {
    group = vim.api.nvim_create_augroup("lylla:refresh", { clear = false }),
    callback = function(ev)
      self:refresh(ev)
    end,
  })
end

---@class lylla.proto
---@field close fun(self)
function statusline:close()
  self.timer:stop()
  self.timer:close()
  vim.api.nvim_del_autocmd(self.refreshau)
  statusline.wins[self.win] = nil
end

---@class lylla.proto
---@field refresh fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:refresh(ev)
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(self.win) then
      return
    end

    self:set(ev)
    self:setwinbar(ev)
  end)
end

---@class lylla.proto
---@field fold fun(self, ev?: vim.api.keyset.create_autocmd.callback_args, modules: any[]): string
function statusline:fold(ev, modules)
  local lst = vim
    .iter(ipairs(modules))
    :map(function(_, module)
      if type(module) == "table" and module._type == "component" then
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
        module.prev = module.fn()
        return module.prev
      end
      if type(module) == "function" then
        module = module()
      end
      return module
    end)
    :totable()
  lst = utils.flatten(lst, 1)
  return vim.iter(lst):fold("", function(str, module)
    if type(module) ~= "table" or #module == 0 then
      return str
    end
    local text = module[1]
    if #module > 1 then
      return str .. "%#" .. module[2] .. "#" .. text .. "%*"
    end
    return str .. "%*" .. text
  end)
end

---@class lylla.proto
---@field get fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:get(ev)
  return self:fold(ev, self.modules)
end

---@class lylla.proto
---@field getwinbar fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:getwinbar(ev)
  return self:fold(ev, self.winbar)
end

---@class lylla.proto
---@field setwinbar fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:setwinbar(ev)
  local buf = vim.api.nvim_win_get_buf(self.win)
  if vim.bo[buf].buftype ~= "" then
    return
  end

  local ok, result = pcall(vim.api.nvim_win_call, self.win, function()
    return self:getwinbar(ev)
  end)
  if not ok then
    return
  end

  vim.wo[self.win].winbar = result
end

---@class lylla.proto
---@field set fun(self, ev?: vim.api.keyset.create_autocmd.callback_args)
function statusline:set(ev)
  local ok, result = pcall(vim.api.nvim_win_call, self.win, function()
    return self:get(ev)
  end)
  if not ok then
    return
  end

  vim.wo[self.win].statusline = result
end

return statusline
