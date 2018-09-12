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

require("/itemeditork/json.lua")
require("/itemeditork/color.lua")
require("/itemeditork/popupCopy.lua")

function ucon(str)
	local esc = ""
	for i = 1, string.len(str) do
		esc = esc..utf8.char(string.byte(string.sub(str,i,i)))
	end
	return esc
end

function tcount(t)
local int = 0
for i,v in pairs(t) do
	int = int + 1
end
return int
end

function tcopy(t)
local newt = {}
for i,v in pairs(t) do
	newt[i] = v
end
return newt
end

function getTT(t)
	if #t ~= tcount(t) then
		return "object"
	else
		return "array"
	end
end


me = {
	_item = nil, --backup item
	item = nil, --editingitem
	uuid = "aaaa"
}

objlist = {
	
}

function removeListItem(str)
	for i,v in pairs(objlist) do
		if v.name == str then
			widget.removeListItem("objects.list", i - 1)
			local lastint = i + 0
			
			table.remove(objlist, i)
			
			if objlist[lastint] then
				widget.setListSelected("objects.list", objlist[lastint].name)
			end
		end
	end
end

function getListItem(str)
	for i,v in pairs(objlist) do
		if v.name == str then
			return v
		end
	end
end


--button hybrid callback

function widget_remparam()
	local sel = widget.getListSelected("objects.list")
	if sel then
		removeListItem(sel)
	end
end

function widget_addparam()
	local ui = root.assetJson("/itemeditork/editjson/pane.json")
	ui.scriptConfig = {}
	ui.scriptConfig.nameparam = ""
	ui.scriptConfig.text = ""
	ui.scriptConfig.editoruuid = me.uuid
	player.interact("ScriptPane", ui)
end

function widget_printparam()
	local sel = widget.getListSelected("objects.list")
	if sel then
		local curitem = getListItem(sel)
		local textt, e = pcall(sb.printJson, curitem.parameters, 0) --Sometimes it has issues parsing UTF-8 codes
		if textt then
			sb.logInfo(e)
			--popupCopy(ucon(e))
		else
			local textt2, e2 = pcall(json.encode, curitem.parameters, 0) --raw parse
			sb.logInfo(ucon(e2)) --"//Raw Parse due to error\n"..ucon(e2))
			--popupCopy(ucon(e2))
		end
	end
end

function widget_editparam()
	local sel = widget.getListSelected("objects.list")
	if sel then
		local ui = root.assetJson("/itemeditork/editjson/pane.json")
		local curitem = getListItem(sel)
		local textt, e = pcall(sb.printJson, curitem.parameters, 1) --Sometimes it has issues parsing UTF-8 codes
		if textt then
			ui.scriptConfig = {}
			ui.scriptConfig.saveraw = false
			ui.scriptConfig.nameparam = curitem.objname
			ui.scriptConfig.text = e
			ui.scriptConfig.editoruuid = me.uuid
			player.interact("ScriptPane", ui)
		else
			local textt2, e2 = pcall(json.encode, curitem.parameters, 1) --raw parse
			ui.scriptConfig = {}
			ui.scriptConfig.saveraw = false
			ui.scriptConfig.nameparam = curitem.objname
			ui.scriptConfig.text = ucon(e2)--"//Raw Parse due to error\n"..ucon(e2)
			ui.scriptConfig.editoruuid = me.uuid
			player.interact("ScriptPane", ui)
		end
	end
end

function widget_rawjson()
	local ui = root.assetJson("/itemeditork/editjson/pane.json")
	local item = packItem()
	local textt, e = pcall(sb.printJson, item, 1) --Sometimes it has issues parsing UTF-8 codes
	if textt then
		ui.scriptConfig = {}
		ui.scriptConfig.saveraw = true
		ui.scriptConfig.text = e
		ui.scriptConfig.editoruuid = me.uuid
		player.interact("ScriptPane", ui)
	else
		local textt2, e2 = pcall(json.encode, item, 1) --raw parse
		if textt2 then
			ui.scriptConfig = {}
			ui.scriptConfig.saveraw = true
			ui.scriptConfig.text = ucon(e2)--"//Raw Parse due to error\n"..ucon(e2)
			ui.scriptConfig.editoruuid = me.uuid
			player.interact("ScriptPane", ui)
		end
	end
