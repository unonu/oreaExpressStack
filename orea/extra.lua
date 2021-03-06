if not orea then orea = {} end

----------------------------------------
--// String functions and operators //--
----------------------------------------

getmetatable('').__mul = function (str,r) return r == 0 and '' or string.rep(str,r) end
getmetatable('').__add = function (str,str2) return str..str2 end
getmetatable('').__index = function(str,i,e)
	if type(i) == 'number' then
		return string.sub(str,i,e or i)
	else
		return string[i]
	end
end
string.count = function (s,p)
	local c = 0
	for i in s:gmatch(p) do c = c + 1 end
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