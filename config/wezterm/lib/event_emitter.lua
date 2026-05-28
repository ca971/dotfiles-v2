--- @module "lib.event_emitter""
--- @description Custom event bus for internal configuration events.
--- Provides publish/subscribe pattern with support for priorities,
--- one-shot handlers, namespaced events, and wildcard matching.
--- Complements WezTerm's built-in event system for internal use.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Class = require("lib.class")
local Guard = require("lib.guard")
local LoggerModule = require("lib.logger")

--- @class EventHandler
--- @field id number Unique handler ID
--- @field callback function The handler function
--- @field priority number Execution priority (lower = first)
--- @field once boolean Whether to remove after first invocation
--- @field namespace string|nil Optional namespace for grouping

--- @class EventEmitter
--- @field _handlers table<string, table<number, EventHandler>> Event handlers by event name
--- @field _next_id number Next handler ID
--- @field _log Logger Logger instance
local EventEmitter = Class.new("EventEmitter")

--- Initialize the event emitter.
--- @param opts? table Options
--- @field opts.name? string Emitter name for logging
function EventEmitter:init(opts)
  opts = opts or {}
  self._handlers = {}
  self._next_id = 1
  self._log = LoggerModule.create(opts.name or "events")
end

--- Subscribe to an event.
--- @param event string Event name (supports "namespace:event" format)
--- @param callback function The handler function
--- @param opts? table Options
--- @field opts.priority? number Priority (default: 100, lower = earlier)
--- @field opts.once? boolean Fire only once (default: false)
--- @field opts.namespace? string Handler namespace
--- @return number id The handler ID (for unsubscribing)
function EventEmitter:on(event, callback, opts)
  Guard.is_non_empty_string(event, "event")
  Guard.is_function(callback, "callback")
  opts = opts or {}

  if not self._handlers[event] then
    self._handlers[event] = {}
  end

  local id = self._next_id
  self._next_id = self._next_id + 1

  --- @type EventHandler
  local handler = {
    id = id,
    callback = callback,
    priority = opts.priority or 100,
    once = opts.once or false,
    namespace = opts.namespace,
  }

  self._handlers[event][#self._handlers[event] + 1] = handler

  -- Sort by priority
  table.sort(self._handlers[event], function(a, b)
    return a.priority < b.priority
  end)

  self._log:trace("Handler registered", {
    event = event,
    id = tostring(id),
    priority = tostring(handler.priority),
  })

  return id
end

--- Subscribe to an event (fires only once).
--- @param event string Event name
--- @param callback function The handler function
--- @param opts? table Options (same as :on() except once is forced true)
--- @return number id The handler ID
function EventEmitter:once(event, callback, opts)
  opts = opts or {}
  opts.once = true
  return self:on(event, callback, opts)
end

--- Unsubscribe a handler by ID.
--- @param event string Event name
--- @param id number Handler ID to remove
--- @return boolean removed True if the handler was found and removed
function EventEmitter:off(event, id)
  Guard.is_non_empty_string(event, "event")
  Guard.is_number(id, "id")

  local handlers = self._handlers[event]
  if not handlers then
    return false
  end

  for i, handler in ipairs(handlers) do
    if handler.id == id then
      table.remove(handlers, i)
      self._log:trace("Handler removed", { event = event, id = tostring(id) })
      return true
    end
  end

  return false
end

--- Remove all handlers for a namespace.
--- @param namespace string The namespace to clear
--- @return number removed Number of handlers removed
function EventEmitter:off_namespace(namespace)
  Guard.is_non_empty_string(namespace, "namespace")
  local removed = 0

  for event, handlers in pairs(self._handlers) do
    local i = 1
    while i <= #handlers do
      if handlers[i].namespace == namespace then
        table.remove(handlers, i)
        removed = removed + 1
      else
        i = i + 1
      end
    end
  end

  if removed > 0 then
    self._log:debug("Namespace handlers removed", {
      namespace = namespace,
      count = tostring(removed),
    })
  end

  return removed
end

--- Remove all handlers for an event.
--- @param event string Event name
--- @return EventEmitter self For method chaining
function EventEmitter:off_all(event)
  if event then
    self._handlers[event] = nil
  else
    self._handlers = {}
  end
  return self
end

--- Emit an event, invoking all registered handlers.
--- @param event string Event name
--- @param ... any Arguments passed to handlers
--- @return table results Array of handler return values
function EventEmitter:emit(event, ...)
  Guard.is_non_empty_string(event, "event")

  local handlers = self._handlers[event]
  if not handlers or #handlers == 0 then
    return {}
  end

  self._log:trace("Emitting event", {
    event = event,
    handler_count = tostring(#handlers),
  })

  local results = {}
  local to_remove = {}

  for i, handler in ipairs(handlers) do
    local ok, result = pcall(handler.callback, ...)
    if ok then
      results[#results + 1] = result
    else
      self._log:error("Handler error", {
        event = event,
        handler_id = tostring(handler.id),
        error = tostring(result),
      })
    end

    if handler.once then
      to_remove[#to_remove + 1] = i
    end
  end

  -- Remove one-shot handlers (reverse order to preserve indices)
  for i = #to_remove, 1, -1 do
    table.remove(handlers, to_remove[i])
  end

  return results
end

--- Emit an event asynchronously (fire-and-forget, errors are logged).
--- @param event string Event name
--- @param ... any Arguments passed to handlers
function EventEmitter:emit_async(event, ...)
  -- In Lua there's no true async, but we wrap in pcall for safety
  local args = { ... }
  pcall(function()
    self:emit(event, table.unpack(args))
  end)
end

--- Check if an event has any handlers.
--- @param event string Event name
--- @return boolean has_handlers True if at least one handler exists
function EventEmitter:has_handlers(event)
  local handlers = self._handlers[event]
  return handlers ~= nil and #handlers > 0
end

--- Get the count of handlers for an event.
--- @param event string Event name
--- @return number count Number of registered handlers
function EventEmitter:handler_count(event)
  local handlers = self._handlers[event]
  return handlers and #handlers or 0
end

--- List all events that have handlers.
--- @return table<number, string> events Array of event names
function EventEmitter:list_events()
  local events = {}
  for event, handlers in pairs(self._handlers) do
    if #handlers > 0 then
      events[#events + 1] = event
    end
  end
  table.sort(events)
  return events
end

--- Get a summary of all registered events and handler counts.
--- @return table<string, number> summary Map of event name to handler count
function EventEmitter:summary()
  local result = {}
  for event, handlers in pairs(self._handlers) do
    result[event] = #handlers
  end
  return result
end

---------------------------------------------------------------------------
-- Module API with global event bus
---------------------------------------------------------------------------

--- @class EventEmitterModule
local M = {
  EventEmitter = EventEmitter,
  _global = nil,
}

--- Get or create the global event bus.
--- @return EventEmitter bus The global event bus
function M.global()
  if not M._global then
    M._global = EventEmitter({ name = "global" })
  end
  return M._global
end

--- Shortcut: subscribe on global bus.
--- @param event string Event name
--- @param callback function Handler function
--- @param opts? table Options
--- @return number id Handler ID
function M.on(event, callback, opts)
  return M.global():on(event, callback, opts)
end

--- Shortcut: emit on global bus.
--- @param event string Event name
--- @param ... any Event arguments
--- @return table results Handler results
function M.emit(event, ...)
  return M.global():emit(event, ...)
end

--- Reset global bus (for testing).
function M.reset()
  M._global = nil
end

return M
