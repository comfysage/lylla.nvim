local logger = vim.log.new({
  name = "lylla",
  current_level = vim.log.levels.DEBUG,
})

local lylla = {}

local lzrq = function(modname)
  return vim.defaulttable(function(k)
    return require(modname)[k]
  end)
end

local config = lzrq("lylla.config")
local statusline = lzrq("lylla.statusline")

-- setup ======================================================================

---@param cfg lylla.config
local function getevents(cfg)
  local modules = cfg.modules

  local t = vim.iter(ipairs(modules)):fold({}, function(acc, _, module)
    if
      type(module) == "table"
      and module.fn
      and type(module.fn) == "function"
    then
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

lylla.timer = nil
lylla.group = nil

---@param cfg? lylla.config
function lylla.setup(cfg)
  ---@diagnostic disable-next-line: assign-type-mismatch
  cfg = cfg or {}
  config.set(config.override(cfg))

  lylla.group = vim.api.nvim_create_augroup("@lylla.refresh", { clear = true })
  local events = getevents(config.get())

  for i = 1, #events do
    local event = events[i]
    local eventname, eventpattern = unpack(vim.split(event, " "), 1, 2)
    ---@cast eventname vim.api.keyset.events?
    if eventname then
      vim.api.nvim_create_autocmd(eventname, {
        group = lylla.group,
        pattern = eventpattern,
        callback = function(ev)
          lylla.refresh(ev)
        end,
      })
    end
  end
end

lylla._init = false

function lylla.init()
  if lylla._init then
    vim.notify("lylla has already been initialized", vim.log.levels.ERROR)
    return
  end

  local err, err_kind
  ---@diagnostic disable-next-line: assign-type-mismatch
  lylla.timer, err, err_kind = vim.uv.new_timer()
  if not lylla.timer or err then
    vim.notify(string.format("%s\n\t%s", err_kind, err), vim.log.levels.ERROR)
    return
  end

  -- TODO: only refresh visible windows
  local refresh = config.get().refresh_rate --[[@as integer]]
  lylla.timer:start(0, refresh, function()
    lylla.refresh()
  end)

  lylla._init = true
end

---@param self lylla.proto
---@param fn fun(self: lylla.proto, ev?: vim.api.keyset.create_autocmd.callback_args|true)
---@param ev? vim.api.keyset.create_autocmd.callback_args|true
local function refreshcomponent(self, fn, ev)
  do
    local ok, result = pcall(fn, self, ev)
    if not ok then
      logger.error("error occured on refresh:\n\t" .. result)
    end
  end
end

---@param ev? vim.api.keyset.create_autocmd.callback_args|true
function lylla.refresh(ev)
  if not lylla._init then
    return
  end

  vim.schedule(function()
    local wins = statusline.wins
    for win, st in pairs(wins) do
      if not vim.api.nvim_win_is_valid(win) then
        st:close()
      else
        refreshcomponent(st, statusline.set, ev)
        refreshcomponent(st, statusline.setwinbar, ev)
      end
    end
  end)
end

-- helpers ====================================================================

---@param fn fun(): string|any[]
---@param opts? { events: string[] }
---@return table
function lylla.component(fn, opts)
  return { fn = fn, opts = opts }
end

return lylla
