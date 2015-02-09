if not orea then orea = {} end

function orea.buildRes()
	print(ansicolors.yellow.."Initialisng Resources:"..ansicolors.clear)
	love.graphics.setDefaultFilter("linear","nearest")
	local files = {}
	orea.recursiveEnumerate("res/", files)
	local res = {}
	local perc, _perc = 0, 0
	for i,f in ipairs(files) do
		local pwd = f:split("/")
		table.remove(pwd,1)
		if pwd[#pwd]:find('%.') then
			if not res[pwd[1]] then res[pwd[1]] = {} end
			res[pwd[1]][f:sub(select(2,f:find(pwd[1]))+2,f:find('%.')-1)] = {path = f, data = nil; users = 0}
		end
		perc = math.floor((i/#files)*100)
		if perc > _perc then _perc = perc; io.write("...".._perc) end
	end
	print("% - Done")

	res.__index = res
	res.allowDuplicates = false
	function res:load(typ, name, ...)
		print("loading "..typ..' '..name)
		local args = {...}
		if typ == "image" then
			local asset = self.images[name]
			if self.allowDuplicates and asset.data then
				asset["data"..asset.users] = love.graphics.newImage(asset.path)
				return asset["data"..asset.users]
			end
			if asset.data == nil then
				asset.data = love.graphics.newImage(asset.path)
			end
			asset.users = asset.users + 1
			return asset.data
		elseif typ == "sprite" then
			local asset = self.sprites[name]
			if self.allowDuplicates and asset.data then
				asset["data"..asset.users] = newAnimation(asset.path,select(1,...),select(2,...),select(3,...),
											select(4,...),select(5,...),select(6,...),select(7,...))
				return asset["data"..asset.users]
			end
			if asset.data == nil then
				asset.data = newAnimation(asset.path,select(1,...),select(2,...),select(3,...),
											select(4,...),select(5,...),select(6,...),select(7,...))
			end
			asset.users = asset.users + 1
			return asset.data
		elseif typ == "sound" then
			local asset = self.sounds[name]
			if self.allowDuplicates and asset.data then
				asset["data"..asset.users] = love.audio.newSource(asset.path, "static")
				return asset["data"..asset.users]
			end
			if asset.data == nil then
				asset.data = love.audio.newSource(asset.path, "static")
			end
			asset.users = asset.users + 1
			return asset.data
		elseif typ == "music" then
			local asset = self.sounds[name]
			if self.allowDuplicates and asset.data then
				asset["data"..asset.users] = love.audio.newSource(asset.path, "stream")
				return asset["data"..asset.users]
			end
			if asset.data == nil then
				asset.data = love.audio.newSource(asset.path, "stream")
			end
			asset.users = asset.users + 1
			return asset.data
		elseif typ == "quadsheet" then
                    local asset = self.quads[name]
                    if asset.data == nil then
                            asset.data = {}
                            local file = love.filesystem.read(asset.path)
                            file = file:split('\n')
                            asset.image = res:load("image",file[1])
                            for i=2,#file do
                                    if #file[i] > 0 then
                                            local quad = file[i]:split(',')
                                            asset.data[quad[1]] = love.graphics.newQuad(quad[2],quad[3],quad[4],quad[5],
                                                    asset.image:getWidth(),asset.image:getHeight())
                                            asset.data[i-1] = {quad[1],asset.data[quad[1]],asset.image}
                                    end
                            end
                    end
                    asset.users = asset.users + 1
                    return asset

		end
	end

	function res:unload(typ, name)
		if typ == "image" then
			local asset = self.images[name]
			asset.users = math.max(0,asset.users - 1)
			if asset.users == 0 then asset.data = nil end
		elseif typ == "sprite" then
			local asset = self.sprites[name]
			asset.users = math.max(0,asset.users - 1)
			if asset.users == 0 then asset.data = nil end
		elseif typ == "sound" then
			local asset = self.sounds[name]
			asset.users = math.max(0,asset.users - 1)
			if asset.users == 0 then asset.data = nil end
		elseif typ == "music" then
			local asset = self.sounds[name]
			asset.users = math.max(0,asset.users - 1)
			if asset.users == 0 then asset.data = nil end
		end
	end

	return res
end