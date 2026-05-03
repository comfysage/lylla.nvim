if vim.g.loaded_lylla then
  return
end

vim.g.loaded_lylla = true

local lzrq = function(modname)
  return vim.defaulttable(function(k)
    return require(modname)[k]
  end)
end

local config = lzrq("lylla.config")
local utils = lzrq("lylla.utils")

-- highlights =================================================================

---@type table<'normal'|'visual'|'command'|'insert'|'replace'|'operator', vim.api.keyset.highlight>
local default_hls = {
  normal = { link = "@property" },
  visual = { link = "@constant" },
  command = { link = "@function" },
  insert = { link = "@variable" },
  replace = { link = "@type" },
  operator = { link = "NonText" },
}

local function set_hl(name, hl)
  hl.default = true
  vim.api.nvim_set_hl(0, name, hl)
end

local function inithls()
  vim.iter(pairs(default_hls)):each(function(mode, defaulthl)
    local hl = config.get().hls[mode]
    local name, revname = utils.get_modehl_name(mode)
    if hl then
      set_hl(name, hl)
    elseif vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = name })) then
      set_hl(name, defaulthl)
    end
    set_hl(revname, utils.reverse_hl(name))
  end)
end

-- init =======================================================================

local function init()
  vim.api.nvim_create_autocmd({ "UIEnter", "WinNew", "WinEnter" }, {
    group = vim.api.nvim_create_augroup("@lylla.win", { clear = true }),
    callback = function()
      require("lylla.statusline").try_new():init()
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = vim.api.nvim_create_augroup("@lylla.close", { clear = true }),
    callback = function(ev)
      ---@cast ev +{match: integer}
      local stl = require("lylla.statusline").wins[ev.match]
      if stl then
        stl:close()
      end
    end,
  })

  if config.get().tabline ~= vim.NIL then
    require("lylla.tabline").setup()
  end

  vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
    group = vim.api.nvim_create_augroup("@lylla.hls", { clear = true }),
    callback = function()
      inithls()
    end,
  })
end

if vim.v.vim_did_enter > 0 then
  init()
else
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("@lylla.init", { clear = true }),
    callback = function()
      init()
    end,
  })
end
