if vim.g.loaded_statusline then
  return
end

vim.g.loaded_statusline = true

if vim.v.vim_did_enter > 0 then
  require("lylla").init()
else
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("lylla:init", { clear = true }),
    callback = function()
      require("lylla").init()
    end,
  })
end
