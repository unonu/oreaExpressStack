animation = {}
animation.__index = animation

--[[ Create new animation: image, frame width, frame height,
 reference width, reference height, number of frames [(_rw/_w)*(_rh/_h)], delay in frames [0], mode ["loop"] ]]
animation.__call = function (_image, _w, _h, _rw, _rh, _f, _d, _m)
	local a = {}
	setmetatable(a,animation)
	a.image = res:load("sprite", _image)
end

function newAnimation(_image, _w, _h, _rw, _rh, _f, _d, _m)
	local a = {}
	a.__index = a
	a.image = love.graphics.newImage(_image)
	a.quad = love.graphics.newQuad(0,0,_w,_h,_rw,_rh)
	a.frames = math.min((_rw/_w)*(_rh/_h),_f or (_rw/_w)*(_rh/_h)) 
	a.xFrames = (_rw/_w)
	a.yFrames = (_rh/_h)
	a.frameWidth = _w
	a.frameHeight = _h
	a.delay = _d or 0
	a.mode = _m or "loop"
	a.switch = 0
	a.mark = 0
	a.rest = 0
	a.dir = 1
	a.play = true
	a.start = function (self)
		self.play = true
	end
	a.stop = function (self)
		self.play = false
	end
	--[[ This function handles both updating and drawing. ]]
	a.draw = function (self,...)
		if self.rest == 0 then
			if self.mode == "loop" then
				self.mark = ((self.mark + self.dir)%self.frames)
			elseif self.mode == "flip" then
				if self.switch == 0 then
					self.mark = self.mark + 1
					if self.mark == self.frames then self.switch = 1 end
				elseif self.switch == 1 then
					self.mark = self.mark - 1
					if self.mark == 1 then self.switch = 0 end
				end
			elseif self.mode == "play" then
				self.mark = math.clamp(1, self.mark + self.dir, self.frames)
			end
			self.rest = self.delay
			self.quad:setViewport(((self.mark%self.xFrames))*self.frameWidth,
									math.floor(self.mark/self.xFrames)*self.frameHeight,
									self.frameWidth, self.frameHeight)
		else
			print(self.rest)
			self.rest = self.rest - 1
		end
		love.graphics.draw(self.image,self.quad,select(1,...),select(2,...),select(3,...),
												select(4,...),select(5,...),select(6,...),
												select(7,...),select(8,...),select(9,...))
	end

	return a
end

love.graphics.newAnimation = orea.newAnimation