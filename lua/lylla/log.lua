---@module 'lylla.log'

local log = {}

log.stack = {}

local function getdebuginfo()
  local i = 3
  local info = debug.getinfo(i, "nSf")
  local nextinfo = debug.getinfo(i + 1, "n")
  while nextinfo and info.name == nil do
    info = nextinfo
    i = i + 1
    nextinfo = debug.getinfo(i + 1, "n")
  end
  return info
end

--- any message will not be displayed unless `'debug'` is set to `msg`.
--- this is a purposeful design decisison made to avoid flooding the user with errors.
--- this design decision also means that modules can silently fail.
---@param msg string
---@param level integer
function log.notify(msg, level, debuginfo)
  debuginfo = debuginfo or getdebuginfo()
  local info = string.format(
    "%s %s at %s",
    #debuginfo.namewhat > 0 and debuginfo.namewhat or "chunk",
    debuginfo.name or "main",
    debuginfo.short_src or "main loop"
  )
  log.stack[#log.stack + 1] = { level, info, msg }
  msg = string.format("in %s:\n\t%s", info, msg)
  if vim.o.debug == "" then
    return
  end
  if vim.o.debug == "throw" and level >= vim.log.levels.ERROR then
    error(msg, level)
    return
  end
  vim.notify_once(msg, level)
  return level
end

---@param msg string
function log.trace(msg)
  return log.notify(msg, vim.log.levels.TRACE, getdebuginfo())
end

---@param msg string
function log.debug(msg)
  return log.notify(msg, vim.log.levels.DEBUG, getdebuginfo())
end

---@param msg string
function log.info(msg)
  return log.notify(msg, vim.log.levels.INFO, getdebuginfo())
end

---@param msg string
function log.warn(msg)
  return log.notify(msg, vim.log.levels.WARN, getdebuginfo())
end

---@param msg string
function log.error(msg)
  return log.notify(msg, vim.log.levels.ERROR, getdebuginfo())
end

return log
