R = function(m, ...)
	require("plenary.reload").reload_module(m, ...)
	return require(m)
end

vim.opt.rtp:prepend "."

--

pcall(function()
	require("lylla").setup()
end)

--

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*/lylla/*",
	callback = function()
		vim.schedule(function() R "lylla".init() end)
	end,
})
