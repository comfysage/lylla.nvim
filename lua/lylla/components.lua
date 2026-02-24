local components = {}

---@param props { buffer?: integer, limit?: integer, sep?: string, filter?: fun(client: vim.lsp.Client): boolean }
function components.lsp_clients(props)
  props = props or {}
  local buffer = props.buffer or 0

  local clients = vim.iter(vim.lsp.get_clients({ bufnr = buffer })):map(function(
    client --[[@as vim.lsp.Client]]
  )
    if props.filter and not props.filter(client) then
      return
    end
    return client.config.name
  end)
  return table.concat(clients, props.sep or " + ", 1, vim.F.if_nil(props.limit))
end

return components
