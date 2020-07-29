-- # A function to include files in a directory.
local function IncludeDirectory(directory)
	directory = "framework/" .. directory

	if (directory:sub(-1) ~= "/") then
		directory = directory .. "/";
	end

	for k, v in ipairs(file.Find(directory .. "*.lua", "LUA", "namedesc")) do
		netlibs.util.include(directory .. v)
	end
end

IncludeDirectory("plugins/netwrapper")
IncludeDirectory("plugins/classes")

IncludeDirectory = nil