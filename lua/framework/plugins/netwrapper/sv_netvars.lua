-- # Micro-ops.
local netlibs, pairs, nsStart = netlibs, pairs, netstream.Start

local netvars = netlibs.netvars or {}
netlibs.netvars = netvars

local stored = netvars.stored or {}
local globals = netvars.globals or {}
netvars.stored = stored
netvars.globals = globals

-- # Check if there is an attempt to send a function. Can't send those.
local function checkBadType(name, object)
	if (isfunction(object)) then
		ErrorNoHalt("Net var '" .. name .. "' contains a bad object type!")
		return true
	elseif (istable(object)) then
		for k, v in pairs(object) do
			-- # Check both the key and the value for tables, and has recursion.
			if (checkBadType(name, k) or checkBadType(name, v)) then
				return true
			end
		end
	end
end

-- # A function to get a networked global.
function netvars.getNetVar(key, default)
	local value = globals[key]
	return value != nil and value or default
end

-- # A function to set a networked global.
function netvars.setNetVar(key, value, recv)
	if (checkBadType(key, value)) then return end
	if (netvars.getNetVar(key) == value) then return end

	globals[key] = value
	nsStart(recv, "netlibs.netvar.global_set", key, value)
end

local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

-- # A function to send entity's networked variables to a player (or players).
function entityMeta:sendNetVar(key, recv)
	nsStart(recv, "netlibs.netvar.set", self:EntIndex(), key, stored[self] and stored[self][key])
end

-- # A function to flush all entity's networked variables.
function entityMeta:clearNetVars(recv)
	stored[self] = nil
	nsStart(recv, "netlibs.netvar.clear", self:EntIndex())
end

-- # A function to set entity's networked variable.
function entityMeta:setNetVar(key, value, bNoNetworking, recv)
	if (checkBadType(key, value)) then return end

	stored[self] = stored[self] or {}

	if (stored[self][key] != value) then
		stored[self][key] = value
	end

	if (!bNoNetworking) then
		self:sendNetVar(key, recv)
	end
end

-- # A function to get entity's networked variable.
function entityMeta:getNetVar(key, default)
	if (stored[self] and stored[self][key] != nil) then
		return stored[self][key]
	end

	return default
end

-- # A function to send all current networked globals and entities' variables to a player.
function playerMeta:syncNetVars()
	for k, v in pairs(globals) do
		nsStart(self, "netlibs.netvar.global_set", k, v)
	end

	for entity, data in pairs(stored) do
		if IsValid(entity) then
			for k, v in pairs(data) do
				nsStart(self, "netlibs.netvar.set", entity:EntIndex(), k, v)
			end
		end
	end
end

local function clear_net_vars_fn(entity)
	entity:clearNetVars()
end

hook.Add("PlayerDisconnected", "PlayerDisconnected.netvar", clear_net_vars_fn)
hook.Add("EntityRemoved", "EntityRemoved.netvars", clear_net_vars_fn)

hook.Add("PlayerInitialSpawn", "PlayerInitialSpawn.netvars", function(client)
	client:syncNetVars()
end)