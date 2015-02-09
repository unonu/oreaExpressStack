if not orea then orea = {} end

-------------------------------
--// Custom vide functions //--
-------------------------------

--[[ Rhudementary video playback (no audio, no auto size, no framerate detection) ]]
video = {}
video.__index = video

function video.make(file,width,height,vWidth,vHeight)
	local v = {}
	setmetatable(v, video)

	v.path = file
	v.width = width
	v.height = height
	v.vWidth = vWidth or width
	v.vHeight = vHeight or height
	v.vScale = {v.width/v.vWidth, v.height/v.vHeight}
	v.frameLength = (v.vWidth)*(v.vHeight)
	v.stream = io.popen('ffmpeg -loglevel fatal -i '..file..' -f image2pipe'..
		' -pix_fmt rgb24 -vcodec rawvideo -')
	v.stream:setvbuf("full",v.frameLength)
	v.raw = nil
	v.data = love.image.newImageData(v.vWidth, v.vHeight)
	v.frame = love.graphics.newImage(v.data)
	v:setFrame()
	v.framerate = 1/30

	v.dt = 0

	v.location = 1
	--[[ states: 1-play, 2-pause, 0-stop ]]
	v.state = 1

	return v
end

function video:setFrame()
	self.raw = self.stream:read(self.frameLength*3)
	if not self.raw then return end
	self.data:setData(self.raw)
	self.frame:refresh()

	self.stream:flush()
	if not self.stream:read(0) then
		self.stream:close()
		self.state = 0
	end
	io.write('')
end

function video:draw(x,y,r,sx,sy,...)
	love.graphics.draw(self.frame,x,y,r,self.vScale[1]+(sx or 0),self.vScale[2]+(sy or 0),...)
end

function video:update(dt)
	self.dt = self.dt + dt
	if self.dt > self.framerate and self.state == 1 then
		self:setFrame()
		self.location = self.location + 1
		self.dt = 0
	end
end

--[[ Set the framerate to 'f' frames per second. ]]
function video:setFramerate(f)
	self.framerate = 1/f
end

function video:release()
	self.state = self.state ~= 0 and self.stream:close() or 0
	io.write('')
end