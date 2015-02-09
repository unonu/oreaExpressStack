require("orea/orea")

function love.load()
	math.randomseed(os.time())
	orea.loadLibs()
	res = orea.buildRes()
	graphics = love.graphics
	mouse = love.mouse
	keyboard = love.keyboard
	keyboard.lastKey = nil

	GLOBAL_speed = 1
	GLOBAL_time = 0
	GLOBAL_checkedStates = false
	GLOBAL_stateArgs = {}
	GLOBAL_clockIcon = res:load("image","system/clock")
	GLOBAL_killTimeout = 0
	GLOBAL_lastActiveInput = "keyboard"
	GLOBAL_initialState = nil

	love.window.setMode(1280,720)
	width = love.window.getWidth()
	height = love.window.getHeight()

	states = orea.loadStates("states/")
	state = states[GLOBAL_initialState].make()
	_state = ""
end

function love.update(dt)
	local dt = dt * GLOBAL_speed
	if not state then print(ansicolors.red.."ABORT: Dropped state."..ansicolors.clear); love.event.quit() end
	if state.__name ~= _state then _state = state.__name; orea.updateStates(states,"states/",true) end
	if GLOBAL_time%20 < .02 and not GLOBAL_checkedStates then
		orea.updateStates(states,"states/",true); GLOBAL_checkedStates = true end
	if GLOBAL_time%20 > 1 then GLOBAL_checkedStates = false end
	--

	if state.update then
		state:update(dt)
	end

	--
	if keyboard.isDown("escape") then GLOBAL_killTimeout = GLOBAL_killTimeout + dt else GLOBAL_killTimeout = 0 end
	if GLOBAL_killTimeout > 5 then print(ansicolors.red.."ABORT: Escape key timeout."..ansicolors.clear); love.event.quit() end
	GLOBAL_time = GLOBAL_time + dt
end

function love.draw()
	if state.draw then
		state:draw()
	end

	--
	if not state.__upToDate then
		love.graphics.setColor(255,255,255)
		love.graphics.draw(GLOBAL_clockIcon,width-24,0)
	end
end

--[[ KEYBOARD ]]
function love.keypressed(k)
	keyboard.lastKey = k
	GLOBAL_lastActiveInput = "keyboard"
	--

	if state.keypressed then
		state:keypressed(k)
	end

	--
	if k == nil then
	elseif k == "r" and keyboard.isDown("lshift","rshift") and keyboard.isDown("lctrl","rctrl") then
		orea.updateStates(states,"states/")	
	end
end

function love.keyreleased(k)
	if state.keyreleased then
		state:keyreleasedd(k)
	end
end

--[[ MOUSE ]]
function love.mousepressed(x, y, button)
	GLOBAL_lastActiveInput = "keyboard"
	--

	if state.mousepressed then
		state:mousepressed(x, y, button)
	end
end

function love.mousereleased(x, y, button)
	if state.mousereleased then
		state:mousereleased(x, y, button)
	end
end

--[[ GAMEPAD ]]
function love.gamepadpressed(joystick, button)
	GLOBAL_lastActiveInput = "gamepad"
	--

	if state.gamepadpressed then
		state:gamepadpressed(joystick, button)
	end
end

function love.gamepadreleased(joystick, button)
	if state.gamepadreleased then
		state:gamepadreleased(joystick, button)
	end
end