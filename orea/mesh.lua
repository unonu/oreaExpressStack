if not orea then orea = {} end

----------------------------------
--// Custom 3D mesh functions //--
----------------------------------

--[[ 3d mesh object ]]
function loadMesh(file)
	local vertices = {}
	local textures = {}
	local normals = {}
	local faces = {}
	local max,min = {-99999999,-99999999,-99999999}, {99999999,99999999,99999999}
	--
	local vertices2d = {}
	local cameraRot = {0,0,0} --camera rotation vector. used to calculate the 2d vertices

	for l in love.filesystem.lines(file) do
		line = l:split(' ')
		if line[1] == 'v' then
			vertices[#vertices+1] = table.map({select(2, unpack(line) )},tonumber)
			max[1] = math.max(max[1], vertices[#vertices][1])
			max[2] = math.max(max[2], vertices[#vertices][2])
			max[3] = math.max(max[3], vertices[#vertices][3])
			min[1] = math.min(min[1], vertices[#vertices][1])
			min[2] = math.min(min[2], vertices[#vertices][2])
			min[3] = math.min(min[3], vertices[#vertices][3])
		elseif line[1] == 'vt' then
			textures[#textures+1] = table.map({select(2, unpack(line) )},tonumber)
			textures[#textures][2] = -textures[#textures][2]
		elseif line[1] == 'vn' then
			normals[#normals+1] = table.map({select(2, unpack(line) )},function (a) return -tonumber(a) end)
		elseif line[1] == 'f' then
			faces[#faces+1] = table.map({select(2, unpack(line) )}, string.split, '/')
			faces[#faces].id = {select(2, unpack(line) )}
		end
	end

	local _faces = {}
	for i,f in ipairs(faces) do
		local _f = {}
		_f[1] = {vertices[tonumber(f[1][1])], 			--vertices
				 vertices[tonumber(f[2][1])],
				 vertices[tonumber(f[3][1])]}
		_f[2] = {textures[tonumber(f[1][2])] or {0,0}, 	--texture
				 textures[tonumber(f[2][2])] or {0,0},
				 textures[tonumber(f[3][2])] or {0,0}}
		_f[3] = {normals[tonumber(f[1][3])], 			--normal
				 normals[tonumber(f[2][3])],
				 normals[tonumber(f[3][3])]}
		--[[ initialise the 2d triangle ]]
		for v=1,3 do
			local x,y
			x = _f[1][v][1]
			y = _f[1][v][2]
			vertices2d[(i-1)*3 +v] = { x,
									   -y,
									   _f[2][v][1],
									   _f[2][v][2],
									   0,0,0}
		end
		_faces[i] = _f
	end
	faces = _faces
	return vertices2d, vertices, faces, {min[1],min[2],min[3],max[1],max[2],max[3]}
end

mesh = {}
mesh.__index = mesh
function mesh.make(file, texture)
	local m = {}
	setmetatable(m, mesh)
	local vertices2d, vertices, faces, extrema = loadMesh(file)
	m.vertices2d = vertices2d
	m.vertices3d = vertices3d
	m.faces = faces
	m.extrema = extrema
	m.vertices3d = {}
	for i=1, #m.vertices2d do
		m.vertices3d[i] = {{},{},{}}
	end
	m.texture = nil
	if type(texture) == "string" then
		m.texture = love.graphics.newImage(texture)
		m.texture:setFilter("nearest")
	else
		m.texture = texture
	end
	local t = m.texture and m.texture:setWrap("repeat") or nil
	m.drawable = love.graphics.newMesh(vertices2d, m.texture, "triangles")
	m.scale = (m.extrema[5]-m.extrema[2])/(m.extrema[4]-m.extrema[1])
	return m
end

function mesh:draw(x,y,r,sx,sy,ox,oy,kx,ky)
	love.graphics.draw(self.drawable,x,y,r,sx or 1,(sy or sx or 1),ox,oy or ox,kx,ky or kx)
end

function mesh:update(camera)
	local drawList = {} 	--[[ indecies of faces to be drawn ]]
	local processed = {} 	--[[ vertices already processed ]]
	local newMap = {} 		--[[ the new vertex map ]]
	local zOrder = {} 		--[[ z value of the face with the same index ]]

	--[[ loop through faces ]]
	for i=1, #self.faces do
		local f = self.faces[i]
		--[[ cull backfaces ]]
		-- local dp = -camera.vector[1]*f[3][1][1] + camera.vector[3]*f[3][1][2] - camera.vector[2]*f[3][1][3]
		-- if dp < 0 then
			--[[ loop through vertices ]]
			local id
			for v=1, 3 do
				--[[ figure out which vertex in vertex2d we're working on ]]
				id = (i-1)*3 +(v)

				--[[ check if this was processed ]]
				if not processed[id] then
					processed[id] = true

					--[[ project the 3d to 2d ]]
					self.vertices3d[i][v][1] = f[1][v][1]*camera.rotMatrix[1][1]
											  -f[1][v][2]*camera.rotMatrix[1][2]
											  -f[1][v][3]*camera.rotMatrix[1][3]
					self.vertices3d[i][v][2] = f[1][v][1]*camera.rotMatrix[2][1]
											  -f[1][v][2]*camera.rotMatrix[2][2]
											  -f[1][v][3]*camera.rotMatrix[2][3]
					self.vertices3d[i][v][3] = f[1][v][1]*camera.rotMatrix[3][1]
											  -f[1][v][2]*camera.rotMatrix[3][2]
											  -f[1][v][3]*camera.rotMatrix[3][3]
				end

				--[[ assign the coords, uv and colour to the vertex ]]
				self.drawable:setVertex(id, self.vertices3d[i][v][1], self.vertices3d[i][v][2], f[2][v][1], f[2][v][2], 255, 255, 255)
			end

			--[[ calculate z order ]]
			zOrder[i] = (self.vertices3d[i][1][3]
						 +self.vertices3d[i][2][3]
						 +self.vertices3d[i][3][3])
								  /3
			--[[ add to draw list ]]
			drawList[#drawList+1] = i
		-- end
	end

	--[[ sort by z order ]]
	table.sort(drawList, function (a,b) return zOrder[a] > zOrder[b] end)

	love.graphics.setCanvas(camera.zBuffer)
	love.graphics.push()
	love.graphics.translate(-camera.x, -camera.y)
	local normaliser = -(zOrder[drawList[1]] - zOrder[drawList[#drawList]])/2
	local normaliser = -360
	local zVerts = {{0,0,nil,nil,0,0,0},{0,0,nil,nil,0,0,0},{0,0,nil,nil,0,0,0}}
	local zMesh = love.graphics.newMesh(zVerts, nil, "triangles")
	for i=1, #drawList do
		newMap[#newMap+1] = (drawList[i]-1)*3 +1
		newMap[#newMap+1] = (drawList[i]-1)*3 +2
		newMap[#newMap+1] = (drawList[i]-1)*3 +3
		--[[ Draw to z bufer canvas ]]
		--[[ User this for a rough z buffer ]]
		-- local zColor = ((zOrder[drawList[i]]/normaliser) + 1) * 128
		-- zColor = zColor > 0 and (zColor < 255 and zColor or 255) or 0
		-- love.graphics.setColor(zColor,zColor,zColor)
		-- love.graphics.polygon("fill", self.vertices3d[drawList[i]][1][1],self.vertices3d[drawList[i]][1][2],
		-- 							  self.vertices3d[drawList[i]][2][1],self.vertices3d[drawList[i]][2][2],
		-- 							  self.vertices3d[drawList[i]][3][1],self.vertices3d[drawList[i]][3][2],
		-- 							  self.vertices3d[drawList[i]][1][1],self.vertices3d[drawList[i]][1][2])
		--[[ Use this for a smooth z buffer ]]
		local zColor1 = ((self.vertices3d[drawList[i]][1][3]/normaliser) + 1) * 128
		local zColor2 = ((self.vertices3d[drawList[i]][2][3]/normaliser) + 1) * 128
		local zColor3 = ((self.vertices3d[drawList[i]][3][3]/normaliser) + 1) * 128
		zColor1 = zColor1 > 0 and (zColor1 < 255 and zColor1 or 255) or 0
		zColor2 = zColor2 > 0 and (zColor2 < 255 and zColor2 or 255) or 0
		zColor3 = zColor3 > 0 and (zColor3 < 255 and zColor3 or 255) or 0
		zMesh:setVertex(1,self.vertices3d[drawList[i]][1][1],self.vertices3d[drawList[i]][1][2],nil,nil, zColor1,zColor1,zColor1)
		zMesh:setVertex(2,self.vertices3d[drawList[i]][2][1],self.vertices3d[drawList[i]][2][2],nil,nil, zColor2,zColor2,zColor2)
		zMesh:setVertex(3,self.vertices3d[drawList[i]][3][1],self.vertices3d[drawList[i]][3][2],nil,nil, zColor3,zColor3,zColor3)
		love.graphics.draw(zMesh)
	end
	love.graphics.pop()
	love.graphics.setCanvas()

	newMap = #newMap > 3 and newMap or {1,1,1}

	-- remap vertices
	self.drawable:setVertexMap(newMap)
end