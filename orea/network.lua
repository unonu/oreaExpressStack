if not orea then orea = {} end

socket = require("socket")

----------------------------------
--// Custom network functions //--
----------------------------------

local function expandTable(s)
	local t = {}
	for e in s:gmatch("[^\',\']+") do
		t[#t] = e[1] ~= '[' and (tonumber(e) or e) or expandTable(e:sub(2,-2)) 
	end
	return t
end

local function compressTable(t)
	local s = ''
	for i=1, #t do
		s = s.. (type(t[i]) ~= 'table' and t[i] or '['..compressTable(t[i])..']')..','
	end
	return s:sub(1,-2)
end

server = {}
server.__index = server

function server.make(address,port)
	local s = {}
	setmetatable(s, server)

	s.address,s.port = address or "localhost", port or 25225
	s.connection = socket.udp()
	s.connection:settimeout(0)
	s.connection:setsockname('*',s.port)

	s.clients = {}
	s.commands = {}
	s.commands["????"] = function (self, a) return {self.clients[a[1]], #self.clients} end 

	s.request = {data = '', ip = '', port = ''}

	return s
end

function server:update(dt)
	self.request.data,
	self.request.ip,
	self.request.port
			= 
	self.connection:receivefrom()

	if not self.clients[self.request.ip] then
		self.clients[#self.clients+1] = self.request.ip
		self.clients[self.request.ip] = #self.clients
		self:reply("????",self.request.ip)
	end

	--[[ The server requests take the form of a 64 bit id followed by a 32 bit   ]]
	--[[ (4 character) command, followed by the arguments for the matching       ]]
	--[[ command, seperated by commas. ]]
	if self.request.data then
		local id = self.request.data:sub(1,8)
		local command = self.request.data:sub(9,12)
		self:reply(command, self.request.data:sub(13))
	end
	socket.sleep(.01)
end

function server:reply(command, data)
	if self.commands[command] then
		local args = expandTable(data)
		args.ip = self.request.ip
		args.port = self.request.port
		local success, e = pcall(self.commands[command], self, args)
		if success then self.connection:sendto( compressTable(e),
												args.ip,
												args.port)
		else print(e) end
	end
end

--[[ Don't forget, all server commands must return a table! ]]
function server:addCommand(command,func)
	if #command == 4 then
		self.commands[command] = func
	end
end

client = {}
client.__index = client

function client.make(address,port)
	local c = {}
	setmetatable(c, client)

	c.connection = socket.udp()
	c.address, c.port = c.connection:getsockname()
	c.connection:settimeout(0)
	c.connection:setpeername(address or "localhost", port or 25225)

	c.dt = 0
	c.updateRate = 0.1

	c.commands = {}
	c.requests = {}
	c.commands["????"] = function (self, a) 
		if not self.id then
			self.id = tostring(math.random(1,9999)):fillJustify(4,'0')..
						tostring(a[1]):fillJustify(4,'0')
		end
	end 

	c.id = nil
	client:request("????")

	return c
end

function client:update(dt)
	self:recieve()

	self.dt = self.dt + dt
	if self.dt > self.updateRate then
		for i=1, #self.requests do
			self.connection:send(self.id or "00000000" ..
								 self.requests[i][1]   ..
								 compressTable(self.requests[i][2]))
		end
		self.requests = {}
		collectgarbage()
		self.dt = 0
	end
end

function client:request(command, ...)
	if #command == 4 then
		if self.requests[command] then
			self.requests[self.requests[command]] = {command, ...}
		else
			self.requests[#self.requests+1] = {command, ...}
			self.requests[command] = #self.requests
		end
	end
end

function client:receive()
	local data = nil
	repeat
		data = self.connection:receive()
		if data then
			local command = data:sub(1,4)
			local args = {}
			for t in data:sub(5):gmatch("[^\',\']+") do
				if t[1] == '[' then
					args[#args+1] = expandTable(t:sub(2,-2))
				else
					args[#args+1] = tonumber(t) or e
				end
			end
			local success, e = pcall(self.commands[command], self, args)
			if not success then print(e) end
		end
	until not data
end

function client:addCommand(command,func)
	if #command == 4 then
		self.commands[command] = func
	end
end