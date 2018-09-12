require("/itemeditork/json.lua")
require("/itemeditork/color.lua")


--theme

_buttons = {
	inventory = "/itemeditork/save/button.png",
	inventoryreplace = "/itemeditork/save/button.png",
	matter = "/itemeditork/save/matter.png",
	wire = "/itemeditork/save/wire.png",
	paint = "/itemeditork/save/paint.png",
	search = "/itemeditork/save/search.png",
	close = "/itemeditork/save/x.png",
}

_images = {
	bg1 = "/itemeditork/save/header.png"
}

_texts = {
}

themeColor = "72e372"

function ucon(str)
	local esc = ""
	for i = 1, string.len(str) do
		esc = esc..utf8.char(string.byte(string.sub(str,i,i)))
	end
	return esc
end

function setUIColor(dr)

	if dr == "" then
		dr = root.assetJson("/itemeditork/info.config:defaultColor", "72e372")
	end
	
	for i,v in pairs(_buttons) do
		widget.setButtonImages(i, {base = v.."?replace;ff3c3c="..dr, hover = v.."?replace;ff3c3c="..dr.."?brightness=60", pressed = v.."?replace;ff3c3c="..dr.."?brightness=60"})
		widget.setFontColor(i,"#"..dr)
	end
	
	for i,v in pairs(_images) do
		widget.setImage(i, v.."?replace;ff3c3c="..dr)
	end
	
	for i,v in pairs(_texts) do
		widget.setFontColor(v, "#"..dr)
	end
	
	themeColor = dr

end




--

function give(wid)
	local s, e = pcall( function()
		
		if wid == "inventoryreplace" then
			if lastslot == "right" or lastslot == "left" then
				local toreplace = config.getParameter("scriptConfig").originalItem
				
				if player.hasItem(toreplace, true) then
					player.consumeItem(toreplace, false, true)
				end
				
				player.giveItem(togive)
				
				world.sendEntityMessage(player.id(),"editor_rawSave", config.getParameter("scriptConfig").editoruuid, togive, lastslot)
			elseif lastslot == "matter" then
				player.giveEssentialItem("beamaxe",togive)	
			elseif lastslot == "wire" then
				player.giveEssentialItem("wiretool",togive)
			elseif lastslot == "paint" then
				player.giveEssentialItem("painttool",togive)
			elseif lastslot == "search" then
				player.giveEssentialItem("inspectiontool",togive)
			end
		elseif wid == "inventory" then
			player.giveItem(togive)
			world.sendEntityMessage(player.id(),"editor_rawSave", config.getParameter("scriptConfig").editoruuid, togive, "right")
		elseif wid == "matter" then
			player.giveEssentialItem("beamaxe",togive)
			world.sendEntityMessage(player.id(),"editor_rawSave", config.getParameter("scriptConfig").editoruuid, togive, "matter")
		elseif wid == "wire" then
			player.giveEssentialItem("wiretool",togive)
			world.sendEntityMessage(player.id(),"editor_rawSave", config.getParameter("scriptConfig").editoruuid, togive, "wire")
		elseif wid == "paint" then
			player.giveEssentialItem("painttool",togive)
			world.sendEntityMessage(player.id(),"editor_rawSave", config.getParameter("scriptConfig").editoruuid, togive, "paint")
		elseif wid == "search" then
			player.giveEssentialItem("inspectiontool",togive)
			world.sendEntityMessage(player.id(),"editor_rawSave", config.getParameter("scriptConfig").editoruuid, togive, "search")
		end
		
		pane.dismiss()
		
		end

 )
	
	if not s then
		widget.setText("h1","Error Saving!")
		sb.logError(e)
	end
end

function init()
	pcall(setUIColor, status.statusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config:defaultColor", "72e372")))
	shiftingEnabled = status.statusProperty("rex_ui_rainbow", false)
	togive = config.getParameter("scriptConfig").item
	lastslot = config.getParameter("scriptConfig").slot
	
	local name = togive.name
	
	if togive.parameters and togive.parameters.shortdescription then
		local name = ucon(tostring(togive.parameters.shortdescription))
	end
	
	widget.setText("h1","Saving: "..name)
end

function uninit()

end

function update(dt)
	shiftUI(dt)
end


function split(inputstr, sep) 
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
    return t
end
