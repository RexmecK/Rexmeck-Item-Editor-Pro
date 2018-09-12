function popupCopy(text)
	local ui = root.assetJson("/itemeditork/copy/pane.json")
	ui.scriptConfig = {}
	ui.scriptConfig.text = text
	player.interact("ScriptPane", ui)
end