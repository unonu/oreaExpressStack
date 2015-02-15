if not orea then orea = {} end

------------------------------
--// Custom GUI functions //--
------------------------------

goo = {}
goo.elements = {}

goo.window = {}
local window = goo.window
window.__index = window

function window.make(title,x,y,width,height)
	local w = {}
	setmetatable(w, window)

	w.title = title
	w.x, w.y = x, y
	w.width = width
	w.height = height
	w.elements = {}
	w.elements.height = 0
	w.elements.width = 0
	w.anchors = {w.x,w.y,w.x+w.width,w.y+w.height}
	w.focus = true

	return w
end

function window:draw()
	love.graphics.setColor(255, 255, 255, 200)
	love.graphics.rectangle("fill",self.x-2,self.y-2,self.width+4,self.height+4)
	love.graphics.setColor(0, 0, 0, 90)
	love.graphics.rectangle("fill",self.x,self.y,self.width,18)

	love.graphics.setColor(0, 0, 0)
	love.graphics.printf(self.title,self.x,self.y+2,self.width,"center")

	local h,v = 0,20
	for i=1, #self.elements do

			self.elements[i]:draw(self.x+h, self.y+v)
			if self.cascade == "vertical" then
				v = v + self.elements[i].height
				h = math.min(h, self.elements[i].width)
			elseif self.cascade == "horizontal" then
				v = 0
				h = h + self.elements[i].width
			end

	end
end

function window:mousepressed(x,y,button)
	for i=1, #self.elements do
		if self.elements[i].mousepressed then 
			self.elements[i]:mousepressed(x,y,button)
		end
	end
end

function window:mousereleased(x,y,button)
	for i=1, #self.elements do
		self.elements[i]:mousereleased(x,y,button)
	end
end

function window:addElement(element,...)
	self.elements[#self.elements+1] = goo.elements[element].make(self, ...)
	self.elements.height = self.elements.height + self.elements[#self.elements].height
	self.elements.width = self.elements.width + self.elements[#self.elements].width
	return self.elements[#self.elements]
end

goo.elements.frame = {}
local frame = goo.elements.frame
frame.__index = frame

function frame.make(parent, vFill, hFill)
	local f = {}
	setmetatable(f, frame)

	f.parent = parent
	f.elements = {}
	f.elements.height = 0
	f.elements.width = 0
	f.vFill = vFill or "stretch"
	f.hFill = hFill or "stretch"
	f.width = 0
	f.height = 0
	if f.hFill == "stretch" then
		f.width = parent.width
	end
	if f.vFill == "stretch" then
		f.height = parent.height
	end
	f.anchors = parent.anchors
	f.anchor = 1
	f.cascade = "vertical"

	return f
end

function frame:addElement(element,...)
	self.elements[#self.elements+1] = goo.elements[element].make(self, ...)
	self.height = math.min(self.height + self.elements[#self.elements].height, self.parent.height)
	self.width = math.min(self.width + self.elements[#self.elements].width, self.parent.width)

	if self.hFill == "stretch" then
		self.width = self.parent.width
	end

	return self.elements[#self.elements]
end

function frame:setAnchor(n)
	self.anchor = n
end

function frame:draw(x,y)
	local h,v = 0,0
	for i=1, #self.elements do

			if self.anchor == 1 then
				self.elements[i]:draw(x+h, y+v)
			elseif self.anchor == 2 then
				self.elements[i]:
					draw(self.anchors[3]-h-self.elements[i].width, y+v)
			elseif self.anchor == 3 then
				self.elements[#self.elements +1 -i]:draw(x+h, self.anchors[4]-v)
			else
				self.elements[#self.elements +1 -i]:
					draw(self.anchors[3]-h-self.elements[#self.elements +1 -i].width, self.anchors[4]-v)
			end
			if self.cascade == "vertical" then
				v = v + self.elements[i].height+8
				h = 0
			elseif self.cascade == "horizontal" then
				v = 0
				h = h + self.elements[i].width
			end

	end

	-- love.graphics.setColor(255,0,0)
	-- love.graphics.rectangle("line",x,y,self.width,self.height)
end

function frame:mousepressed(x,y,button)
	for i=1, #self.elements do
		if self.elements[i].mousepressed then 
			self.elements[i]:mousepressed(x,y,button)
		end
	end
end

function frame:mousereleased(x,y,button)
	for i=1, #self.elements do
		self.elements[i]:mousereleased(x,y,button)
	end
end

goo.elements.button = {}
local button = goo.elements.button
button.__index = button

function button.make(parent, text, source, target, t2)
	local b = {}
	setmetatable(b, button)

	b.parent = parent
	b.text = text
	b.source = source
	b.target = target
	b.t2 = t2
	b.focus = false
	b.width = love.graphics.getFont():getWidth(text)+8
	b.height = love.graphics.getFont():getHeight(text)+8
	b.x, b.y = 0,0

	return b
end

function button:trigger()
	if type(self.source) == "function" then
		if type(self.target) == "function" then
			self.target(self.source())
		else
			self.target[self.t2] = self.source()
		end
	else
		if type(self.target) == "function" then
			self.target(self.source)
		else
			self.target[self.t2] = self.source
		end
	end
end

function button:draw(x,y)
	self.x, self.y = x, y
	love.graphics.setColor(255,255,255)
	love.graphics.rectangle("fill", x, y, self.width, self.height)

	love.graphics.setColor(0,0,0)
	love.graphics.print(self.text,x+4,y+4)

	love.graphics.rectangle("line", x, y, self.width, self.height)
end

function button:keyboard(k)
	if self.focus and k == "return" then
		self:trigger()
	end
end

function button:mousepressed(x, y, button)
	if button == 'l' and x > self.x and y > self.y and
		x < self.x+self.width and y < self.y+self.height then
		self:trigger()
	end
end

goo.elements.text = {}
local text = goo.elements.text
text.__index = text

function text.make(parent, value, align, sx, sy, r, kx, ky)
	local t = {}
	setmetatable(t, text)

	t.parent = parent
	t.value = value
	t.align = align or "left"
	t.sx = sx or 1
	t.sy = sy or 1
	t.r = r or 0
	t.kx = kx or 0
	t.ky = ky or 0
	t.width = parent.width or 100
	t.height = love.graphics.getFont():getHeight(value)
				* math.floor(love.graphics.getFont():getWidth(value)/t.width) + 8
	t.color = {0,0,0,255}

	return t
end

function text:draw(x, y)
	love.graphics.setColor(unpack(self.color))
	love.graphics.printf(self.value,x,y,self.parent.width or 100,
		self.align, self.r, self.sx, self.sy,0,0,self.kx, self.ky)
end

goo.elements.vSpace = {}
local vSpace = goo.elements.vSpace
vSpace.__index = vSpace

function vSpace.make(parent, size)
	local v = {}
	setmetatable(v, vSpace)

	v.height = size
	v.width = parent.width

	return v
end

function vSpace:draw(x,y)
end