if not orea then orea = {} end

--------------------------------
--// Custom state functions //--
--------------------------------

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
