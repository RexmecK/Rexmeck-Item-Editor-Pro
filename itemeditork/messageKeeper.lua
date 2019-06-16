_MKSave = {}
_MKRawSave = {}

function deepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function init()
	if not status.statusProperty("rex_ui_color") then
		status.setStatusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config")["defaultColor"])
	end
	require("/itemeditork/json.lua")
	require("/itemeditork/popupCopy.lua")
	require("/itemeditork/color.lua")
	
	message.setHandler("editor_save", 
		function(_, loc, id, paramname, obj)
			if loc then
				if not _MKSave[id] then
					_MKSave[id] = {}
				end
				table.insert(_MKSave[id], {paramname = paramname, obj = obj})
			end
		end
	)
	message.setHandler("editor_pull", 
		function(_, loc, id)
			if loc then
				if _MKSave[id] then
					local copy = deepCopy(_MKSave[id])
					_MKSave[id] = {}
					return copy
				else
					return {}
				end
			end
		end
	)
	message.setHandler("editor_rawPull", 
		function(_, loc, id)
			if loc then
				if _MKRawSave[id] then
					local copy = deepCopy(_MKRawSave[id])
					_MKRawSave[id] = nil
					return copy
				else
					return nil
				end
			end
		end
	)
	message.setHandler("editor_rawSave", 
		function(_, loc, id, item, slot)
			if loc then
				_MKRawSave[id] = {item = item, slot = slot}
			end
		end
	)
end