netlibs = netlibs or {};
netlibs.Core = netlibs.Core or {};
netlibs.Libs = netlibs.Libs or {};

netlibs.startTime = os.clock();
netlibs.prefix = "[Netlibrary]"

if (netlibs.initialized) then
	MsgC(Color(0, 255, 100, 255), ""..netlibs.prefix.." Lua auto-reload in progress...\n")
else
	MsgC(Color(0, 255, 100, 255), ""..netlibs.prefix.." Initializing...\n")
end

-- A function to include a file based on its prefix.
function util.Include(name)
	-- We sort files based on their name or prefix.
	local server = (string.find(name, "sv_") or string.find(name, "init.lua"))
	local client = (string.find(name, "cl_") or string.find(name, "cl_init.lua"))
	local shared = (string.find(name, "sh_") or string.find(name, "shared.lua"))
	
	if (server and !SERVER) then return end
	
	if (shared and SERVER) then
		AddCSLuaFile(name)
	elseif (client and SERVER) then
		AddCSLuaFile(name)
		return
	end
	
	include(name)
end

if (!string.utf8len or !pon or !netstream) then
	util.Include("thirdparty/sh_pon.lua")
	util.Include("thirdparty/sh_netstream.lua")
	util.Include("thirdparty/sh_utf8.lua")
end

util.Include("framework/sh_core.lua");

if (netlibs.initialized) then
	MsgC(Color(0, 255, 100, 255), ""..netlibs.prefix.." Auto-reloaded in "..math.Round(os.clock() - netlibs.startTime, 3).. " second(s)\n")
else
	MsgC(Color(0, 255, 100, 255), ""..netlibs.prefix.." has finished loading in "..math.Round(os.clock() - netlibs.startTime, 3).. " second(s)\n")
	netlibs.initialized = true
end
netlibs.startTime = nil