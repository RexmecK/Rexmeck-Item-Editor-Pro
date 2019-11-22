require("/itemeditork/json.lua")
require("/itemeditork/color.lua")


--theme

_buttons = {
	no = "/itemeditork/unsaved/no.png",
	yes = "/itemeditork/unsaved/yes.png",
	close = "/itemeditork/unsaved/x.png",
}

_images = {
	bg1 = "/itemeditork/unsaved/header.png"
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
confirmed = false

function init()
	pcall(setUIColor, status.statusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config:defaultColor", "72e372")))
	shiftingEnabled = status.statusProperty("rex_ui_rainbow", false)
	unsaveditem = config.getParameter("scriptConfig").item
	lastslot = config.getParameter("scriptConfig").slot
	
	local name = unsaveditem.name
	
	if unsaveditem.parameters and unsaveditem.parameters.shortdescription then
		local name = ucon(tostring(unsaveditem.parameters.shortdescription))
	end
	
	widget.setText("h1", "Discard "..name.."?")
end

function uninit()
	if not confirmed then
		unconfirmed()
	end
end

function update(dt)
	shiftUI(dt)
end


function no()
	confirmed = true
	local ui = root.assetJson("/itemeditork/edit/pane.json")
	ui.scriptConfig = {}
	ui.scriptConfig.item = unsaveditem
	ui.scriptConfig.slot = ""
	ui.scriptConfig.hasChanges = true
	ui.scriptConfig.editoruuid = sb.makeUuid()
	player.interact("ScriptPane", ui)
	pane.dismiss()
end

function yes()
	confirmed = true
	pane.dismiss()
end

function unconfirmed()
	local ui = root.assetJson("/itemeditork/unsaved/pane.json")
	ui.scriptConfig = config.getParameter("scriptConfig")
	player.interact("ScriptPane", ui)
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
