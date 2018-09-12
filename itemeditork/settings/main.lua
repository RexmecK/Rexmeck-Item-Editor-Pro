function call(wid)
	if wid and _ENV["widget_"..wid] then
		_ENV["widget_"..wid]()
	end
end

function widget_savecolor()
	status.setStatusProperty("rex_ui_color", widget.getText("valuecolor"))
end

function widget_checkrainbow()
	status.setStatusProperty("rex_ui_rainbow", widget.getChecked("checkrainbow"))
end

function init()
	widget.setText("valuecolor",status.statusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config:defaultColor", "72e372")))
	widget.setChecked("checkrainbow", status.statusProperty("rex_ui_rainbow", false))
end

function uninit()

end

function update(dt)

end
