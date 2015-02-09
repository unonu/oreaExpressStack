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
	w.anchors = {w.x,w.y,w.x+w.width,w.y+w.height}
	w.focus = true

	return w
end

function window:draw()
	local h,v = 0,0
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

function window:addElement(element,...)
	self.elements[#self.elements+1] = element.make(self, ...)
	self.elements.height = self.elements.height + self.elements[#self.elements].height
	self.elements.width = self.elements.width + self.elements[#self.elements].width
end

goo.frame = {}
local frame = goo.frame
frame.__index = frame

function frame.make(parent, vFill, hFill)
	local f = {}
	setmetatable(f, frame)

	f.elements = {}
	f.vFill = vFill or "stretch"
	f.hFill = hFill or "stretch"
	f.width = 0
	f.height = 0
	f.anchors = parent.anchors
	f.anchor = 1
	f.cascade = "vertical"

	return f
end

function frame:addElement(element,...)
	self.elements[#self.elements+1] = element.make(self, ...)
	self.height = self.height + self.elements[#self.elements].height
	self.width = self.width + self.elements[#self.elements].width
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
			self.elements[#self.elements +1 -i]:draw(self.anchors[3]-h, y+v)
		elseif self.anchor == 3 then
			self.elements[i]:draw(x+h, self.anchors[4]-v)
		else
			self.elements[#self.elements +1 -i]:draw(self.anchors[3]-h, self.anchors[4]-v)
		end
		if self.cascade == "vertical" then
			v = v + self.elements[i].height
			h = math.min(h, self.elements[i].width)
		elseif self.cascade == "horizontal" then
			v = 0
			h = h + self.elements[i].width
		end
	end

	love.graphics.rectangle("line",x,y,self.width,self.height)
	
end

goo.button = {}
local button = goo.button
button.__index = button

function button.make(text, source, target, t2)
	local b = {}
	setmetatable(b, button)

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

	love.graphics.print(self.text,x+4,y+4)

	love.graphics.setColor(0,0,0)
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