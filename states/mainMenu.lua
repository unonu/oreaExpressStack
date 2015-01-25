do
	GLOBAL_initialState = "mainMenu"
	
	local mainMenu = {}
	mainMenu.__index = mainMenu

	function mainMenu.make()
		local m = {}
		setmetatable(m,mainMenu)

		m.x = res:load("sprite","test",50,50,100,100)

		return m
	end

	function mainMenu:draw()
		graphics.print("This is the main menu. Press space",0,0)
		self.x:draw(24,24)
	end

	function mainMenu:update(dt)
	end

	function mainMenu:keypressed(k)
		if k == ' ' then
			love.graphics.setBackgroundColor(0,math.random(0,255),0)
		elseif k == 'escape' then
			love.event.quit()
		end
	end

	return mainMenu

end