-- # Micro-ops.
local netlibs, nsHook = netlibs, netstream.Hook

local netvars = netlibs.netvars or {}
netlibs.netvars = netvars

local stored = netvars.stored or {}
local globals = netvars.globals or {}
netvars.stored = stored
netvars.globals = globals

-- # A function to get a networked global.
function netvars.getNetVar(key, default)
	local value = globals[key]
	return value != nil and value or default
end

-- # Cannot set them on client.
function netvars.setNetVar() end

local entityMeta = FindMetaTable("Entity")

-- # A function to get entity's networked variable.
function entityMeta:getNetVar(key, default)
	local index = self:EntIndex()

	if (stored[index] and stored[index][key] != nil) then
		return stored[index][key]
	end

	return default
end

nsHook("netlibs.netvar.set", function(index, key, value)
	stored[index] = stored[index] or {}
	stored[index][key] = value
end)

nsHook("netlibs.netvar.clear", function(index)
	stored[index] = nil
end)

nsHook("netlibs.netvar.global_set", function(key, value)
	globals[key] = value
end)