local pairs, type, ErrorNoHalt, IsValid, hook_Add = pairs, type, ErrorNoHalt, IsValid, hook.Add
local FindMetaTable = FindMetaTable

local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")
netVars = netVars or {util = {}, meta = {}}
netVars.net = netVars.net or {}

local function checkBadType(name, object)
	local objectType = type(object)
	
	if (objectType == "function") then
		ErrorNoHalt("Net var '"..name.."' contains a bad object type!")
		return true
	elseif (objectType == "table") then
		for k, v in pairs(object) do
			if (checkBadType(name, k) or checkBadType(name, v)) then
				return true
			end
		end
	end
end

function entityMeta:sendNetVar(key, receiver)
	netstream.Start(receiver, "ycVar", self:EntIndex(), key, netVars.net[self] and netVars.net[self][key])
end

function entityMeta:clearNetVars(receiver)
	netVars.net[self] = nil
	netstream.Start(receiver, "ycDelVar", self:EntIndex())
end

function entityMeta:setNetVar(key, value, receiver)
	if (checkBadType(key, value)) then return end
		
	netVars.net[self] = netVars.net[self] or {}

	if (netVars.net[self][key] != value) then
		netVars.net[self][key] = value
	end

	self:sendNetVar(key, receiver)
end

function entityMeta:getNetVar(key, default)
	if (netVars.net[self] and netVars.net[self][key] != nil) then
		return netVars.net[self][key]
	end

	return default
end

function playerMeta:setLocalVar(key, value)
	if (checkBadType(key, value)) then return end
	
	netVars.net[self] = netVars.net[self] or {}
	netVars.net[self][key] = value

	netstream.Start(self, "ycLclVar", key, value)
end
playerMeta.getLocalVar = entityMeta.getNetVar

function playerMeta:syncVars()
	for entity, data in pairs(netVars.net) do
		if IsValid(entity) then
			for k, v in pairs(data) do
				netstream.Start(self, "ycVar", entity:EntIndex(), k, v)
			end
		end
	end
end

hook_Add("EntityRemoved", "ycCleanVars", function(entity)
	entity:clearNetVars()
end)

hook_Add("PlayerInitialSpawn", "ycSyncVars", function(ply)
	ply:syncVars()
end)