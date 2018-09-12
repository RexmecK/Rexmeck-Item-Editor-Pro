require("/itemeditork/json.lua")

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
	ok = "/itemeditork/copy/button.png",
	close = "/itemeditork/copy/x.png",
}

_images = {
	bg2 = "/itemeditork/copy/bg.png",
	bg1 = "/itemeditork/copy/header.png"
}

_texts = {
	"text"
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

function call(wid)
	if _ENV["widget_"..wid] then
		_ENV["widget_"..wid]()
	end
end

--

function init()
	pcall(setUIColor, status.statusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config:defaultColor", "72e372")))
	shiftingEnabled = status.statusProperty("rex_ui_rainbow", false)
	widget.setText("text", config.getParameter("scriptConfig").text or "")
end

function uninit()

end

function update(dt)

end

