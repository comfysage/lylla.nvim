local M = {}

local lzrq = function(modname)
  return setmetatable({
    modname = modname,
  }, {
    __index = function(t, k)
      local m = rawget(t, "modname")
      return m and require(m)[k] or nil
    end,
  })
end

local config = lzrq("lylla.config")
local utils = lzrq("lylla.utils")

---@type table<'normal'|'visual'|'command'|'insert'|'replace'|'operator', vim.api.keyset.highlight>
local default_hls = {
  normal = { link = "@property" },
  visual = { link = "@constant" },
  command = { link = "@function" },
  insert = { link = "@variable" },
  replace = { link = "@type" },
  operator = { link = "NonText" },
}

---@param cfg? lylla.config
function M.setup(cfg)
  cfg = cfg or {}
  config.set(config.override(cfg))
end

function M.inithls()
  vim.iter(pairs(default_hls)):each(function(mode, defaulthl)
    local name = utils.get_modehl_name(mode)

    local hl = config.get().hls[mode]
    if hl then
      vim.api.nvim_set_hl(0, name, hl)
      return
    end

    if vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = name })) then
      vim.api.nvim_set_hl(0, name, defaulthl)
    end
  end)
end

function M.resethl()
  vim.iter(pairs(default_hls)):each(function(mode, _)
    local name = utils.get_modehl_name(mode)
    vim.api.nvim_set_hl(0, name, {})
  end)
end

M.initialized = false

function M.init()
  if M.initialized then
    return
  end

  M.initialized = true

  vim.api.nvim_create_autocmd({ "UIEnter", "WinNew", "WinEnter" }, {
    group = vim.api.nvim_create_augroup("lylla:win", { clear = true }),
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if not require("lylla.statusline").wins[win] then
        require("lylla.statusline"):new(win):init()
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = vim.api.nvim_create_augroup("lylla:close", { clear = true }),
    callback = function(ev)
      local stl = require("lylla.statusline").wins[ev.match]
      if stl then
        stl:close()
      end
    end,
  })

  if config.get().tabline ~= vim.NIL then
    require("lylla.tabline").setup()
  end

  vim.api.nvim_create_autocmd("ColorSchemePre", {
    group = vim.api.nvim_create_augroup("lylla:resethl", { clear = true }),
    callback = function()
      M.resethl()
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("lylla:inithls", { clear = true }),
    callback = function()
      M.inithls()
    end,
  })
  M.inithls()
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
