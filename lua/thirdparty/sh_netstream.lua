--[[
	NetStream - 2.1.0
	Alexander Grist-Hucker
	http://www.revotech.org

	Credits to:
		thelastpenguin for pON.
		https://github.com/thelastpenguin/gLUA-Library/tree/master/pON
--]]

local util, type, pcall, pairs, ErrorNoHalt, net = util, type, pcall, pairs, ErrorNoHalt, net

if (!pon) then
	include("pon.lua")
end

AddCSLuaFile()

netstream = netstream or {}

local stored = netstream.stored or {}
netstream.stored = stored

if (DBugR) then
	DBugR.Profilers.Netstream = table.Copy(DBugR.SP)
	DBugR.Profilers.Netstream.CChan = ""
	DBugR.Profilers.Netstream.Name = "Netstream"
	DBugR.Profilers.Netstream.Type = SERVICE_PROVIDER_TYPE_NET

	DBugR.Profilers.NetstreamPerf = table.Copy(DBugR.SP)
	DBugR.Profilers.NetstreamPerf.Name = "Netstream"
	DBugR.Profilers.NetstreamPerf.Type = SERVICE_PROVIDER_TYPE_CPU
end

--[[
	@codebase Shared
	@details A function to hook a data stream.
	@param String A unique identifier.
	@param Function The datastream callback.
--]]
function netstream.Hook(name, Callback)
	stored[name] = Callback
end

if (DBugR) then
	local oldDS = netstream.Hook

	for name, func in pairs(stored) do
		stored[name] = nil

		oldDS(name, DBugR.Util.Func.AttachProfiler(func, function(time)
			DBugR.Profilers.NetstreamPerf:AddPerformanceData(tostring(name), time, func)
		end))
	end

	netstream.Hook = DBugR.Util.Func.AddDetourM(netstream.Hook, function(name, func, ...)
		func = DBugR.Util.Func.AttachProfiler(func, function(time)
			DBugR.Profilers.NetstreamPerf:AddPerformanceData(tostring(name), time, func)
		end)

		return name, func, ...
	end)
end

if (SERVER) then
	util.AddNetworkString("NetStreamDS")

	-- A function to start a net stream.
	function netstream.Start(client, name, ...)
		local recipients = {}
		local bShouldSend = false

		if (!istable(client)) then
			if (!client) then
				client = player.GetAll()
			else
				client = {client}
			end
		end

		for k, v in pairs(client) do
			if (type(v) == "Player") then
				recipients[#recipients + 1] = v
				
				bShouldSend = true;
			elseif (type(k) == "Player") then
				recipients[#recipients + 1] = k
			
				bShouldSend = true;
			end;
		end

		local encodedData = pon.encode({...})

		if (encodedData and #encodedData > 0 and bShouldSend) then
			net.Start("NetStreamDS")
				net.WriteString(name)
				net.WriteUInt(#encodedData, 32)
				net.WriteData(encodedData, #encodedData)
			net.Send(recipients)
		end
	end

	if (DBugR) then
		netstream.Start = DBugR.Util.Func.AddDetour(netstream.Start, function(_, name, ...)
			local encodedData = pon.encode({...})
			DBugR.Profilers.Netstream:AddNetData(name, #encodedData)
		end)
	end

	net.Receive("NetStreamDS", function(length, client)
		local NS_DS_NAME = net.ReadString()
		local NS_DS_LENGTH = net.ReadUInt(32)
		local NS_DS_DATA = net.ReadData(NS_DS_LENGTH)

		if (NS_DS_NAME and NS_DS_DATA and NS_DS_LENGTH) then
			client.nsDataStreamName = NS_DS_NAME
			client.nsDataStreamData = ""

			if (client.nsDataStreamName and client.nsDataStreamData) then
				client.nsDataStreamData = NS_DS_DATA

				if (stored[client.nsDataStreamName]) then
					local bStatus, value = pcall(pon.decode, client.nsDataStreamData)

					if (bStatus) then
						stored[client.nsDataStreamName](client, unpack(value))
					else
						ErrorNoHalt("NetStream: '" .. NS_DS_NAME .. "'\n" .. value .. "\n")
					end
				end

				client.nsDataStreamName = nil
				client.nsDataStreamData = nil
			end
		end

		NS_DS_NAME, NS_DS_DATA, NS_DS_LENGTH = nil, nil, nil
	end)
else
	-- A function to start a net stream.
	function netstream.Start(name, ...)
		local encodedData = pon.encode({...})

		if (encodedData and #encodedData > 0) then
			net.Start("NetStreamDS")
				net.WriteString(name)
				net.WriteUInt(#encodedData, 32)
				net.WriteData(encodedData, #encodedData)
			net.SendToServer()
		end
	end

	if (DBugR) then
		netstream.Start = DBugR.Util.Func.AddDetour(netstream.Start, function(name, ...)
			local encodedData = pon.encode({...})

			DBugR.Profilers.Netstream:AddNetData(name, #encodedData)
		end)
	end

	net.Receive("NetStreamDS", function(length)
		local NS_DS_NAME = net.ReadString()
		local NS_DS_LENGTH = net.ReadUInt(32)
		local NS_DS_DATA = net.ReadData(NS_DS_LENGTH)

		if (NS_DS_NAME and NS_DS_DATA and NS_DS_LENGTH and stored[NS_DS_NAME]) then
			local bStatus, value = pcall(pon.decode, NS_DS_DATA)

			if (bStatus) then
				stored[NS_DS_NAME](unpack(value))
			else
				ErrorNoHalt("NetStream: '" .. NS_DS_NAME .. "'\n" .. value .. "\n")
			end
		end

		NS_DS_NAME, NS_DS_DATA, NS_DS_LENGTH = nil, nil, nil
	end)
end