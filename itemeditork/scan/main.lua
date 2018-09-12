require("/itemeditork/json.lua")
require("/itemeditork/color.lua")


--theme

_buttons = {
	left = "/itemeditork/scan/left.png",
	right = "/itemeditork/scan/right.png",
	matter = "/itemeditork/scan/matter.png",
	wire = "/itemeditork/scan/wire.png",
	paint = "/itemeditork/scan/paint.png",
	spawnItem = "/itemeditork/scan/scan.png",
	search = "/itemeditork/scan/search.png",
	settings = "/itemeditork/scan/gear.png",
	about = "/itemeditork/scan/about.png",
	close = "/itemeditork/edit/x.png",
}

_images = {
	bg2 = "/itemeditork/scan/bg.png",
	bg1 = "/itemeditork/scan/header.png"
}

_texts = {
	"itemId"
}

themeColor = "72e372"

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

function settings(wid)
	local ui = root.assetJson("/itemeditork/settings/pane.json")
	player.interact("ScriptPane", ui)
end

aboutdescription = [[A Tool that edits items ingame.
 
Testers:
 Discord : Big brother#3552
 Starbound Char : space hobo
 
 Discord : Khodin#1796
 
 Discord : Spectre#0898
 Starbound Char : Ludmina
 SteamID : 76561193845521385
 
 Discord : typical#0654
 Starbound Char : ª
 
Credits:
 Craig Mason-Jones : JSON.lua
 Silverfeelin : Quickbar Mini
 
]]

function about(wid)
	--local ui = root.assetJson("/itemeditork/about/pane.json")
	--player.interact("ScriptPane", ui)
	
	
	
	local ui = root.assetJson("/itemeditork/editjson/pane.json")
	ui.scriptConfig = {}
	ui.scriptConfig.saveraw = false
	ui.scriptConfig.nameparam = ""
	ui.scriptConfig.text = "RexmecK Item Editor Pro "..root.assetJson("/itemeditork/info.config", {version = "Unknown Version"})["version"].."\n \n"..aboutdescription
	ui.scriptConfig.editoruuid = ""
	ui.gui.save.disabled = true
	player.interact("ScriptPane", ui)
end

function scan(wid)
	if wid == "left" then
		processItem(player.primaryHandItem(), wid)
	elseif wid == "right" then
		processItem(player.altHandItem(), wid)
	elseif wid == "matter" then
		processItem(player.essentialItem("beamaxe"), wid)
	elseif wid == "wire" then
		processItem(player.essentialItem("wiretool"), wid)
	elseif wid == "paint" then
		processItem(player.essentialItem("painttool"), wid)
	elseif wid == "search" then
		processItem(player.essentialItem("inspectiontool"), wid)
	elseif wid == "spawnItem" then
		Input(widget.getText("itemId"))
		widget.setText("itemId","")
	end
end

function Input(str)
	if str == "" then
		return
	end
	
	local startwith = string.sub(str, 1,1)
	
	if str == "empty" then
		processItem({name = "perfectlygenericitem", count = 1}, "right")
	elseif startwith == "/" then
		local args = string.gsub(str, "/spawnitem ", "")..""
		local arg12 = string.gsub(args, " '{.+", "")..""
		local args1 = string.gsub(arg12, " .+", "")..""
		local args2 = tonumber(string.gsub(arg12, args1, "").."")
		local args3 = ""
		for i,v in string.gmatch(str, " '{.+") do
			args3 = string.sub(i, 3,i:len() - 1)
			break
		end
		
		if not args1 then
			return
		end
		if args3 ~= "" then
			local s, e = pcall(json.decode, args3)
			if s then
				processItem({name = args1,count = args2 or 1, parameters = e}, "right")
			end
		else
			local a = root.createItem({name = args1,count = args2 or 1})
			local b,c = pcall(root.itemConfig, {name = args1,count = args2 or 1})
			if b and c and c.config then
				a.parameters = c.config
			end
			processItem(a, "right")
		end
	elseif startwith == "{" then
		local s, e = pcall(json.decode, str)
		if s then
			processItem(e, "right")
		end
	elseif pcall(root.assetJson, "/_customitems/"..str) then
		processItem(root.assetJson("/_customitems/"..str), "right")
	else
		local a = root.createItem({name = str, count = 1})
		local b,c = pcall(root.itemConfig, {name = str, count = 1})
		if b and c and c.config then
			a.parameters = c.config
		end
		processItem(a, "right")
	end
end

function processItem(item, spawntype)
	if item and item.name then
		local ui = root.assetJson("/itemeditork/edit/pane.json")
		ui.scriptConfig = {}
		ui.scriptConfig.item = item
		ui.scriptConfig.spawnType = spawntype
		ui.scriptConfig.editoruuid = sb.makeUuid()
		player.interact("ScriptPane", ui)
	end
end

function init()
	pcall(setUIColor, status.statusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config:defaultColor", "72e372")))
	shiftingEnabled = status.statusProperty("rex_ui_rainbow", false)
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