end

function widget_jsonlog()
	local reps = packItem()
	if reps then
		local text1, a = pcall(sb.printJson, reps)
		if text1 then
			sb.logInfo(a)
			--popupCopy(ucon(a))
		else
			local text2, a2 = pcall(json.encode, reps)
			sb.logInfo(ucon(a2))
			--popupCopy(ucon(a2))
		end
	end
end

function call(wid)
	if wid and _ENV["widget_"..wid] then
		_ENV["widget_"..wid]()
	end
end

function widget_save()
	local saved = packItem()
	if saved then
		local ui = root.assetJson("/itemeditork/save/pane.json")
		ui.scriptConfig = {item = saved, originalItem = me._item, editoruuid = me.uuid}
		player.interact("ScriptPane", ui)
	end
end

function widget_addcount()
	if widget.getText("count") == "" then
		widget.setText("count", "0")
	end
	widget.setText("count",tostring(math.min(tonumber(widget.getText("count")) + 1, 9999)))
end

function widget_remcount()
	if widget.getText("count") == "" then
		widget.setText("count", "2")
	end
	widget.setText("count",tostring(math.max(tonumber(widget.getText("count")) - 1, 1)))
end

--

_buttons = {
	rawjson = "/itemeditork/edit/button.png",
	printparam = "/itemeditork/edit/page.png",
	remparam = "/itemeditork/edit/neg.png",
	addparam = "/itemeditork/edit/posi.png",
	editparam = "/itemeditork/edit/pencil.png",
	addcount = "/itemeditork/edit/posi.png",
	remcount = "/itemeditork/edit/neg.png",
	delete = "/itemeditork/edit/delete.png",
	save = "/itemeditork/edit/button.png",
	jsonlog = "/itemeditork/edit/button.png",
	close = "/itemeditork/edit/x.png",
}

_images = {
	bg2 = "/itemeditork/edit/bg.png",
	headerover = "/itemeditork/edit/header.png"
}

