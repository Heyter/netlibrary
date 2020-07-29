netlibs = netlibs or {util = {}}

local start_time = os.clock();
netlibs.prefix = "[Netlibrary]"

if (netlibs.initialized) then
	MsgC(Color(0, 255, 100, 255), netlibs.prefix .. " Lua auto-reload in progress...\n")
else
	MsgC(Color(0, 255, 100, 255), netlibs.prefix .. " Initializing...\n")
end

-- A function to include a file based on its prefix.
function netlibs.util.include(fileName, realm)
	if (!fileName) then
		error(netlibs.prefix .. " No file name specified for including.")
	end

	if ((realm == "server" or fileName:find("sv_")) and SERVER) then
		return include(fileName)
	elseif (realm == "shared" or fileName:find("shared.lua") or fileName:find("sh_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		end

		return include(fileName)
	elseif (realm == "client" or fileName:find("cl_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			return include(fileName)
		end
	end
end

if !(string.utf8len and pon and netstream) then
	netlibs.util.include("thirdparty/sh_pon.lua")
	netlibs.util.include("thirdparty/sh_netstream.lua")
	netlibs.util.include("thirdparty/sh_utf8.lua")
end

netlibs.util.include("thirdparty/sh_tween.lua")
netlibs.util.include("thirdparty/sh_class.lua")

netlibs.util.include("framework/sh_core.lua")

if (netlibs.initialized) then
	MsgC(Color(0, 255, 100, 255), netlibs.prefix .. " Auto-reloaded in " .. math.Round(os.clock() - start_time, 3) .. " second(s)\n")
else
	MsgC(Color(0, 255, 100, 255), netlibs.prefix .. " has finished loading in " .. math.Round(os.clock() - start_time, 3) .. " second(s)\n")
	netlibs.initialized = true
end

start_time = nil