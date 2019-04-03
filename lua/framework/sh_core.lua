-- # A function to include files in a directory.
function util.IncludeDirectory(directory, base)
	if (base) then
		directory = "framework/"..directory
	end
	
	if (string.sub(directory, -1) != "/") then
		directory = directory.."/";
	end
	
	local files, _ = file.Find(directory.."*.lua", "LUA", "namedesc")
	for k, v in ipairs(files) do
		util.Include(directory..v)
	end
end

util.IncludeDirectory("plugins/netwrapper", true)
util.IncludeDirectory("plugins/tables", true)

util.IncludeDirectory = nil