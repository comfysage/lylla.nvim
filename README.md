# lylla.nvim

a minimal statusline plugin for neovim with extensive configuration; simple by default, flexible if needed.

## features

- minimal default look, based on neovim default statusline implementation
- flexible configuration; define your own components
- lightweight design; no required dependencies

## goals

lylla is designed to be:

- minimal in features (no clutter)
- maximal in configuration
- stable and predictable; i wanted to prevent any hidden logic that i got
  annoyed by in other statusline plugins

## installation

###### `vim.pack`

```lua
vim.pack.add({ src = "comfysage/lylla.nvim" })
```

###### `lazy.nvim`

```lua
{
  "comfysage/lylla.nvim", lazy = false,
}
```

### dependencies

some of the utilities included in lylla use
[mini.nvim](https://github.com/mini-nvim/mini.nvim) but these are not required
in the default implementation.

## configuration

the default configuration is as follows:

```lua
require("lylla").setup({
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
})
```

### example configuration

#### use `mini.icons` for colors

some nice highlights that i personally use:

```lua
    hls = {
      normal = { link = "MiniIconsAzure" },
      visual = { link = "MiniIconsPurple" },
      command = { link = "MiniIconsOrange" },
      insert = { link = "MiniIconsGrey" },
      replace = { link = "MiniIconsGrey" },
      operator = { link = "NonText" },
    },
```

### example components

you can define custom components by passing lua functions:

```lua
local lylla = require("lylla")

lylla.setup({
    modules = {
        lylla.component(function()
          return "hi " .. vim.env.USER
        end, { events = { "VimEnter" } }),
    },
})
```

components return strings to be shown in the statusline and can register
autocmds to refresh them.

components can also return a tuple combining text with a highlight group:

```lua
{
    {
        { "meow", "ModeMsg" },
        { " | ", "WinSeparator" },
    },
    { fn = function() return { vim.bo.filetype, "MsgArea" } end },
}
```

these tables can be nested to any amount; they all get folded down on refresh.

### change refresh rate and events

```lua
require("lylla").setup {
  refresh_rate = 100, -- update faster
  events = { "WinEnter", "BufEnter", "CursorMoved" }, -- only update on these
}
```

(events control when the statusline is redrawn)

### add a custom module

modules are just tables that return strings.
this example shows your current working directory:

```lua
local lylla = require("lylla")

lylla.setup {
  modules = {
    "%<%f %h%w%m%r", -- filename etc
    "%=", -- spacer
    {
        fn = function()
            return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        end, opts = {
            events = { "DirChanged" },
        },
    },
  },
}
```

### conditional modules

modules can react to options, buffers, or plugins.
example: only show diagnostics if `vim.diagnostic` is loaded:

```lua
{
  lylla.component(function()
    if not package.loaded["vim.diagnostic"] then
      return ""
    end
    return vim.diagnostic.status()
  end, { events = { "DiagnosticChanged" } }),
}
```

### lsp information

lylla components has a builtin helper for getting the current lsp client.

```lua
local components = require("lylla.components")

{
  lylla.component(function()
    local clients = components.lsp_clients()
    return clients and {
      { { "lsp :: " }, { client } },
    }
  end, { events = { "FileType", "LspAttach" } }),
}
```

### winbar

the winbar can be configured in the same way as the statusline:

```lua
winbar = {
  lylla.component(function()
    return {
      utils.getfilepath(),
      utils.getfilename(),
      { " " },
      "%h%w%m%r",
    }
  end, {
    events = {
      "WinEnter",
      "BufEnter",
      "BufWritePost",
      "FileChangedShellPost",
      "Filetype",
    },
  }),
  { " " },
  lylla.component(function()
    return utils.get_searchcount()
  end),
},
```
