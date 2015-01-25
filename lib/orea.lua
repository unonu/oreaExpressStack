--[[ Orea's supplementary features ]]

require("lib/ansicolors")
serialise = require("lib/serial")

----------------------------------------
--// String functions and operators //--
----------------------------------------

getmetatable('').__mul = function (str,r) return r == 0 and '' or string.rep(str,r) end
getmetatable('').__add = function (str,str2) return str..str2 end
getmetatable('').__index = function(str,i)
	if type(i) == 'number' then
		return string.sub(str,i,i)
	else
		return string[i]
	end
end
string.count = function (s,p)
	local c, i = 0, 1
	while i <= #s and s:find(p,i) do
		v,i = s:find(p,i)
		c,i = c + 1, i + 1
	end
	return c
end
string.split = function (s,d)
	local t = {}
	for i in s:gmatch("[^\'"..(d or '%s').."\']+") do
		t[#t+1] = i
	end

	return t
end
-- fill s to w width wiith f string
string.fillJustify = function (s,w,f)
	local value = ''..i
	if type(w) == "number" then
		local t = w
		for j = 1, s do
			t = t/10
			if t < 1 then
				value = f..value
			end
		end
	elseif type(w) == "string" then
		if #w > s then return w end
		for j = 1, s-#w do
			t = t/10
			if t < 1 then
				value = f..value
			end
		end
	end
	return value
end

-------------------------
--// Table functions //--
-------------------------

table.getIndex = function (t,item)
	if t and #t ~= nil then
		for i=1,#t do
			if t[i] == item then return i end
		end
	elseif t then
		for i,s in pairs(t) do
			if s == item then return i end
		end
	else return nil end
end
table.compare = function (t1,t2)
	if #t1 == #t2 then
		for i=1,#t1 do
			if t1[i] ~= t2[i] then return false end
		end
		return true
	end
end
table.map = function (t,f,...)
	local r = {}
	for k,v in pairs(t) do
		r[k] = f(v,...)
	end
	return r
end

-------------------------------
--// OREA custom functions //--
-------------------------------

if not orea then orea = {} end

--[[ Print a table and its contents ]]
function orea.printTable(t,_s)
	local s = "["..tostring(t).."]"
	_s = _s or 0
	io.write(s)
	local x = 0
	for i,e in pairs(t) do
		if type(e) == 'table' then
			io.write((' '):rep((#s+_s)*(x < 1 and x or 1)+1)..i..') ')
			orea.printTable(e,#s+_s+1+#(i..') '))
			io.write('\n')
		else
			io.write((' '):rep((#s+_s)*(x < 1 and x or 1)+1)..i..') '..e..' ['..type(e)..']\n')
		end
		x = x+1
	end
end

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

--[[ Prepare all the game states from a given directory ]]
function orea.loadStates(dir)
	print(ansicolors.yellow.."Loading States:"..ansicolors.clear)
	local files = love.filesystem.getDirectoryItems(dir or "")
	local states = {}
	for i,f in ipairs(files) do
		io.write("  "..f:sub(1,-5))
		local stateCode = love.filesystem.load((dir or "")..f)
		local success, state = pcall(stateCode)
		if success and state then
			io.write(ansicolors.green.." - Done"..ansicolors.clear)
			states[f:sub(1,-5)] = state
			states[f:sub(1,-5)].__name = f:sub(1,-5)
			states[f:sub(1,-5)].__modified = love.filesystem.getLastModified((dir or "")..f)
			states[f:sub(1,-5)].__upToDate = true
		else
			io.write(ansicolors.red.." - Fail: "..tostring(state)..ansicolors.clear)
		end
		print()
	end

	return states
end

--[[ Update game state files if we see a change ]]
function orea.updateStates(states, dir, test)
	local files = love.filesystem.getDirectoryItems(dir or "")
	for i,s in pairs(states) do
		if s.__modified ~= love.filesystem.getLastModified((dir or "")..s.__name..".lua") and (s.__upToDate or not test) then
			s.__upToDate = false
			print(s.__name.." was modified")
			if test ~= true then
				io.write("Updating "..s.__name)
				local _name = s.__name
				local success, stateCode = pcall(love.filesystem.load, (dir or "")..s.__name..".lua")
				if success then
					success, stateCode = pcall(stateCode)
					if success then
						io.write(" - Done")
						s = stateCode
						s.__name = _name
						s.__modified = love.filesystem.getLastModified((dir or "")..s.__name..".lua")
						s.__upToDate = true
						if state and state.__name == _name then
							state = s.make(unpack(GLOBAL_stateArgs))
						end
					end
				else
					io.write(" - Fail: "..tostring(stateCode).."  Continuing with old code")
				end
				print()
			end
		end
	end
end

--[[ Change the game state ]]
function changeState(name, ...)
	io.write("Changing State")
	local arg = {...}
	if states[name] then
		GOLOBAL_stateArgs = arg
		local tempState = {}
		success, tempState = pcall(states[name].make, unpack(arg))
		if success then
			io.write(ansicolors.green.." - Done: "..ansicolors.clear..tempState.__name)
			state = tempState
		else
			io.write(ansicolors.red.." - Fail: "..tempState..ansicolors.clear)
		end
	else
		io.write(ansicolors.red.." - Fail: No such state."..ansicolors.clear)
	end
	print()
end

--[[ Draws a cool background ]]
function orea.drawBack()
	for i=0, math.floor((screen.width+100)/48) do
	for ii=0, math.floor((screen.height+100)/48) do
		if ((i/2)-math.floor(i/2) > 0 and (ii/2)-math.floor(ii/2) == 0) or ((i/2)-math.floor(i/2) == 0 and (ii/2)-math.floor(ii/2) > 0) then
			love.graphics.setColor(190,190,190)
		else
			love.graphics.setColor(210,210,210)
		end
		love.graphics.rectangle('fill', -50+(i*48)+(((love.mouse.getX())-(screen.width/2))/16),-50+(ii*48)+(((love.mouse.getY())-(screen.height/2))/16),48,48)
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

--[[ Returns a table of configures gamepads ]]
function orea.loadGamepads()
	local joysticks = love.joystick.getJoysticks()
	for i,j in ipairs(joysticks) do
		local guid = j:getGUID()
		if j:getName() == "BDA PS3 Airflo wired controller" then
			love.joystick.setGamepadMapping(guid, "a", "button", 2)
			love.joystick.setGamepadMapping(guid, "b", "button", 3)
			love.joystick.setGamepadMapping(guid, "x", "button", 1)
			love.joystick.setGamepadMapping(guid, "y", "button", 4)
			love.joystick.setGamepadMapping(guid, "rightshoulder", "button", 6)
			love.joystick.setGamepadMapping(guid, "leftshoulder", "button", 5)
			love.joystick.setGamepadMapping(guid, "leftx", "axis", 1)
			love.joystick.setGamepadMapping(guid, "lefty", "axis", 2)
			love.joystick.setGamepadMapping(guid, "rightx", "axis", 3)
			love.joystick.setGamepadMapping(guid, "righty", "axis", 4)
			love.joystick.setGamepadMapping(guid, "triggerleft", "button", 7)
			love.joystick.setGamepadMapping(guid, "triggerright", "button", 8)
			love.joystick.setGamepadMapping(guid, "back", "button", 9)
			love.joystick.setGamepadMapping(guid, "start", "button", 10)
		elseif j:getName() == "Afterglow Gamepad for Xbox 360" then
			love.joystick.setGamepadMapping(guid, "a", "button", 1)
			love.joystick.setGamepadMapping(guid, "b", "button", 2)
			love.joystick.setGamepadMapping(guid, "x", "button", 3)
			love.joystick.setGamepadMapping(guid, "y", "button", 4)
			love.joystick.setGamepadMapping(guid, "rightshoulder", "button", 6)
			love.joystick.setGamepadMapping(guid, "leftshoulder", "button", 5)
			love.joystick.setGamepadMapping(guid, "leftx", "axis", 1)
			love.joystick.setGamepadMapping(guid, "lefty", "axis", 2)
			love.joystick.setGamepadMapping(guid, "rightx", "axis", 4)
			love.joystick.setGamepadMapping(guid, "righty", "axis", 5)
			love.joystick.setGamepadMapping(guid, "triggerleft", "axis", 3)
			love.joystick.setGamepadMapping(guid, "triggerright", "axis", 6)
		end
		print(j:getName(),j:getGUID(),j:isGamepad())
	end
	return joysticks
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

--[[ Interpolation types. Given a and c, beginning and end, this will return the value at b ]]
--[[ percent (x/1) along the interpolating path. ]]
orea.interpolations = {
	linear = function (a,b,c)
		return a + (c-a)*b
	end,
	sinusoidal = function (a,b,c)
		return a + (c-a)*math.sin(b*math.pi/2)
	end,
	quadratic = function (a,b,c)
		return a + (c-a)*(b*b)
	end,
	cubic = function (a,b,c)
		return a + (c-a)*(b^3)
	end
}
	orea.interpolations[1] = orea.interpolations.linear
	orea.interpolations[2] = orea.interpolations.sinusoidal
	orea.interpolations[3] = orea.interpolations.quadratic
	orea.interpolations[4] = orea.interpolations.cubic

--[[ Returns a value interpolated "b" percent along a to c in mode "mode." ]]
function orea.interpolate(a,b,c,mode)
	return orea.interpolations[mode](a,b,c)
end 

--[[ Returns a camera ]]
function newCamera(name,w,h)
	local c = {}
	c.__index = c

	c.x = 0
	c.y = 0
	c.z = 0
	c._x,c._y,c._z = c.x,c.y,c.z
	c.rotMatrix = {{},{},{}}
	c.xMatrix = {{1,0,0},{0},{0}}
	c.zMatrix = {{nil,nil,0},{nil,nil,0},{0,0,1}}
	c.vector = {}
	c.rx = 0
	c.ry = 0
	c.rz = 0
	c.zoom = 1
	c.sx, c.sy = 1,1
	c.width = w
	c.height = h
	c.r = 0
	c.zBuffer = love.graphics.newCanvas(w,h)
	c.timers = {
		--[[ Screen shake timer. How long, how much, whether to diminish ]]
		shake = {0,0,false},
		--[[ Fade timer. How long, in or out,time, method (linear), colour ]]
		fade = {0,0,0,1,{0,0,0},255},
		--[[ Target timer. Max time, destination x, destination y, destination z ]]
		--[[ time, method (sinusoidal), where we were before]]
		target = {0,0,0,0,0,2,0,0,0},
		--[[ Zoom timer. Max time, final zoom, time, method (sinusoidal), ]]
		--[[ previous zoom ]]
		zoom = {0,0,0,2,0}
	}
	--[[ Pixel shader to use on this camera ]]
	c.shader = nil
	--[[ Parent for the camera. The camera will follow it ]]
	c.parent = nil
	--[[ Set target. Location, time, interpolation method ]]
	c.setTarget = function (self, x,y,z,time,method)
		self.timers.target[1] = time
		self.timers.target[2] = x
		self.timers.target[3] = y
		self.timers.target[4] = z or self.z
		self.timers.target[5] = time
		self.timers.target[7] = self.x
		self.timers.target[8] = self.y
		self.timers.target[9] = self.z
		self.timers.target[6] = method or 1
	end
	--[[ Set fade. Time, direction, colour, interpolation method ]]
	c.fade = function (self,time,d,c,m)
		self.timers.fade[1] = time
		self.timers.fade[3] = time
		self.timers.fade[2] = d or 0
		self.timers.fade[5] = c or {0,0,0}
		self.timers.fade[4] = m or 1
	end
	--[[ Shake the camera ]]
	c.shake = function (self,time,delta,diminish)
		self.timers.shake[1] = time
		self.timers.shake[2] = delta
		self.timers.shake[3] = diminish
	end
	--[[ Zoom camera ]]
	c.setZoom = function (self,time,zoom,method)
		self.timers.zoom[1] = time
		self.timers.zoom[2] = zoom or 1
		self.timers.zoom[3] = time
		self.timers.zoom[4] = method or 2 
		self.timers.zoom[5] = self.zoom
	end
	c.update = function (self,dt,do3d)
		self._x,self._y,self._z = self.x,self.y,self.z

		--[[ Shake ]]
		if self.timers.shake[1] > 0 then
			self.timers.shake[1] = self.timers.shake[1] - 1
			if self.timers.shake[3] then
				self.timers.shake[2] = self.timers.shake[2]/2
			end
		else
			self.timers.shake[3] = false
		end
		--[[ Fade ]]
		if self.timers.fade[3] ~= 0 then
			self.timers.fade[6] = math.abs(orea.interpolate(0,self.timers.fade[3]/self.timers.fade[1],255,
				self.timers.fade[4])-(255*self.timers.fade[2]))
			self.timers.fade[3] = self.timers.fade[3] - .1
		end
		--[[ Target ]]
		if self.timers.target[4] ~= 0 then
			self.x = self.timers.target[2]
			self.y = self.timers.target[3]
			self.z = self.timers.target[4]
			self.timers.target[2] =
				orea.interpolate(self.timers.target[2],self.timers.target[5]/self.timers.target[1],
					self.timers.target[7],self.timers.target[5])
			self.timers.target[3] =
				orea.interpolate(self.timers.target[3],self.timers.target[5]/self.timers.target[1],
					self.timers.target[8],self.timers.target[5])
			self.timers.target[4] =
				orea.interpolate(self.timers.target[4],self.timers.target[5]/self.timers.target[1],
					self.timers.target[9],self.timers.target[5])	
			self.timers.target[5] = self.timers.target[5] - .1
		end
		--[[ Zoom ]]
		if self.timers.zoom[3] ~= 0 then
			self.z = orea.interpolate(self.timers.zoom[5],self.timers.zoom[3]/self.timers.zoom[1],
				self.timers.zoom[2],self.timers.zoom[4])
			self.timers.zoom[3] = self.timers.zoom[3] - .1
		end 
		if self.parent then
			self.x = parent.x - self.width/2 or 0
			self.y = parent.y - self.height/2 or 0
			self.z = parent.z or 0
		end

		if do3d then
			local cosx, cosz, sinx, sinz = math.cos(self.rx), math.cos(self.rz), math.sin(self.rx), math.sin(self.rz)
			self.xMatrix[2][2] = cosx
			self.xMatrix[2][3] = sinx
			self.xMatrix[3][2] = -sinx
			self.xMatrix[3][3] = cosx

			self.zMatrix[1][1] = cosz
			self.zMatrix[1][2] = -sinz
			self.zMatrix[2][1] = sinz
			self.zMatrix[2][2] = cosz

			for z=1, 3 do
			for x=1, 3 do
				self.rotMatrix[z][x] = self.xMatrix[z][1]*self.zMatrix[1][x]
									  +self.xMatrix[z][2]*self.zMatrix[2][x]
									  +self.xMatrix[z][3]*self.zMatrix[3][x]
			end
			end

			self.vector[1] = -sinz*sinx
			self.vector[2] = cosz*sinx
			self.vector[3] = cosx

			self.zBuffer:clear()
		end
	end
	--[[ Simple property functions ]]
	c.setParent = function (self, target)
		if target.x and target.y then
			c.parent = target
			return true
		end
		return false
	end
	c.setPosition = function (self, x, y, z)
		self.x = x or self.x
		self.y = y or self.y
	end
	c.getPosition = function (self) return self.x, self.y, self.z end
	c.getX = function (self) return self.x end
	c.getY = function (self) return self.y end
	c.scale = function (self, sx, sy)
		self.sx = sx or self.sx
		self.sy = sy or self.sx
	end
	c.releaseParent = function (self)
		self.parent = nil
	end
	c.setSize = function (self, w, h)
		self.width = w or self.width
		self.height = h or self.height
	end
	c.getSize = function (self) return self.width, self.height end
	c.getWidth = function (self) return self.width end
	c.getHeight = function (self) return self.heihgt end
	--[[ There aren't any rotation functions yet. Don't suppose I'll ever need them ]]
	--[[ Sets the camera to translate, rotate and scale according to the properties ]]
	c.set = function (self)
		love.graphics.push()
		love.graphics.translate(-self.x + self.width/2,-self.y + self.height/2)
		love.graphics.rotate(self.r)
		love.graphics.translate(-self.width/2,-self.height/2)
		love.graphics.scale(self.zoom)
		if self.timers.shake[1] ~= 0 then
			love.graphics.translate(math.random(-self.timers.shake[2],self.timers.shake[2]),
				math.random(-self.timers.shake[2],self.timers.shake[2]))
		end
		-- Camera Bounds:
		-- 	love.graphics.setColor(255, 0, 0)
		-- 	love.graphics.rectangle("line", 4, 4, self.width-8, self.height-8)
		-- 	love.graphics.setColor(255, 255, 255)
		love.graphics.setScissor(self.x,self.y,self.width,self.height)
	end
	--[[ Releases the alterations caused by the camera ]]
	c.release = function (self)
		love.graphics.setScissor()
		love.graphics.pop()
		if self.timers.fade[3] ~= 0 then
		love.graphics.setColor(self.timers.fade[5][1], self.timers.fade[5][2], self.timers.fade[5][3],
			self.timers.fade[6])
			love.graphics.rectangle("fill",0,0,self.width,self.height)
		end
	end

	return c
end

--[[ Converts letters to numbers like a boss ]]
function atoi(s)
	local i = 0
	for c in s:gmatch("%d") do i = i*10+c end
	return i
end

--[[ Converts a hex colour code to a table ]]
function hexToCol(h)
	local t
	for c in h:gmatch(".") do
		t = (t or '')..c..','
	end
	t = t:gsub("%a",function (s) return s:lower():byte()-87 end)
	t = t:split(",")
	return {t[2]*16+t[3],t[4]*16+t[5],t[6]*16+t[7]}
end

--[[ Makes an extreme colour by pushing away from "m." ]]
function orea.colorExtreme( table,m )
	local t ={}
	for i,v in ipairs(table) do
		if v >= m then t[i] = 255
		else t[i] = 0 end
	end
	return unpack(t)
end

--[[ Draws a dotted line ]]
function love.graphics.stippledLine( x1,y1,x2,y2,l,g )
	-- "l" and "g" are length and gap, respectively
	local ang = math.atan2((y2-y1),(x2-x1))
	local x_dist = math.cos(ang)
	local y_dist = math.sin(ang)
	for i=0, math.floor(((x2-x1)^2+(y2-y1)^2)^.5/(l+g)) do
		love.graphics.line(x1+(i*x_dist*(l+g)),y1+(i*y_dist*(l+g)),x1+(i*x_dist*(l+g))+(x_dist*l),y1+(i*y_dist*(l+g))+(y_dist*l))
	end
end

--[[ Draws an arc/curve without fill ]]
function love.graphics.curve(x,y,r,b,e,s)
	local points = {}
	local step = ((e-b))/s
	for i = 1, (s*2)+2, 2 do
		points[i] = x + math.cos(b+(step*(i-1)/2))*r
		points[i+1] = y + math.sin(b+(step*(i-1)/2))*r
	end
	love.graphics.line(unpack(points))
end

--[[ 3d mesh object ]]
function loadMesh(file)
	local vertices = {}
	local textures = {}
	local normals = {}
	local faces = {}
	local max,min = {-99999999,-99999999,-99999999}, {99999999,99999999,99999999}
	--
	local vertices2d = {}
	local cameraRot = {0,0,0} --camera rotation vector. used to calculate the 2d vertices

	for l in love.filesystem.lines(file) do
		line = l:split(' ')
		if line[1] == 'v' then
			vertices[#vertices+1] = table.map({select(2, unpack(line) )},tonumber)
			max[1] = math.max(max[1], vertices[#vertices][1])
			max[2] = math.max(max[2], vertices[#vertices][2])
			max[3] = math.max(max[3], vertices[#vertices][3])
			min[1] = math.min(min[1], vertices[#vertices][1])
			min[2] = math.min(min[2], vertices[#vertices][2])
			min[3] = math.min(min[3], vertices[#vertices][3])
		elseif line[1] == 'vt' then
			textures[#textures+1] = table.map({select(2, unpack(line) )},tonumber)
			textures[#textures][2] = -textures[#textures][2]
		elseif line[1] == 'vn' then
			normals[#normals+1] = table.map({select(2, unpack(line) )},function (a) return -tonumber(a) end)
		elseif line[1] == 'f' then
			faces[#faces+1] = table.map({select(2, unpack(line) )}, string.split, '/')
			faces[#faces].id = {select(2, unpack(line) )}
		end
	end

	local _faces = {}
	for i,f in ipairs(faces) do
		local _f = {}
		_f[1] = {vertices[tonumber(f[1][1])], --vertices
				 vertices[tonumber(f[2][1])],
				 vertices[tonumber(f[3][1])]}
		_f[2] = {textures[tonumber(f[1][2])] or {0,0}, --texture
				 textures[tonumber(f[2][2])] or {0,0},
				 textures[tonumber(f[3][2])] or {0,0}}
		_f[3] = {normals[tonumber(f[1][3])], --normal
				 normals[tonumber(f[2][3])],
				 normals[tonumber(f[3][3])]}
		--[[ initialise the 2d triangle ]]
		for v=1,3 do
			local x,y
			x = _f[1][v][1]
			y = _f[1][v][2]
			vertices2d[(i-1)*3 +v] = { x,
									   -y,
									   _f[2][v][1],
									   _f[2][v][2],
									   0,0,0}
		end
		_faces[i] = _f
	end
	faces = _faces

	return vertices2d, vertices, faces, {min[1],min[2],min[3],max[1],max[2],max[3]}

end

mesh = {}
mesh.__index = mesh
function mesh.make(file, texture)
	local m = {}
	setmetatable(m, mesh)
	local vertices2d, vertices, faces, extrema = loadMesh(file)
	m.vertices2d = vertices2d
	m.vertices3d = vertices3d
	m.faces = faces
	m.extrema = extrema
	m.vertices3d = {}
	for i=1, #m.vertices2d do
		m.vertices3d[i] = {{},{},{}}
	end
	m.texture = nil
	if type(texture) == "string" then
		m.texture = love.graphics.newImage(texture)
		m.texture:setFilter("nearest")
	else
		m.texture = texture
	end
	local t = m.texture and m.texture:setWrap("repeat") or nil
	m.drawable = love.graphics.newMesh(vertices2d, m.texture, "triangles")
	m.scale = (m.extrema[5]-m.extrema[2])/(m.extrema[4]-m.extrema[1])

	return m
end

function mesh:draw(x,y,r,sx,sy,ox,oy,kx,ky)
	love.graphics.draw(self.drawable,x,y,r,sx or 1,(sy or sx or 1),ox,oy or ox,kx,ky or kx)
end

function mesh:update(camera)
	local drawList = {} --[[ indecies of faces to be drawn ]]
	local processed = {} --[[ vertices already processed ]]
	local newMap = {} --[[ the new vertex map ]]
	local zOrder = {} --[[ z value of the face with the same index ]]

	--[[ loop through faces ]]
	for i=1, #self.faces do
		local f = self.faces[i]
		--[[ cull backfaces ]]
		-- local dp = -camera.vector[1]*f[3][1][1] + camera.vector[3]*f[3][1][2] - camera.vector[2]*f[3][1][3]
		-- if dp < 0 then
			--[[ loop through vertices ]]
			local id
			for v=1, 3 do
				--[[ figure out which vertex in vertex2d we're working on ]]
				id = (i-1)*3 +(v)

				--[[ check if this was processed ]]
				if not processed[id] then
					processed[id] = true

					--[[ project the 3d to 2d ]]
					self.vertices3d[i][v][1] = f[1][v][1]*camera.rotMatrix[1][1]
											  -f[1][v][2]*camera.rotMatrix[1][2]
											  -f[1][v][3]*camera.rotMatrix[1][3]
					self.vertices3d[i][v][2] = f[1][v][1]*camera.rotMatrix[2][1]
											  -f[1][v][2]*camera.rotMatrix[2][2]
											  -f[1][v][3]*camera.rotMatrix[2][3]
					self.vertices3d[i][v][3] = f[1][v][1]*camera.rotMatrix[3][1]
											  -f[1][v][2]*camera.rotMatrix[3][2]
											  -f[1][v][3]*camera.rotMatrix[3][3]
				end

				--[[ assign the coords, uv and colour to the vertex ]]
				self.drawable:setVertex(id, self.vertices3d[i][v][1], self.vertices3d[i][v][2], f[2][v][1], f[2][v][2], 255, 255, 255)
			end

			--[[ calculate z order ]]
			zOrder[i] = (self.vertices3d[i][1][3]
						 +self.vertices3d[i][2][3]
						 +self.vertices3d[i][3][3])
								  /3
			--[[ add to draw list ]]
			drawList[#drawList+1] = i
		-- end
	end

	--[[ sort by z order ]]
	table.sort(drawList, function (a,b) return zOrder[a] > zOrder[b] end)

	love.graphics.setCanvas(camera.zBuffer)
	love.graphics.push()
	love.graphics.translate(-camera.x, -camera.y)
	local normaliser = -(zOrder[drawList[1]] - zOrder[drawList[#drawList]])/2
	local normaliser = -360
	local zVerts = {{0,0,nil,nil,0,0,0},{0,0,nil,nil,0,0,0},{0,0,nil,nil,0,0,0}}
	local zMesh = love.graphics.newMesh(zVerts, nil, "triangles")
	for i=1, #drawList do
		newMap[#newMap+1] = (drawList[i]-1)*3 +1
		newMap[#newMap+1] = (drawList[i]-1)*3 +2
		newMap[#newMap+1] = (drawList[i]-1)*3 +3
		--[[ Draw to z bufer canvas ]]
		--[[ User this for a rough z buffer ]]
		-- local zColor = ((zOrder[drawList[i]]/normaliser) + 1) * 128
		-- zColor = zColor > 0 and (zColor < 255 and zColor or 255) or 0
		-- love.graphics.setColor(zColor,zColor,zColor)
		-- love.graphics.polygon("fill", self.vertices3d[drawList[i]][1][1],self.vertices3d[drawList[i]][1][2],
		-- 							  self.vertices3d[drawList[i]][2][1],self.vertices3d[drawList[i]][2][2],
		-- 							  self.vertices3d[drawList[i]][3][1],self.vertices3d[drawList[i]][3][2],
		-- 							  self.vertices3d[drawList[i]][1][1],self.vertices3d[drawList[i]][1][2])
		--[[ Use this for a smooth z buffer ]]
		local zColor1 = ((self.vertices3d[drawList[i]][1][3]/normaliser) + 1) * 128
		local zColor2 = ((self.vertices3d[drawList[i]][2][3]/normaliser) + 1) * 128
		local zColor3 = ((self.vertices3d[drawList[i]][3][3]/normaliser) + 1) * 128
		zColor1 = zColor1 > 0 and (zColor1 < 255 and zColor1 or 255) or 0
		zColor2 = zColor2 > 0 and (zColor2 < 255 and zColor2 or 255) or 0
		zColor3 = zColor3 > 0 and (zColor3 < 255 and zColor3 or 255) or 0
		zMesh:setVertex(1,self.vertices3d[drawList[i]][1][1],self.vertices3d[drawList[i]][1][2],nil,nil, zColor1,zColor1,zColor1)
		zMesh:setVertex(2,self.vertices3d[drawList[i]][2][1],self.vertices3d[drawList[i]][2][2],nil,nil, zColor2,zColor2,zColor2)
		zMesh:setVertex(3,self.vertices3d[drawList[i]][3][1],self.vertices3d[drawList[i]][3][2],nil,nil, zColor3,zColor3,zColor3)
		love.graphics.draw(zMesh)
	end
	love.graphics.pop()
	love.graphics.setCanvas()

	newMap = #newMap > 3 and newMap or {1,1,1}

	-- remap vertices
	self.drawable:setVertexMap(newMap)
end

--------------------------------
--// Custom maths functions //--
--------------------------------

function math.loop(min,v,max) if v > max then return min elseif v < min then return max else return v end end
function math.carryLoop(min,v,max) return ((v-min)%(max-min))+min end
-- Gets the intersection 
function math.getIntercept(l1p1, l1p2, l2p1, l2p2)
	local m1 = (l1p2[2]-l1p1[2])/(l1p2[1]-l1p1[1])
	local m2 = (l2p2[2]-l2p1[2])/(l2p2[1]-l2p1[1])
	local b1 = -m1*l1p1[1]+l1p1[2]
	local b2 = -m2*l2p1[1]+l2p1[2]
	local x = (b2-b1)/(m1-m2)
	local y = m1*x+b1
	return x,y
end

-- Takes three points, first two are line {} {} {}
function math.getPerpIntercept(lp1,lp2,p3)
	local h = math.dist(lp1[1],lp1[2],p3[1],p3[2])
	local phi = math.atan2(lp2[2]-lp1[2],lp2[1]-lp1[1])
	local the = math.atan2(p3[2]-lp1[2],p3[1]-lp1[1]) - phi
	local a = h*math.cos(the)
	local x = a/math.cos(phi)
	local y = a/math.sin(phi)
	return x,y
end

-- Gets the shortest distance between the line and the point
function math.getPerpDistance(lp1,lp2,p3)
	local h = math.dist(lp1[1],lp1[2],p3[1],p3[2])
	local phi = math.atan2(lp2[2]-lp1[2],lp2[1]-lp1[1])
	local the = math.atan2(p3[2]-lp1[2],p3[1]-lp1[1]) - phi
	return h*math.sin(the)
end

-- Gets the projection of line oy on to ox. Or vice versa?
function math.projection(ox,oy,x1,y1,x2,y2)
	-- first minus second is positive
	local h1 = math.dist(ox,oy,x1,y1)
	local phi = math.atan2(y1-oy,x1-ox)
	local the = math.atan2(y2-oy,x2-ox)
	return math.cos(phi-the)*h1
end

-----------------------------------
--// Stuff form the math+ file //--
-----------------------------------

-- Averages an arbitrary number of angles.
function math.averageAngles(...)
    local x,y = 0,0
    for i=1,select('#',...) do local a= select(i,...) x, y = x+math.cos(a), y+math.sin(a) end
    return math.atan2(y, x)
end


-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
-- Distance between two 3D points:
function math.dist(x1,y1,z1, x2,y2,z2) return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5 end


-- Returns the angle between two points.
function math.getAngle(x1,y1, x2,y2) return math.atan2(x2-x1, y2-y1) end


-- Returns the closest multiple of 'size' (defaulting to 10).
function math.multiple(n, size) size = size or 10 return math.round(n/size)*size end


-- Clamps a number to within a certain range.
function math.clamp(low, n, high) return math.min(math.max(n, low), high) end


-- Normalizes two numbers.
function math.normalize(x,y) local l=(x*x+y*y)^.5 if l==0 then return 0,0,0 else return x/l,y/l,l end end
-- Normalizes a table of numbers.
function math.normalize(t) local n,m = #t,0 for i=1,n do m=m+t[i] end m=1/m for i=1,n do t[i]=t[i]*m end return t end


-- Returns 'n' rounded to the nearest 'deci'th.
function math.round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end


-- Randomly returns either -1 or 1.
function math.rsign() return math.random(2) == 2 and 1 or -1 end


-- Returns 1 if number is positive, -1 if it's negative, or 0 if it's 0.
function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end


-- Checks if two line segments intersect. Line segments are given in form of ({x,y},{x,y}, {x,y},{x,y}).
function math.checkIntersect(l1p1, l1p2, l2p1, l2p2)
    local function checkDir(pt1, pt2, pt3) return math.sign(((pt2[1]-pt1[1])*(pt3[2]-pt1[2])) - ((pt3[1]-pt1[1])*(pt2[2]-pt1[2]))) end
    return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end

-- Checks if two rectangles overlap. Rectangles are given in form of ({x,y},{x,y}, {x,y},{x,y}).
function math.CheckCollision(box1x, box1y, box1w, box1h, box2x, box2y, box2w, box2h)
    if box1x > box2x + box2w - 1 or -- Is box1 on the right side of box2?
       box1y > box2y + box2h - 1 or -- Is box1 under box2?
       box2x > box1x + box1w - 1 or -- Is box2 on the right side of box1?
       box2y > box1y + box1h - 1    -- Is b2 under b1?
    then
        return false                -- No collision. Yay!
    else
        return true                 -- Yes collision. Ouch!
    end
end

function unrequire(m)
	package.loaded[m] = nil
	_G[m] = nil
end