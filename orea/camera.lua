if not orea then orea = {} end

---------------------------------
--// Custom camera functions //--
---------------------------------

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

