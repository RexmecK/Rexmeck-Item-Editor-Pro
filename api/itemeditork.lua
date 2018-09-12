--[[
	HOW TO USE THIS API
	
	allows other interface to create a new editor interface with an item attached
	
	
	
	
	pcall(require, "/api/itemeditork.lua")
	if itemeditork then
		itemeditork.open(item)
	end

]]--


itemeditork = {

	_rawOpen = function(item)
		local ui = root.assetJson("/itemeditork/edit/pane.json")
		ui.scriptConfig = {}
		ui.scriptConfig.item = item
		ui.scriptConfig.slot = "right"
		ui.scriptConfig.editoruuid = sb.makeUuid()
		player.interact("ScriptPane", ui)
	end,

	open = function(item)
		if type(item) == "string" then
			local a = root.createItem({name = item, count = 1})
			local b,c = pcall(root.itemConfig, {name = item, count = 1})
			if b and c and c.config then
				a.parameters = c.config
			end
			itemeditork._rawOpen(a)
		elseif type(item) == "table" then
			local tcount = 0
			if item.parameters then
				for i,v in pairs(item.parameters) do
					tcount = tcount + 1
				end
			end
			if tcount == 0 then
				local b,c = pcall(root.itemConfig, item)
				if b and c and c.config then
					item.parameters = c.config
				end
			end
			itemeditork._rawOpen(item)
		end
	end
	
}