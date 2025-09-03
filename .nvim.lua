R = function(m, ...)
  require("plenary.reload").reload_module(m, ...)
  return require(m)
end

vim.opt.rtp:prepend(".")

--

vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    pcall(function()
      R("lylla")
    end)
  end,
})
