-- FLUX-CE Library
if not table.safe_merge then
    function table.safe_merge(to, from)
        local old_idx_to, old_idx = to.__index, from.__index
        local references = {}
        to.__index = nil
        from.__index = nil

        for k, v in pairs(from) do
            if v == from or k == 'class' then
                references[k] = v
                from[k] = nil
            end
        end

        table.Merge(to, from)

        for k, v in pairs(references) do
            from[k] = v
        end

        to.__index = old_idx_to
        from.__index = old_idx

        return to
    end
end

if not string.parse_table then
    function string.parse_table(str, ref)
        local tables = str:Split('::')
        ref = istable(ref) and ref or _G

        for k, v in ipairs(tables) do
            ref = ref[v]
            if not istable(ref) then return false, v end
        end

        return ref
    end
end

if not string.parse_parent then
    function string.parse_parent(str, ref)
        local tables = str:Split('::')
        local last_ref = str
        ref = istable(ref) and ref or _G

        for k, v in ipairs(tables) do
            local new_ref = ref[v]
            if not istable(new_ref) then return ref, v end
            last_ref = v
            ref = new_ref
        end

        if istable(ref) then
            return ref, last_ref or str
        else
            return false
        end
    end
end

local last_class = nil

--
-- Function: class(string name, table parent = _G, class parent_class = nil)
-- Description: Creates a new class. Supports constructors and inheritance.
-- Argument: string name - The name of the library. Must comply with Lua variable name requirements.
-- Argument: table parent (default: _G) - The parent table to put the class into.
-- Argument: class parent_class (default: nil) - The base class this new class should extend.
--
-- Alias: class (string name, class parent_class = nil, table parent = _G)
--
-- Returns: table - The created class.
--
if not isfunction(class) then
    function class(name, parent_class)
        if isstring(parent_class) then
            parent_class = parent_class:parse_table()
        end

        local parent = nil
        parent, name = name:parse_parent()
        parent[name] = {}
        local obj = parent[name]
        obj.ClassName = name
        obj.BaseClass = parent_class or false
        obj.class_name = obj.ClassName
        obj.parent = obj.BaseClass
        obj.static_class = true
        obj.class = obj
        obj.included_modules = {}

        -- If this class is based off some other class - copy it's parent's data.
        if istable(parent_class) then
            local copy = table.Copy(parent_class)
            table.safe_merge(copy, obj)

            if isfunction(parent_class.class_extended) then
                local success, exception = pcall(parent_class.class_extended, parent_class, copy)

                if not success then
                    ErrorNoHalt(tostring(exception))
                end
            end

            obj = copy
        end

        last_class = {
            name = name,
            parent = parent
        }

        obj.new = function(...)
            local new_obj = {}
            local real_class = parent[name]
            local old_super = super
            -- Set new object's meta table and copy the data from original class to new object.
            setmetatable(new_obj, real_class)
            table.safe_merge(new_obj, real_class)
            parent_class = real_class.parent

            if parent_class and isfunction(parent_class.init) then
                super = function(...) return parent_class.init(new_obj, ...) end

                real_class.init = isfunction(real_class.init) and real_class.init or function(object)
                    super()
                end
            end

            -- If there is a constructor - call it.
            if real_class.init then
                local success, value = pcall(real_class.init, new_obj, ...)

                if not success then
                    ErrorNoHalt('[' .. name .. '] Class constructor has failed to run!\n')
                    ErrorNoHalt(value)
                end
            end

            new_obj.class = real_class
            new_obj.static_class = false
            new_obj.IsValid = function() return true end
            super = old_super

            -- Return our newly generated object.
            return new_obj
        end

        obj.include = function(self, what)
            local module_table = isstring(what) and what:parse_table() or what
            if not istable(module_table) then return end

            for k, v in pairs(module_table) do
                if not self[k] then
                    self[k] = v
                end
            end

            table.insert(self.included_modules, module_table)
        end

        return parent[name]
    end

    if not isfunction(delegate) then
        function delegate(obj, t)
            if not istable(obj) or not istable(t) or not t.to then return end
            local var_class = isstring(t.to) and t.to:parse_table() or t.to

            if istable(var_class) and var_class.class_name then
                for k, v in ipairs(t) do
                    obj[v] = var_class[v]
                end
            end

            return true
        end
    end
end

--
-- Function: extends (class parent_class)
-- Description: Sets the base class of the class that is currently being created.
-- Argument: class parent_class - The base class to extend.
--
-- Alias: implements
-- Alias: inherits
--
-- Returns: bool - Whether or not did the extension succeed.
--
if not isfunction(extends) then
    function extends(parent_class)
        if isstring(parent_class) then
            parent_class = parent_class:parse_table()
        end

        if istable(last_class) and istable(parent_class) then
            local obj = last_class.parent[last_class.name]
            local copy = table.Copy(parent_class)
            table.safe_merge(copy, obj)

            if isfunction(parent_class.class_extended) then
                local success, exception = pcall(parent_class.class_extended, parent_class, copy)

                if not success then
                    ErrorNoHalt(tostring(exception))
                end
            end

            obj = copy
            obj.parent = parent_class
            obj.BaseClass = obj.parent_class
            hook.Run('OnClassExtended', obj, parent_class)
            last_class.parent[last_class.name] = obj
            last_class = nil

            return true
        end

        return false
    end
end

--- Create a module with a specified name.
-- The resulting object will have the `include` method by default.
-- ```
-- mod 'Talkable'
--
-- -- You can include other modules too.
-- Talkable:include 'Living'
--
-- function Talkable:talk()
--   -- ...
-- end
-- ```
-- @return [Object(created module)]
if not isfunction(mod) then
    function mod(name)
        local parent = nil
        parent, name = name:parse_parent()
        parent[name] = parent[name] or {}
        local obj = {}
        obj.included_modules = {}

        obj.include = function(self, what)
            local module_table = isstring(what) and what:parse_table() or what
            if not istable(module_table) then return end

            for k, v in pairs(module_table) do
                if not self[k] then
                    self[k] = v
                end
            end

            self.included_modules[#self.included_modules + 1] = module_table
        end

        parent[name] = obj

        return obj
    end
end

if not isfunction(enumerate) then
    do
        local enumerators = {}

        --- Creates enumerator variables based on a provided list.
        -- Starts at 0.
        -- ```
        -- --         0           1             2
        -- enumerate 'GENDER_MALE GENDER_FEMALE GENDER_OTHER'
        -- ```
        -- @return [Number highest enumerator]
        function enumerate(enums, existing_enumerator)
            if not isstring(enums) or enums:len() == 0 then return end
            local words = enums:upper():gsub('\n', ' '):split' '
            local first_valid_word = nil
            local enumerator = 0

            if existing_enumerator then
                enumerator = enumerators[existing_enumerator] or 0
            end

            for _, word in ipairs(words) do
                if word ~= '' and word ~= ' ' then
                    if not first_valid_word then
                        first_valid_word = word
                    end

                    _G[word] = enumerator
                    enumerator = enumerator + 1
                end
            end

            if enumerator > 0 then
                local idx = first_valid_word:match('^([%w0-9]+)')

                if idx then
                    enumerators[idx] = enumerator - 1
                end
            end

            return enumerator - 1
        end
    end
end
--
-- class 'SomeClass' extends SomeOtherClass
-- class 'SomeClass' extends 'SomeOtherClass'
--
-- Example
--[[ 
class "Test"

function Test:init()
	self.name = "test"
end

local n = Test.new()
print(n.name) 
]]