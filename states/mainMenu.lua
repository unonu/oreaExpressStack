do
	GLOBAL_initialState = "mainMenu"
	
	local mainMenu = {}
	mainMenu.__index = mainMenu

	function mainMenu.make()
		local m = {}
		setmetatable(m,mainMenu)

		love.graphics.setBackgroundColor(0,0,255)

		m.logo = res:load("image","system/orea")

		m.x = goo.window.make("Menu", 540,260,200,100)
		local frame = m.x:addElement("frame")
		frame:setAnchor(2)
		frame:addElement("text","Hello! this is a game made by OREA","center")
		frame:addElement("vSpace",20)
		frame:addElement("button","Quit",nil,function () love.event.quit() end)

		return m
	end

	function mainMenu:draw()
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(self.logo,width,height,0,.5,.5,self.logo:getWidth(),self.logo:getHeight())

		self.x:draw()

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

	function mainMenu:mousepressed(x,y,button)
		self.x:mousepressed(x,y,button)
	end

	return mainMenu

end