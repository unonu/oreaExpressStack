--[[ Orea's supplementary features ]]

require("orea/ansicolors")

if not orea then orea = {} end

modules = {
	"extra",
	"math",
	"res",
	"graphics",
	"goo",
	"animation",
	"filesystem",
	"states",
	"camera",
	"video",
	"mesh",
	"network",
}

for i in ipairs(modules) do
	require("orea/"..modules[i])
end