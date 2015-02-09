if not orea then orea = {} end

serialise = require("orea/serial")

--------------------------------------
--// Custom file system functions //--
--------------------------------------

--[[ Recursively enumerate the files in the given directory ]]
function orea.recursiveEnumerate(dir,paths)
	local found = love.filesystem.getDirectoryItems(dir)
	for i,p in ipairs(found) do
		table.insert(paths,(dir or "")..p)
		if love.filesystem.isDirectory((dir or "")..p) then
			orea.recursiveEnumerate((dir or "")..p.."/",paths)
		end
	end
end

--[[ Recursively remove the files in the given directory ]]
function orea.recursiveRemove(dir,paths)
	local found = love.filesystem.getDirectoryItems(dir)
	for i,p in ipairs(found) do
		-- table.insert(paths,(dir or "")..p)
		if love.filesystem.isDirectory((dir or "")..p) then
			orea.recursiveRemove((dir or "")..p.."/",paths)
		else
			love.filesystem.remove((dir or "")..p)
		end
	end
	love.filesystem.remove(dir)
end

--[[ Require all files in the "libs" folder ]]
function orea.loadLibs()
	print(ansicolors.yellow.."Loading Libraries in \"lib/\":"..ansicolors.clear)
	local files = {}
	orea.recursiveEnumerate("lib/", files)
	for i,l in ipairs(files) do
		if l:sub(-4) == ".lua" and l ~= "lib/orea.lua" and l ~= "lib/ansicolors.lua" and l ~= "lib/serial.lua" then
			io.write("  "..l:sub(1,-5))
			local success, message = pcall(require, l:sub(1,-5))
			if success then
				io.write(ansicolors.green.." - Done"..ansicolors.clear)
			else
				io.write(ansicolors.red.." - Fail: "..message..ansicolors.clear)
			end
			print()
		end
	end
end

--[[ Initialises the filesystem ]]
function orea.initFS(name)
	io.write(ansicolors.yellow.."Initialising FIlesystem"..ansicolors.clear)
	if not love.filesystem.exists(name) then
		love.filesystem.setIdentity(name)
	end
	io.write('.')
	if not love.filesystem.exists("joysticks") then
		love.filesystem.createDirectory("joystickthens")
	end
	io.write('.')
	if not love.filesystem.exists("records") then
		love.filesystem.createDirectory("records")
	end
	io.write('.')
	if not love.filesystem.exists("saves") then
		love.filesystem.createDirectory("saves")
	end
	io.write('.')
	if not love.filesystem.exists("worlds") then
		love.filesystem.createDirectory("worlds")
	end
	io.write('.')
	if not love.filesystem.exists("config") then
		love.filesystem.setIdentity(name)
		local config = love.filesystem.newFile("config")
		config:open('w')
		config:write("#Config File")
		config:close()
	end
	io.write('.')

	print()
end

--[[ Converts a string to some numbers and those numbers to char codes which are returned as a string]]
function orea.obscure(s)
	local c = {}
	for i=1, #s do
		c[i] = string.byte(s:sub(i,i))
		if c[i] > 99 or c[i] < 10 then print("Warning: Obscured char code of invalid length. Expect corruption") end
		--maybe act on this corruption
	end
	local r = ''
	for i,v in ipairs(c) do
		r = r..string.char(tostring(v):sub(1,1))
		r = r..string.char(tostring(v):sub(2,2))
	end
	return r
end

--[[ Load fonts from res/fonts ]]
function orea.loadFonts()
	print(ansicolors.yellow.."Loading Fonts:"..ansicolors.clear)
	local fonts = {}
	local numFonts = 0
	local files = love.filesystem.getDirectoryItems('res/fonts/')
	for i, f in ipairs(files) do
		if f:sub(-4) == '.png' then
			local fontDef = love.filesystem.read('fonts/'..f:sub(1,-4)..'font'):sub(1,-2)
			io.write(ansicolors.cyan.."  "..f..ansicolors.clear.." - "..fontDef)
			fonts[f:sub(1,-5)] = love.graphics.newImageFont('fonts/'..f,fontDef)
			numFonts = numFonts + 1
		elseif f:sub(-4) == '.ttf' then
			io.write(ansicolors.blue.."  "..f..ansicolors.clear)
			fonts[f:sub(1,-5)] = love.graphics.newFont('fonts/'..f,16)
			numFonts = numFonts + 1
		end
		print()
	end
	return fonts
end

function unrequire(m)
	package.loaded[m] = nil
	_G[m] = nil
end