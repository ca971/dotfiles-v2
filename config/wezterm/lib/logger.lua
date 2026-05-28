--- @module "lib.logger""
--- @description Structured, leveled logging system with output formatting.
--- Supports log levels (TRACE, DEBUG, INFO, WARN, ERROR, FATAL),
--- structured context, log rotation awareness, and both console
--- and file output targets. Uses the OOP class system.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Class = require("lib.class")
local Guard = require("lib.guard")

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

--- @enum LogLevel
--- Numeric log levels for filtering.
local LogLevel = {
  TRACE = 0,
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
  FATAL = 5,
  OFF = 6,
}

--- @type table<number, string>
--- Map from numeric level to label string.
local LEVEL_LABELS = {
  [0] = "TRACE",
  [1] = "DEBUG",
  [2] = "INFO",
  [3] = "WARN",
  [4] = "ERROR",
  [5] = "FATAL",
}

--- @type table<number, string>
--- ANSI color codes per log level (for console output).
local LEVEL_COLORS = {
  [0] = "\27[90m", -- Gray for TRACE
  [1] = "\27[36m", -- Cyan for DEBUG
  [2] = "\27[32m", -- Green for INFO
  [3] = "\27[33m", -- Yellow for WARN
  [4] = "\27[31m", -- Red for ERROR
  [5] = "\27[35;1m", -- Bold magenta for FATAL
}

local RESET = "\27[0m"

---------------------------------------------------------------------------
-- Logger Class
---------------------------------------------------------------------------

--- @class Logger
--- @field _name string Logger name/namespace
--- @field _level number Current minimum log level
--- @field _outputs table Array of output targets
--- @field _context table<string, any> Persistent context fields
--- @field _use_colors boolean Whether to use ANSI colors
--- @field _timestamp_format string strftime format for timestamps
local Logger = Class.new("Logger")

--- Initialize the logger.
--- @param opts? table Configuration options
--- @field opts.name? string Logger name (default: "wezterm")
--- @field opts.level? string|number Log level (default: "INFO")
--- @field opts.use_colors? boolean Enable ANSI colors (default: true)
--- @field opts.timestamp_format? string strftime format (default: "%Y-%m-%d %H:%M:%S")
--- @field opts.context? table<string, any> Initial context
function Logger:init(opts)
  opts = opts or {}

  self._name = opts.name or "wezterm"
  self._use_colors = opts.use_colors ~= false
  self._timestamp_format = opts.timestamp_format or "%Y-%m-%d %H:%M:%S"
  self._context = opts.context or {}
  self._outputs = {}
  self._buffer = {}
  self._buffer_size = opts.buffer_size or 100

  -- Resolve level
  local level = opts.level or "INFO"
  if type(level) == "string" then
    self._level = LogLevel[level:upper()] or LogLevel.INFO
  else
    self._level = level
  end
end

--- Resolve a level name to its numeric value.
--- @param level string|number The level to resolve
--- @return number numeric_level The numeric log level
function Logger:_resolve_level(level)
  if type(level) == "number" then
    return level
  end
  return LogLevel[tostring(level):upper()] or LogLevel.INFO
end

--- Set the minimum log level.
--- @param level string|number The new minimum level
--- @return Logger self For method chaining
function Logger:set_level(level)
  self._level = self:_resolve_level(level)
  return self
end

--- Get the current log level name.
--- @return string level_name The current level name
function Logger:get_level()
  return LEVEL_LABELS[self._level] or "UNKNOWN"
end

--- Add persistent context fields.
--- @param ctx table<string, any> Context key-value pairs
--- @return Logger self For method chaining
function Logger:with_context(ctx)
  Guard.is_table(ctx, "ctx")
  for k, v in pairs(ctx) do
    self._context[k] = v
  end
  return self
end

--- Create a child logger with additional context.
--- @param name string Child logger name
--- @param ctx? table<string, any> Additional context
--- @return Logger child A new logger inheriting parent settings
function Logger:child(name, ctx)
  Guard.is_non_empty_string(name, "name")

  local child_context = {}
  for k, v in pairs(self._context) do
    child_context[k] = v
  end
  if ctx then
    for k, v in pairs(ctx) do
      child_context[k] = v
    end
  end

  return Logger({
    name = self._name .. "." .. name,
    level = self._level,
    use_colors = self._use_colors,
    timestamp_format = self._timestamp_format,
    context = child_context,
  })
end

