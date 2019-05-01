require("/itemeditork/json.lua")
require("/itemeditork/color.lua")

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

--theme

_buttons = {
	save = "/itemeditork/saveparam/button.png",
	close = "/itemeditork/saveparam/x.png",
}

_images = {
	bg2 = "/itemeditork/saveparam/bg.png",
	bg1 = "/itemeditork/saveparam/header.png"
}

_texts = {
	"name",
	"error"
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

function widget_save()
	if ejson ~= nil and widget.getText("name") ~= "" then
		world.sendEntityMessage(player.id(),"editor_save", config.getParameter("scriptConfig").editoruuid, widget.getText("name"), ejson)
		pane.dismiss()
	end
end

function widget_name()
	widget_save()
end

function call(wid)
	if _ENV["widget_"..wid] then
		_ENV["widget_"..wid]()
	end
end

--
ejson = nil

function convertToUTF8(str)
	local esc = ""
	for i = 1, string.len(str) do
		esc = esc..utf8.char(string.byte(string.sub(str,i,i)))
	end
	return esc
end

function init()
	pcall(setUIColor, status.statusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config:defaultColor", "72e372")))
	shiftingEnabled = status.statusProperty("rex_ui_rainbow", false)
	etext = config.getParameter("scriptConfig").etext
	
	local s, resu = pcall(json.decode, etext)
	if not s then
		widget.setVisible("name", false)
		widget.setVisible("save", false)
		widget.setVisible("bg2", false)
		widget.setVisible("error", true)
		widget.setText("h1", "Error!")
		widget.setText("error", convertToUTF8(string.gsub(resu, "%[.+: ", "", 1)))
		sb.logInfo(string.gsub(resu, "%[.+: ", "", 1))
	else
		ejson = resu
		widget.setText("name", config.getParameter("scriptConfig").nameparam)
		widget.setText("h1", "Save parameter for "..string.sub(config.getParameter("scriptConfig").editoruuid, 1,8))
	end

	widget.focus("name")
end

function uninit()

end

function update(dt)
	shiftUI(dt)
end