_texts = {
	"itemname",
	"itemdesc",
	"itemID",
	"count",
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
	
	for i,v in pairs(objlist) do
		widget.setFontColor("objects.list."..v.name..".name", "#"..dr)
		
		
		if v.type == "number" then
			widget.setImage("objects.list."..v.name..".icon", "/itemeditork/type/int.png?replace;ff3c3c="..dr)
		elseif v.type == "string" then
			widget.setImage("objects.list."..v.name..".icon", "/itemeditork/type/string.png?replace;ff3c3c="..dr)
		elseif v.type == "boolean" then
			widget.setImage("objects.list."..v.name..".icon", "/itemeditork/type/boolean.png?replace;ff3c3c="..dr)
		elseif v.type == "object" then
			widget.setImage("objects.list."..v.name..".icon", "/itemeditork/type/obj.png?replace;ff3c3c="..dr)
		elseif v.type == "array" then
			widget.setImage("objects.list."..v.name..".icon", "/itemeditork/type/array.png?replace;ff3c3c="..dr)
		end
		
	end
	
	themeColor = dr

end

--edit parameters

function roaItem(n, o) --replace or add
	for i,v in ipairs(objlist) do
		if v.objname == n then
			objlist[i].parameters = o
			if v.objname == "shortdescription" then
				widget.setText("itemname", tostring(o))
			end
			if v.objname == "description" then
				widget.setText("itemdesc", tostring(o))
			end
			return
		end
	end
	addItem(n, o)
end

function addItem(a, b)
	local newobj = widget.addListItem("objects.list")
	widget.setText("objects.list."..newobj..".name", a)
	widget.setFontColor("objects.list."..newobj..".name", "#"..themeColor)
	local typeT = type(b)
	if a == "shortdescription" then
		widget.setText("itemname", tostring(b))
	end
	if a == "description" then
		widget.setText("itemdesc", tostring(b))
	end
	
	if typeT == "number" then
		widget.setImage("objects.list."..newobj..".icon", "/itemeditork/type/int.png?replace;ff3c3c="..themeColor)
	elseif typeT == "string" then
		widget.setImage("objects.list."..newobj..".icon", "/itemeditork/type/string.png?replace;ff3c3c="..themeColor)
	elseif typeT == "boolean" then
		widget.setImage("objects.list."..newobj..".icon", "/itemeditork/type/boolean.png?replace;ff3c3c="..themeColor)
	elseif typeT == "table" and getTT(b) == "object" then
		widget.setImage("objects.list."..newobj..".icon", "/itemeditork/type/obj.png?replace;ff3c3c="..themeColor)
		typeT = "object"
	elseif typeT == "table" and getTT(b) == "array" then
		widget.setImage("objects.list."..newobj..".icon", "/itemeditork/type/array.png?replace;ff3c3c="..themeColor)
		typeT = "array"
	end
	
	table.insert(objlist, {name = newobj, parameters = b, objname = a, type = typeT})
end

function packItem()
	if me.item then
		local aaa = tcopy(objlist)
		local newitem = {name = widget.getText("itemID"), count = tonumber(widget.getText("count")), parameters = {}}
		for i,v in ipairs(aaa) do
			newitem.parameters[v.objname] = v.parameters
		end
		return newitem
	end
end

function processItem(item)
	widget.clearListItems("objects.list")
	widget.setText("itemID", "")
	widget.setText("itemname", "^#1a1a1a;shortdescription")
	widget.setText("itemdesc", "^#1a1a1a;description")
	objlist = {}

	me._item = item
	me.item = item
	if not item.parameters then item.parameters = {} end
	
	for i,v in pairs(item.parameters) do
		addItem(i, v)
	end
	
	if item.parameters then
		if item.parameters.shortdescription then 
			widget.setText("itemname", tostring(item.parameters.shortdescription))
		end
		
		if item.parameters.description then 
			widget.setText("itemdesc", tostring(item.parameters.description))
		end
	end
	
	widget.setText("itemID", item.name)
	widget.setText("count", item.count or "1")
end

--

function init()
	widget.clearListItems("objects.list")
	pcall(setUIColor, status.statusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config:defaultColor", "72e372")))
	shiftingEnabled = status.statusProperty("rex_ui_rainbow", false)
	me._item = config.getParameter("scriptConfig").item
	local reloadsurvival = widget.getData("close")
	if reloadsurvival then
		me._item = reloadsurvival.item
	end
	if me._item then
		me.item = me._item
		local item = me._item
		if not me._item.parameters then me._item.parameters = {} end
		
		for i,v in pairs(item.parameters) do
			addItem(i, v)
		end
		
		local sd = ""
		if item.parameters then
			if me._item.parameters.shortdescription then 
				widget.setText("itemname", tostring(me._item.parameters.shortdescription))
			end
			
			if me._item.parameters.description then 
				widget.setText("itemdesc", tostring(me._item.parameters.description))
			end
		end
		
		widget.setText("itemID", me._item.name)
		widget.setText("count", me._item.count or "1")
	else
		pane.dismiss()
	end
	
	if reloadsurvival then
		me._item = reloadsurvival.originalItem
	end
	
	me.uuid = config.getParameter("scriptConfig").editoruuid 
	
	widget.setText("h1", "Rexmeck Item Editor Pro - "..string.sub(me.uuid, 1,8))
end

function uninit()
	widget.setData("close", {item = packItem(), originalItem = me._item})
end

function update(dt)
	if _userdata_pull and _userdata_pull:finished() then
		if _userdata_pull:result() ~= nil then
			for i,v in pairs(_userdata_pull:result()) do
				roaItem(v.paramname, v.obj)
			end
		end
		_usercool = 2
		_userdata_pull = nil
	elseif not _userdata_pull then
		if _usercool <= 0 then
			_userdata_pull = world.sendEntityMessage(player.id(), "editor_pull", me.uuid)
		else
			_usercool = math.max(_usercool - 1, 0)
		end
	end
	
	if _userdata2_pull and _userdata2_pull:finished() then
		if _userdata2_pull:result() ~= nil then
			processItem(_userdata2_pull:result())
		end
		_usercool2 = 2
		_userdata2_pull = nil
	elseif not _userdata2_pull then
		if _usercool2 <= 0 then
			_userdata2_pull = world.sendEntityMessage(player.id(), "editor_rawPull", me.uuid)
		else
			_usercool2 = math.max(_usercool2 - 1, 0)
		end
	end
	
	shiftUI(dt)
end

--handler event
_usercool = 0
_userdata_pull = nil

_usercool2 = 0
_userdata2_pull = nil