--- @module "lib.class""
--- @description Enterprise-grade OOP class system for Lua.
--- Supports single inheritance, mixins, interfaces, abstract methods,
--- method chaining, instanceof checks, and class sealing.
--- Inspired by middleclass and 30log patterns adapted for WezTerm.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

--- @class ClassSystem
--- @field _VERSION string Semantic version of the class system
--- @field _DESCRIPTION string Human-readable description
--- @field _registry table<string, Class> Global class registry for introspection
local ClassSystem = {
  _VERSION = "2.0.0",
  _DESCRIPTION = "Enterprise OOP Class System for Lua",
  _registry = {},
}

---------------------------------------------------------------------------
-- Internal helpers (private)
---------------------------------------------------------------------------

--- Deep-copy a table (shallow references for non-table values).
--- @param orig table The source table
--- @return table copy The cloned table
local function shallow_copy(orig)
  if type(orig) ~= "table" then
    return orig
  end
  local copy = {}
  for k, v in pairs(orig) do
    copy[k] = v
  end
  return copy
end

--- Merge source table into destination (non-destructive).
--- @param dst table Destination table
--- @param src table Source table
--- @return table dst The merged destination
local function merge_into(dst, src)
  for k, v in pairs(src) do
    if dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

---------------------------------------------------------------------------
-- Class metatable factory
---------------------------------------------------------------------------

--- @class Class
--- @field __name string The class name
--- @field __super Class|nil The parent class
--- @field __mixins table<string, table> Applied mixins
--- @field __interfaces table<string, table> Implemented interfaces
--- @field __abstract table<string, boolean> Abstract method declarations
--- @field __sealed boolean Whether the class is sealed (no subclassing)
--- @field __static table<string, any> Static members

