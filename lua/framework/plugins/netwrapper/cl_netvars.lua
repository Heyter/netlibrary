local FindMetaTable, LocalPlayer = FindMetaTable, LocalPlayer

local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")
netVars = netVars or {util = {}, gui = {}, meta = {}}
netVars.net = netVars.net or {}

netstream.Hook("ycVar", function(index, key, value)
	netVars.net[index] = netVars.net[index] or {}
	netVars.net[index][key] = value
end)

netstream.Hook("ycDelVar", function(index)
	netVars.net[index] = nil
end)

netstream.Hook("ycLclVar", function(key, value)
	local client = LocalPlayer()
	local index = client:EntIndex()
	netVars.net[index] = netVars.net[index] or {}
	netVars.net[index][key] = value
end)

function entityMeta:getNetVar(key, default)
	local index = self:EntIndex()

	if (netVars.net[index] and netVars.net[index][key] != nil) then
		return netVars.net[index][key]
	end

	return default
end
playerMeta.getLocalVar = entityMeta.getNetVar