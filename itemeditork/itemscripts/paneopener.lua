function init() 
	activeItem.setHoldingItem(false)
end
lastfire = ""
	
function update(dt, fireMode, shiftHeld)
	if fireMode == "primary" and lastfire ~= "primary" then
		local ui = root.assetJson("/itemeditork/scan/pane.json")
		player.interact("ScriptPane", ui)
	end
	lastfire = fireMode
end