--- Create a new class.
--- @param name string The class name (must be unique)
--- @param super? Class Optional parent class for inheritance
--- @return Class class The new class object
function ClassSystem.new(name, super)
  assert(type(name) == "string" and #name > 0, "Class name must be a non-empty string")
  assert(not ClassSystem._registry[name], string.format("Class '%s' is already registered", name))

  if super then
    assert(type(super) == "table" and super.__name, "Super must be a valid Class")
    assert(not super.__sealed, string.format("Cannot inherit from sealed class '%s'", super.__name))
  end

  --- @type Class
  local cls = {
    __name = name,
    __super = super,
    __mixins = {},
    __interfaces = {},
    __abstract = {},
    __sealed = false,
    __static = {},
  }

  -- Instance metatable: method lookup chain
  cls.__index = function(instance, key)
    -- 1. Check class itself
    local val = rawget(cls, key)
    if val ~= nil then
      return val
    end
    -- 2. Check parent chain
    local parent = cls.__super
    while parent do
      val = rawget(parent, key)
      if val ~= nil then
        return val
      end
      parent = parent.__super
    end
    return nil
  end

  -- Class-level metatable for static access and calling as constructor
  setmetatable(cls, {
    __index = super,
    __call = function(self, ...)
      return self:create(...)
    end,
    __tostring = function(self)
      local parent_name = self.__super and self.__super.__name or "none"
      return string.format("Class<%s : %s>", self.__name, parent_name)
    end,
  })

  --- Create a new instance of this class.
  --- @param ... any Constructor arguments passed to init()
  --- @return table instance The new instance
  function cls:create(...)
    -- Guard against abstract instantiation
    for method_name, _ in pairs(self.__abstract) do
      assert(
        type(rawget(self, method_name)) == "function",
        string.format(
          "Cannot instantiate class '%s': abstract method '%s' not implemented",
          self.__name,
          method_name
        )
      )
    end

    local instance = setmetatable({}, self)
    instance.__class = self

    if instance.init then
      instance:init(...)
    end

    return instance
  end

  --- Declare abstract methods that subclasses must implement.
  --- @param ... string Method names to declare as abstract
  --- @return Class self For method chaining
  function cls:abstract(...)
    local methods = { ... }
    for _, method_name in ipairs(methods) do
      assert(type(method_name) == "string", "Abstract method name must be a string")
      self.__abstract[method_name] = true
    end
    return self
  end

  --- Apply a mixin (table of methods) to the class.
  --- @param mixin table A table containing methods to mix in
  --- @param mixin_name? string Optional name for the mixin
  --- @return Class self For method chaining
  function cls:include(mixin, mixin_name)
    assert(type(mixin) == "table", "Mixin must be a table")
    local name_key = mixin_name or mixin.__name or tostring(mixin)

    if self.__mixins[name_key] then
      return self -- Already applied, idempotent
    end

    for k, v in pairs(mixin) do
      if k ~= "__name" and k:sub(1, 2) ~= "__" then
        if rawget(self, k) == nil then
          self[k] = v
        end
      end
    end

    -- Call mixin included hook if present
    if type(mixin.included) == "function" then
      mixin.included(self)
    end

    self.__mixins[name_key] = mixin
    return self
  end

  --- Declare that the class implements an interface.
  --- An interface is a table of method names (strings) that must exist.
  --- @param interface table<number, string> List of required method names
  --- @param interface_name? string Optional interface name
  --- @return Class self For method chaining
  function cls:implements(interface, interface_name)
    assert(type(interface) == "table", "Interface must be a table")
    local iface_name = interface_name or interface.__name or tostring(interface)

    self.__interfaces[iface_name] = interface
    return self
  end

  --- Validate that all declared interfaces are satisfied.
  --- @return boolean valid True if all interfaces are satisfied
  --- @return string|nil error Error message if validation fails
  function cls:validate_interfaces()
    for iface_name, iface in pairs(self.__interfaces) do
      for _, method_name in ipairs(iface) do
        if type(method_name) == "string" then
          local found = false
          local search = self
          while search do
            if type(rawget(search, method_name)) == "function" then
              found = true
              break
            end
            search = search.__super
          end
          if not found then
            return false,
              string.format(
                "Class '%s' does not implement '%s' required by interface '%s'",
                self.__name,
                method_name,
                iface_name
              )
          end
        end
      end
    end
    return true, nil
  end

  --- Seal the class to prevent further subclassing.
  --- @return Class self For method chaining
  function cls:seal()
    self.__sealed = true
    return self
  end

  --- Check if an instance belongs to a class (supports inheritance chain).
  --- @param instance table The instance to check
  --- @param target_class Class The class to check against
  --- @return boolean is_instance True if instance is of target_class
  function cls.is_instance(instance, target_class)
    if type(instance) ~= "table" or not instance.__class then
      return false
    end
    local current = instance.__class
    while current do
      if current == target_class then
        return true
      end
      current = current.__super
    end
    return false
  end

  --- Check if a class is a subclass of another.
  --- @param child Class The potential child class
  --- @param parent Class The potential parent class
  --- @return boolean is_subclass True if child extends parent
  function cls.is_subclass(child, parent)
    if type(child) ~= "table" or not child.__name then
      return false
    end
    local current = child.__super
    while current do
      if current == parent then
        return true
      end
      current = current.__super
    end
    return false
  end

  --- Get the full inheritance chain of the class.
  --- @return table<number, string> chain List of class names from child to root
  function cls:get_chain()
    local chain = { self.__name }
    local current = self.__super
    while current do
      chain[#chain + 1] = current.__name
      current = current.__super
    end
    return chain
  end

  -- Register in global registry
  ClassSystem._registry[name] = cls

  return cls
end

--- Retrieve a class from the registry by name.
--- @param name string The class name
--- @return Class|nil class The class or nil if not found
function ClassSystem.get(name)
  return ClassSystem._registry[name]
end

--- List all registered class names.
--- @return table<number, string> names List of registered class names
function ClassSystem.list()
  local names = {}
  for name, _ in pairs(ClassSystem._registry) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- Reset the class registry (primarily for testing).
--- @return nil
function ClassSystem.reset()
  ClassSystem._registry = {}
end

return ClassSystem