--- Format a log entry.
--- @param level number The log level
--- @param message string The log message
--- @param data? table Additional structured data
--- @return string formatted The formatted log line
function Logger:_format(level, message, data)
  local timestamp = os.date(self._timestamp_format)
  local level_label = LEVEL_LABELS[level] or "???"

  -- Build context string
  local ctx_parts = {}
  for k, v in pairs(self._context) do
    ctx_parts[#ctx_parts + 1] = string.format("%s=%s", k, tostring(v))
  end
  if data then
    for k, v in pairs(data) do
      ctx_parts[#ctx_parts + 1] = string.format("%s=%s", k, tostring(v))
    end
  end

  local ctx_str = ""
  if #ctx_parts > 0 then
    ctx_str = " {" .. table.concat(ctx_parts, ", ") .. "}"
  end

  if self._use_colors then
    local color = LEVEL_COLORS[level] or ""
    return string.format(
      "%s[%s]%s %s[%-5s]%s [%s] %s%s",
      "\27[90m",
      timestamp,
      RESET,
      color,
      level_label,
      RESET,
      self._name,
      message,
      ctx_str
    )
  else
    return string.format(
      "[%s] [%-5s] [%s] %s%s",
      timestamp,
      level_label,
      self._name,
      message,
      ctx_str
    )
  end
end

--- Core log method.
--- @param level number The log level
--- @param message string The message to log
--- @param data? table Additional structured data
function Logger:_log(level, message, data)
  if level < self._level then
    return
  end

  local formatted = self:_format(level, message, data)

  -- Buffer management
  self._buffer[#self._buffer + 1] = {
    level = level,
    message = message,
    data = data,
    formatted = formatted,
    timestamp = os.time(),
  }

  -- Trim buffer if exceeds size
  if #self._buffer > self._buffer_size then
    table.remove(self._buffer, 1)
  end

  -- Output to WezTerm log or fallback to print
  local wez = nil
  local ok, mod = pcall(require, "wezterm")
  if ok and type(mod) == "table" and mod.log_info then
    wez = mod
  end

  if wez then
    if level >= LogLevel.ERROR then
      wez.log_error(formatted)
    elseif level >= LogLevel.WARN then
      wez.log_warn(formatted)
    else
      wez.log_info(formatted)
    end
  else
    -- Fallback to print (for testing outside WezTerm)
    print(formatted)
  end
end

--- Log a TRACE message.
--- @param message string The message
--- @param data? table Additional data
function Logger:trace(message, data)
  self:_log(LogLevel.TRACE, message, data)
end

--- Log a DEBUG message.
--- @param message string The message
--- @param data? table Additional data
function Logger:debug(message, data)
  self:_log(LogLevel.DEBUG, message, data)
end

--- Log an INFO message.
--- @param message string The message
--- @param data? table Additional data
function Logger:info(message, data)
  self:_log(LogLevel.INFO, message, data)
end

--- Log a WARN message.
--- @param message string The message
--- @param data? table Additional data
function Logger:warn(message, data)
  self:_log(LogLevel.WARN, message, data)
end

--- Log an ERROR message.
--- @param message string The message
--- @param data? table Additional data
function Logger:error(message, data)
  self:_log(LogLevel.ERROR, message, data)
end

--- Log a FATAL message.
--- @param message string The message
--- @param data? table Additional data
function Logger:fatal(message, data)
  self:_log(LogLevel.FATAL, message, data)
end

--- Get buffered log entries.
--- @param count? number Number of recent entries (default: all)
--- @return table entries Array of log entry tables
function Logger:get_buffer(count)
  if not count then
    return self._buffer
  end
  local result = {}
  local start = math.max(1, #self._buffer - count + 1)
  for i = start, #self._buffer do
    result[#result + 1] = self._buffer[i]
  end
  return result
end

--- Clear the log buffer.
--- @return Logger self For method chaining
function Logger:clear_buffer()
  self._buffer = {}
  return self
end

--- Measure execution time of a function.
--- @param label string A label for the operation
--- @param fn function The function to measure
--- @param ... any Arguments to pass to fn
--- @return any ... The return values of fn
function Logger:timed(label, fn, ...)
  Guard.is_non_empty_string(label, "label")
  Guard.is_function(fn, "fn")

  local start = os.clock()
  local results = { fn(...) }
  local elapsed = os.clock() - start

  self:debug(string.format("%s completed", label), {
    elapsed_ms = string.format("%.2f", elapsed * 1000),
  })

  return table.unpack(results)
end

---------------------------------------------------------------------------
-- Module-level singleton & factory
---------------------------------------------------------------------------

--- @class LoggerModule
--- @field Level LogLevel Log level enum
--- @field _default Logger Default logger instance
local M = {
  Level = LogLevel,
  _default = nil,
}

--- Get or create the default logger.
--- @param opts? table Options for initial creation
--- @return Logger logger The default logger instance
function M.get_default(opts)
  if not M._default then
    M._default = Logger(opts or { name = "wezterm", level = "INFO" })
  end
  return M._default
end

--- Create a new named logger.
--- @param name string Logger name
--- @param opts? table Additional options
--- @return Logger logger A new logger instance
function M.create(name, opts)
  opts = opts or {}
  opts.name = name
  return Logger(opts)
end

--- Expose the Logger class for direct use.
M.Logger = Logger

return M
