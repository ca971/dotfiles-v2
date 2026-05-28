--- @module "lib.cache""
--- @description Memoization and caching layer with TTL support.
--- Provides function result caching, timed expiration, cache invalidation,
--- and statistics tracking. Designed for caching expensive operations
--- like process detection and environment checks.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Class = require("lib.class")

--- @class CacheEntry
--- @field value any The cached value
--- @field expires_at number|nil Expiration timestamp (nil = never expires)
--- @field hits number Number of cache hits
--- @field created_at number Creation timestamp

--- @class Cache
--- @field _name string Cache instance name
--- @field _store table<string, CacheEntry> Internal key-value store
--- @field _default_ttl number|nil Default TTL in seconds (nil = forever)
--- @field _max_size number Maximum number of entries (0 = unlimited)
--- @field _stats table Cache statistics
local Cache = Class.new("Cache")

--- Initialize a new cache instance.
--- @param opts? table Configuration options
--- @field opts.name? string Cache name (default: "default")
--- @field opts.default_ttl? number Default TTL in seconds (nil = no expiry)
--- @field opts.max_size? number Maximum entries (default: 1000, 0 = unlimited)
function Cache:init(opts)
  opts = opts or {}
  self._name = opts.name or "default"
  self._store = {}
  self._default_ttl = opts.default_ttl
  self._max_size = opts.max_size or 1000
  self._stats = {
    hits = 0,
    misses = 0,
    sets = 0,
    evictions = 0,
  }
end

--- Get the current time in seconds.
--- @return number time Current time
--- @private
function Cache:_now()
  return os.time()
end

--- Check if a cache entry has expired.
--- @param entry CacheEntry The entry to check
--- @return boolean expired True if the entry has expired
--- @private
function Cache:_is_expired(entry)
  if not entry.expires_at then
    return false
  end
  return self:_now() >= entry.expires_at
end

--- Evict expired entries from the cache.
--- @return number evicted Number of entries evicted
function Cache:evict_expired()
  local evicted = 0
  local keys_to_remove = {}

  for key, entry in pairs(self._store) do
    if self:_is_expired(entry) then
      keys_to_remove[#keys_to_remove + 1] = key
    end
  end

  for _, key in ipairs(keys_to_remove) do
    self._store[key] = nil
    evicted = evicted + 1
  end

  self._stats.evictions = self._stats.evictions + evicted
  return evicted
end

--- Evict the oldest entry (LRU-style based on creation time).
--- @private
function Cache:_evict_oldest()
  local oldest_key = nil
  local oldest_time = math.huge

  for key, entry in pairs(self._store) do
    if entry.created_at < oldest_time then
      oldest_time = entry.created_at
      oldest_key = key
    end
  end

  if oldest_key then
    self._store[oldest_key] = nil
    self._stats.evictions = self._stats.evictions + 1
  end
end

--- Get the current size of the cache.
--- @return number size Number of entries
function Cache:size()
  local count = 0
  for _ in pairs(self._store) do
    count = count + 1
  end
  return count
end

--- Store a value in the cache.
--- @param key string The cache key
--- @param value any The value to cache
--- @param ttl? number TTL in seconds (overrides default)
--- @return Cache self For method chaining
function Cache:set(key, value, ttl)
  -- Enforce max size
  if self._max_size > 0 and self:size() >= self._max_size then
    self:evict_expired()
    -- Still full? Evict oldest
    if self:size() >= self._max_size then
      self:_evict_oldest()
    end
  end

  local effective_ttl = ttl or self._default_ttl
  local now = self:_now()

  --- @type CacheEntry
  self._store[key] = {
    value = value,
    expires_at = effective_ttl and (now + effective_ttl) or nil,
    hits = 0,
    created_at = now,
  }

  self._stats.sets = self._stats.sets + 1
  return self
end

--- Retrieve a value from the cache.
--- @param key string The cache key
--- @param default? any Default value if not found or expired
--- @return any value The cached value or default
function Cache:get(key, default)
  local entry = self._store[key]

  if not entry then
    self._stats.misses = self._stats.misses + 1
    return default
  end

  if self:_is_expired(entry) then
    self._store[key] = nil
    self._stats.misses = self._stats.misses + 1
    self._stats.evictions = self._stats.evictions + 1
    return default
  end

  entry.hits = entry.hits + 1
  self._stats.hits = self._stats.hits + 1
  return entry.value
end

--- Check if a key exists and is not expired.
--- @param key string The cache key
--- @return boolean exists True if key exists and is valid
function Cache:has(key)
  local entry = self._store[key]
  if not entry then
    return false
  end
  if self:_is_expired(entry) then
    self._store[key] = nil
    return false
  end
  return true
end

--- Remove a specific key from the cache.
--- @param key string The cache key to remove
--- @return boolean removed True if the key existed and was removed
function Cache:remove(key)
  if self._store[key] then
    self._store[key] = nil
    return true
  end
  return false
end

--- Clear all entries from the cache.
--- @return Cache self For method chaining
function Cache:clear()
  self._store = {}
  return self
end

--- Memoize a function: cache its results by arguments.
--- @param fn function The function to memoize
--- @param key_fn? fun(...): string Custom key generator (default: tostring of args)
--- @param ttl? number TTL for cached results
--- @return function memoized The memoized function
function Cache:memoize(fn, key_fn, ttl)
  assert(type(fn) == "function", "memoize() expects a function")

  local cache = self

  key_fn = key_fn
    or function(...)
      local parts = {}
      local args = { ... }
      for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(args[i])
      end
      return table.concat(parts, ":")
    end

  return function(...)
    local key = key_fn(...)
    if cache:has(key) then
      return cache:get(key)
    end

    local result = fn(...)
    cache:set(key, result, ttl)
    return result
  end
end

--- Get or compute: return cached value or compute and cache it.
--- @param key string The cache key
--- @param compute_fn function Function to compute value if not cached
--- @param ttl? number TTL for the computed value
--- @return any value The cached or freshly computed value
function Cache:get_or_set(key, compute_fn, ttl)
  if self:has(key) then
    return self:get(key)
  end

  local value = compute_fn()
  self:set(key, value, ttl)
  return value
end

--- Get cache statistics.
--- @return table stats Cache statistics
function Cache:get_stats()
  local total = self._stats.hits + self._stats.misses
  return {
    name = self._name,
    size = self:size(),
    hits = self._stats.hits,
    misses = self._stats.misses,
    sets = self._stats.sets,
    evictions = self._stats.evictions,
    hit_rate = total > 0 and (self._stats.hits / total * 100) or 0,
  }
end

--- Reset statistics counters.
--- @return Cache self For method chaining
function Cache:reset_stats()
  self._stats = {
    hits = 0,
    misses = 0,
    sets = 0,
    evictions = 0,
  }
  return self
end

---------------------------------------------------------------------------
-- Module API with global cache instances
---------------------------------------------------------------------------

--- @class CacheModule
local M = {
  Cache = Cache,
  _instances = {},
}

--- Get or create a named cache instance (singleton per name).
--- @param name? string Cache name (default: "default")
--- @param opts? table Cache options
--- @return Cache cache The cache instance
function M.get(name, opts)
  name = name or "default"
  if not M._instances[name] then
    opts = opts or {}
    opts.name = name
    M._instances[name] = Cache(opts)
  end
  return M._instances[name]
end

--- Reset all cache instances (for testing).
function M.reset()
  M._instances = {}
end

return M
