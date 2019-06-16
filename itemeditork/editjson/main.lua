require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/rect.lua"
require "/itemeditork/editjson/englishUS.lua"
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

--input events

function KIL(key)
	if not keycode[key] then
		sb.logWarn("Key %s does not exist in keymap!", key)
		return
	end
	return string.len(keycode[key]) == 1
end

mouse = {
	
}

scrolling = false

guisize = {
	x = 261,
	y = 159
}

guisize = {
	x = 333 - 3,
	y = 221 - 17
}

renderLines = 26
renderLineTexts = 60

function canvasClickEvent(position, button, isButtonDown)
	if rect.contains({guisize.x - 12, 0, guisize.x, guisize.y}, textbox:mousePosition()) then
		scrolling = isButtonDown
		if isButtonDown then
			return
		end
	elseif scrolling then
		scrolling = isButtonDown
	end
	
	if not widget.hasFocus("textbox") or not rect.contains({0, 0, guisize.x, guisize.y}, textbox:mousePosition()) then
		if isButtonDown and button == 0 then
			return
		end
	end

	if repacking then
		return
	end
	
	mouse[button + 1] = {down = isButtonDown, position = position}
	
	if not isButtonDown and button == 0 and not widget.hasFocus("textbox") then
		local dif = vec2.sub({-10, guisize.y + 9}, {-position[1], position[2]})
		
		dif = vec2.mul(dif, {1/5, 1/8})
		dif[1] = math.floor(dif[1])
		dif[2] = math.floor(dif[2])
		
		local vf = vec2.add(tb.view, {0,0})
		tb.view[1] = math.floor(tb.view[1])
		tb.view[2] = math.floor(tb.view[2])
		
		local view = vec2.add(tb.view, dif)
		view[1] = math.max(view[1],1)
		view[2] = math.max(view[2],1)
		
		if #textlist >= view[2] then
			if tb.select then
				tb.select.e = {math.max( math.min(vec2.add(tb.view, dif)[1], #textlist[tb.select.w[2]] + 1) ,1), tb.select.w[2]}
			end
			tb.cursor = view
			moveCursor("check")
		end
	end
	
	if isButtonDown and button == 0 and not (keyboard.lshift or keyboard.rshift) then
		local dif = vec2.sub({-10, guisize.y + 9}, {-position[1], position[2]})
		
		dif = vec2.mul(dif, {1/5, 1/8})
		dif[1] = math.floor(dif[1])
		dif[2] = math.floor(dif[2])
		
		local vf = vec2.add(tb.view, {0,0})
		tb.view[1] = math.floor(tb.view[1])
		tb.view[2] = math.floor(tb.view[2])
		
		local view = vec2.add(tb.view, dif)
		view[1] = math.max(view[1],1)
		view[2] = math.max(view[2],1)
		
		if #textlist >= view[2] then
			tb.cursor = view
			moveCursor("check")
			tb.select = {w = tb.cursor, e = view}
		end
	end
end

keyboard = {
	lshift = false,
	rshift = false,
	backspace = false,
	caps = false
}

function canvasKeyEvent(key, isKeyDown)

	if not widget.hasFocus("textbox") then
		return key
	end
	
	if repacking then
		return
	end
	
	if keycode[key] == "LSHIFT" then
		keyboard.lshift = isKeyDown
		return
	end
	
	if keycode[key] == "RSHIFT" then
		keyboard.rshift = isKeyDown
		return
	end
	
	if keycode[key] == "LCTRL" then
		keyboard.lctrl = isKeyDown
		return
	end
	
	if keycode[key] == "RCTRL" then
		keyboard.rctrl = isKeyDown
		return
	end
	
	if keycode[key] == "CAPSLOCK" and isKeyDown then
		keyboard.caps = not keyboard.caps
		return
	end
	
	if keycode[key] == "a" and isKeyDown and (keyboard.lctrl or keyboard.rctrl) and (keyboard.lshift or keyboard.rshift) then
		moveCursor("last") clearSelect()
		tb.view[1] = math.max(#textlist[tb.cursor[2]] - 48, 1)
		tb.select = {w = {1,tb.cursor[2]}, e = {#textlist[tb.cursor[2]] + 1,tb.cursor[2]}}
		return
	end
	
	if keycode[key] == "a" and isKeyDown and (keyboard.lctrl or keyboard.rctrl) then
		tb.cursor = {#textlist[#textlist] + 1, #textlist}
		clearSelect()
		cursorFocus()
		tb.select = {w = {1,1}, e = {#textlist[#textlist] + 1,#textlist}}
		return
	end
	
	if keycode[key] == "s" and isKeyDown and (keyboard.lctrl or keyboard.rctrl)  then
		widget_save()
		return
	end
	
	if keycode[key] == "m" and isKeyDown and (keyboard.lctrl or keyboard.rctrl)  then
		widget_rejson()
		return
	end
	
	if keycode[key] == "d" and isKeyDown and (keyboard.lctrl or keyboard.rctrl)  then
		local dupe = clipboard_copyno()
		if dupe == "" then
			dupeLine()
		end
		pastestring(dupe)
		return
	end
	
	if keycode[key] == "c" and isKeyDown and (keyboard.lctrl or keyboard.rctrl)  then
		clipboard_copy()
		return
	end
	
	if keycode[key] == "x" and isKeyDown and (keyboard.lctrl or keyboard.rctrl)  then
		clipboard_cut()
		return
	end
	
	if keycode[key] == "v" and isKeyDown and (keyboard.lctrl or keyboard.rctrl)  then
		clipboard_paste()
		return
	end
	
	if keycode[key] == "z" and isKeyDown and (keyboard.lctrl or keyboard.rctrl) and (keyboard.lshift or keyboard.rshift) then
		redo()
		return
	end
	
	if keycode[key] == "z" and isKeyDown and (keyboard.lctrl or keyboard.rctrl) then
		undo()
		return
	end
	
	if keycode[key] == "HOME" and isKeyDown then
		if (keyboard.lctrl or keyboard.rctrl) and (keyboard.lshift or keyboard.rshift) then
			tb.select = {w = tb.cursor, e = {1, 1}}
			tb.cursor = {1, 1}
			cursorFocus()
			return
		elseif (keyboard.lctrl or keyboard.rctrl) then
			tb.cursor = {1, 1}
			clearSelect()
			cursorFocus()
			return
		else
			if keyboard.rshift or keyboard.lshift then
				tb.select = {w = tb.cursor, e = {1, tb.cursor[2]}}
			else
				moveCursor("first") clearSelect()
			end
			tb.view[1] = 1
			return
		end
	end
	
	if keycode[key] == "END" and isKeyDown then
		if (keyboard.lctrl or keyboard.rctrl) and (keyboard.lshift or keyboard.rshift) then
			tb.select = {w = tb.cursor, e = {#textlist[#textlist] + 1, #textlist}}
			tb.cursor = {#textlist[#textlist] + 1, #textlist}
			cursorFocus()
			return
		elseif (keyboard.lctrl or keyboard.rctrl) then
			tb.cursor = {1, #textlist}
			moveCursor("last") 
			clearSelect()
			cursorFocus()
			return
		else
			if keyboard.rshift or keyboard.lshift then
				tb.select = {w = {#textlist[tb.cursor[2]] + 1, tb.cursor[2]}, e = tb.cursor}
			else
				moveCursor("last") clearSelect()
			end
			tb.view[1] = math.max(#textlist[tb.cursor[2]] - renderLines, 1)
			return
		end
	end
	
	if keycode[key] == "PAGEDOWN" and isKeyDown then
		clearSelect()
		for _= 1,(renderLines - 1) do
			moveCursor("down")
		end
		tb.view[2] = math.min(tb.view[2] + (renderLines - 1), math.max(#textlist - (renderLines - 1), 1))
		return
	end
	
	if keycode[key] == "PAGEUP" and isKeyDown then
		clearSelect()
		for _= 1,(renderLines - 1) do
			moveCursor("up")
		end
		tb.view[2] = math.max(tb.view[2] - (renderLines - 1), 0)
		return
	end
	
	if key == 0 then
		keyboard.backspace = isKeyDown
		if isKeyDown then
			repeatDel = 30
		end
	end

	if isKeyDown and getLetter(key, keyboard.rshift or keyboard.lshift, keyboard.caps) then
		removeSelectedLetters()
		addLetter(tb.cursor[2], tb.cursor[1], getLetter(key, keyboard.rshift or keyboard.lshift, keyboard.caps))
		moveCursor("right")  clearSelect()
		cursorFocus()
	elseif isKeyDown and keycode[key] == "SPACE" then
		removeSelectedLetters()
		addLetter(tb.cursor[2], tb.cursor[1], " ")
		moveCursor("right")  clearSelect()
		cursorFocus()
	elseif isKeyDown and keycode[key] == "ENTER" then
		removeSelectedLetters()
		newLine(tb.cursor[2])
		cursorFocus()
	elseif isKeyDown and keycode[key] == "TAB" then
		removeSelectedLetters()
		addLetter(tb.cursor[2], tb.cursor[1], " ")
		moveCursor("right")
		addLetter(tb.cursor[2], tb.cursor[1], " ")
		moveCursor("right")
		addLetter(tb.cursor[2], tb.cursor[1], " ")
		moveCursor("right") clearSelect()
		
		cursorFocus()
	else
		--moving
		if isKeyDown and key == 0 then
			if tb.select and ((tb.select.e[1] ~= tb.select.w[1]) or (tb.select.e[2] ~= tb.select.w[2])) then
				--selectiveRemoveLetters(tb.select.w[2], tb.select.w[1], tb.select.e[1])
				multiline_function(true)
			else
				removeLetter(tb.cursor[2], tb.cursor[1])
				clearSelect()
			end
		end
		
		if isKeyDown and keycode[key] == "LEFT" and (keyboard.rshift or keyboard.lshift) then
			moveCursor("left") 
			tb.select.e = tb.cursor
			cursorFocus()
		elseif isKeyDown and keycode[key] == "LEFT" then
			moveCursor("left") 
			clearSelect()
			cursorFocus()
		end
		
		if isKeyDown and keycode[key] == "RIGHT" and (keyboard.rshift or keyboard.lshift) then
			moveCursor("right") 
			tb.select.e = tb.cursor
			cursorFocus()
		elseif isKeyDown and keycode[key] == "RIGHT" then
			moveCursor("right") 
			clearSelect()
			cursorFocus()
		end
		
		if isKeyDown and keycode[key] == "UP" and (keyboard.rshift or keyboard.lshift) then
			moveCursor("up")
			tb.select.e = tb.cursor
			cursorFocus()
		elseif isKeyDown and keycode[key] == "UP" then
			moveCursor("up")
			moveCursor("check")
			clearSelect() 
			cursorFocus()
		end
		
		if isKeyDown and keycode[key] == "DOWN" and (keyboard.rshift or keyboard.lshift) then
			moveCursor("down") 
			tb.select.e = tb.cursor
			cursorFocus()
		elseif isKeyDown and keycode[key] == "DOWN" then
			moveCursor("down") 
			moveCursor("check")
			clearSelect() 
			cursorFocus()
		end
		
	end
	
end

--button hybrid callback

function widget_paste()
end

function widget_save()
	repacktype = "save"
	repackThread = coroutine.create(repack)
	coroutine.resume(repackThread)
	repacking = true
end

function widget_rejson()
	repacktype = "rejson"
	repackThread = coroutine.create(repack)
	coroutine.resume(repackThread)
	repacking = true
end

function widget_clear()
	tb = {
		view = {0,0},
		cursor = {1,1},
		select = nil, --{w = {1,1}, e = {1,4}}
		panning = nil --{start = {0,0}, cur = {0,0}, original = {}}
	}
	textlist = {
		{}
	}
	timesnap = 5 - 2
end

function call(wid)
	if wid and _ENV["widget_"..wid] then
		_ENV["widget_"..wid]()
	end
end

--text editor

function cursorFocus()
	tb.view = {
		math.min(math.max(tb.view[1], tb.cursor[1] - 47), tb.cursor[1]), 
		math.min(math.max(tb.view[2], tb.cursor[2] - (renderLines - 1)), tb.cursor[2] - 1)
	}
end

function moveCursor(dir)
	if dir == "down" then
		tb.cursor[2] = math.min(tb.cursor[2] + 1, #textlist)
		tb.cursor[1] = math.min(tb.cursor[1], #textlist[tb.cursor[2]] + 1)
	elseif dir == "up" then
		tb.cursor[2] = math.max(tb.cursor[2] - 1, 1)
		tb.cursor[1] = math.min(tb.cursor[1], #textlist[tb.cursor[2]] + 1)
	elseif dir == "right" then
		tb.cursor[1] = math.min(tb.cursor[1] + 1, #textlist[tb.cursor[2]] + 1)
	elseif dir == "left" then
		tb.cursor[1] = math.max(tb.cursor[1] - 1, 1)
	elseif dir == "last" then
		tb.cursor[1] = math.max(#textlist[tb.cursor[2]] + 1,1)
	elseif dir == "first" then
		tb.cursor[1] = 1
		tb.cursor[2] = math.min(tb.cursor[2], #textlist)
	elseif dir == "check" then
		if not textlist[tb.cursor[2]] then
			tb.cursor[2] = math.max(#textlist,1)
		end
		if not textlist[tb.cursor[2]][tb.cursor[1]] then
			tb.cursor[1] = math.max(#textlist[tb.cursor[2]] + 1,1)
		end
	end
end

function removeLetter(line, at)
	if at == 1 and line ~= 1 then 
		timesnap = 5 - 2
		local mergeline1 = textlist[line]
		removeLine(line)
		moveCursor("last")
		for i,v in ipairs(mergeline1) do
			addLetter(tb.cursor[2], tb.cursor[1], v)
			moveCursor("right")
		end
		for i,v in ipairs(mergeline1) do
			moveCursor("left")
		end
	elseif #textlist[line] == 1 then 
		timesnap = 5 - 2
		textlist[line] = jarray()
		tb.cursor[1] = 1
	else
		timesnap = 5 - 2
		if textlist[line][at - 1] then
			moveCursor("left")
			table.remove(textlist[line], at - 1)
		end
	end
	cursorFocus()
end

function addLetter(line, at, char)
	if #textlist[line] == 0 then 
		timesnap = 5 - 2
		textlist[line] = {char}
	elseif #textlist[line] == at - 1 then 
		timesnap = 5 - 2
		table.insert(textlist[line], char)
	else
		timesnap = 5 - 2
		table.insert(textlist[line], math.min(at, #textlist[line]), char)
	end
end

function dupeLine()

	local dupedline = {} 
	for i,v in pairs(textlist[tb.cursor[2]]) do
		table.insert(dupedline, v)
	end
	--newLine(tb.cursor[2])
	table.insert(textlist, tb.cursor[2] + 1, {})
	textlist[tb.cursor[2] + 1] = dupedline
	timesnap = 5 - 2

end

function newLine(line)
	timesnap = 5 - 2
	local a = getSelectiveLetters(line, tb.cursor[1], #textlist[line] + 1)
	table.insert(textlist, line + 1, jarray())
	selectiveRemoveLetters(line, tb.cursor[1], #textlist[line] + 1)
	moveCursor("down")
	clearSelect()
	pastestring(a)
	moveCursor("first")
end

function removeLine(line)
	timesnap = 5 - 2
	table.remove(textlist, line)
	moveCursor("up")
end

function removeSelectedLetters()

	if tb.select and (tb.select.w[2] ~= tb.select.e[2] or tb.select.w[1] ~= tb.select.e[1]) then
		multiline_function(true)
		clearSelect()
		cursorFocus()
	end

end

function getSelectedLetters()
	if tb.select then
		return getSelectiveLetters(tb.select.w[2], tb.select.w[1], tb.select.e[1])
	end
	return ""
end

function selectiveRemoveLetters(line, start, e)
	timesnap = 5 - 2
	local tr = table.remove
	
	local s = start
	local s2 = e
	
	if start > e then
		s = e
		s2 = start
	end
	
	for i = s,s2 - 1 do
		if textlist[line][s] then
			tr(textlist[line], s)
		end
	end
	
	tb.cursor = {s, line}
	
	cursorFocus()
end

function absoluteSelected()
	local selected = {w = {tb.select.w[1],tb.select.w[2]}, e = {tb.select.e[1], tb.select.e[2]}}
	if selected.w[2] > selected.e[2] then
		selected = {w = {tb.select.e[1], tb.select.e[2]}, e = {tb.select.w[1],tb.select.w[2]}}
	elseif selected.w[1] > selected.e[1] and selected.w[2] == selected.e[2] then
		selected = {w = {tb.select.e[1], tb.select.e[2]}, e = {tb.select.w[1],tb.select.w[2]}}
	end
	return selected
end

function tableselectedremove(tab, begin, ed)
	for i = begin, ed do
		table.remove(tab, begin)
	end
	return tab
end

function tablecrop(tab, begin, ed)
	if ed ~= #tab then
		local was = #tab
		for i = ed, was do
			table.remove(tab, ed + 1)
		end
	end

	if begin > 0 then
		for i = 2, begin do
			table.remove(tab, 1)
		end
	end
	return tab
end

function multiline_function(cut)
	local str = ""
	local selected = absoluteSelected()
	local rebegining = {}

	if selected.w[2] ~= selected.e[2] then
		for sy = selected.w[2], selected.e[2] do
			if sy == selected.w[2] then
				str = str..table.concat(tablecrop(copyT(textlist[sy]), selected.w[1], #textlist[sy]), "")
				if cut then
					tableselectedremove(textlist[selected.w[2]], selected.w[1], #textlist[sy])
					rebegining = combineT(rebegining, textlist[selected.w[2]])
				end
			elseif sy == selected.e[2] then
				str = str..table.concat(tablecrop(copyT(textlist[sy]), 0, selected.e[1] - 1), "")
				if cut then
					tableselectedremove(textlist[selected.e[2]], 1, selected.e[1] - 1)
					rebegining = combineT(rebegining, textlist[selected.e[2]])
				end
			else
				str = str..table.concat(copyT(textlist[sy]), "")
				if cut then
					textlist[sy] = {"toremove"}
				end
			end 
		end
	else
		str = str..table.concat(tablecrop(copyT(textlist[selected.w[2]]), selected.w[1], selected.e[1] - 1), "")
		if cut then
			tableselectedremove(textlist[selected.w[2]], selected.w[1], selected.e[1] - 1)
		end
	end
	
	if cut and selected.w[2] ~= selected.e[2] then
		local offset = 0
		for sy = selected.w[2], selected.e[2] do
			if textlist[sy - offset] and textlist[sy - offset][1] == "toremove" then
				table.remove(textlist, sy - offset)
				offset = offset + 1
			end
		end
		
		table.remove(textlist, selected.e[2] - offset)
		table.remove(textlist, selected.w[2])
		table.insert(textlist, selected.w[2] ,rebegining)
		timesnap = 5 - 2
		tb.cursor = {selected.w[1], selected.w[2]}
		clearSelect()
	elseif cut and selected.w[2] == selected.e[2] then
		timesnap = 5 - 2
		tb.cursor = {selected.w[1], selected.w[2]}
		clearSelect()
	end
	
	cursorFocus()
	return str
end

function getSelectiveLetters(line, start, e)
	local s = start
	local s2 = e
	
	if start > e then
		s = e
		s2 = start
	end
	
	local str = ""
	
	for i = s,s2 - 1 do
		if textlist[line][i] then
			str = str..utf8.char(string.byte(textlist[line][i]))
		end
	end
	return str
end

function clearSelect()
	tb.select = {w = copyT(tb.cursor), e = copyT(tb.cursor)}
end

function packtlist(t)
	local tab = {}
	for i,v in ipairs(t) do
		table.insert(tab, table.concat(v, ""))
	end
	return tab
end

function unpacktlist(t)
	local tab = {}
	for i,v in ipairs(t) do
		local new = {}
		for i2 = 1, string.len(v) do
			table.insert(new, string.sub(v, i2, i2))
		end
		table.insert(tab,new)
	end
	return tab
end

function copyT(t)
	local tab = {}
	for i,v in pairs(t) do
		tab[i] = v
	end
	return tab
end

function combineT(t, t2)
	for i,v in pairs(t2) do
		table.insert(t,v)
	end
	return t
end

function tbc(t)
	local tab = {view = {t.view[1] + 0, t.view[2] + 0},  cursor = {t.cursor[1] + 0, t.cursor[2] + 0}, select = nil, panning = nil}
	if t.select then
		tab.select = {w = {t.select.w[1] + 0,t.select.w[2] + 0}, e = {t.select.e[1] + 0,t.select.e[2] + 0}}
	end
	return tab
end

function takesnapshot()
	for i,v in ipairs(resnapshot) do
		table.remove(resnapshot, 1)
	end
	table.insert(snapshot, {textlist = packtlist(textlist), tb = tbc(tb)})
end

function undo()
	if #snapshot > 1 then
		table.insert(resnapshot, snapshot[#snapshot - 1])
		textlist = unpacktlist(snapshot[#snapshot - 1].textlist)
		tb =  tbc(snapshot[#snapshot - 1].tb)
		table.remove(snapshot, #snapshot)
	end
end

function redo()
	if #resnapshot > 0 then
		table.insert(snapshot, resnapshot[#resnapshot])
		textlist = unpacktlist(resnapshot[#resnapshot].textlist)
		tb = tbc(resnapshot[#resnapshot].tb)
		table.remove(resnapshot, #resnapshot)
	end
end

function clipboard_cut()
	widget.setText("paste", multiline_function(true))
end

function clipboard_copy()
	if (tb.select and tb.select.e and tb.select.w) and (tb.select.e[1] ~= tb.select.w[1] and tb.select.e[2] ~= tb.select.w[2])then
		widget.setText("paste", multiline_function(false))
	elseif (tb.select and tb.select.e and tb.select.w) and (tb.select.e[1] ~= tb.select.w[1] and tb.select.e[2] == tb.select.w[2])then
		widget.setText("paste", multiline_function(false))
	elseif (tb.select and tb.select.e and tb.select.w) and (tb.select.e[1] == tb.select.w[1] and tb.select.e[2] ~= tb.select.w[2])then
		widget.setText("paste", multiline_function(false))
	else
		widget.setText("paste", "")
	end
end

function clipboard_copyno()
	return multiline_function(false)
end

function clipboard_paste()
	if (tb.select and tb.select.e and tb.select.w) and (tb.select.e[1] ~= tb.select.w[1] and tb.select.e[2] ~= tb.select.w[2])then
		multiline_function(true)
	elseif (tb.select and tb.select.e and tb.select.w) and (tb.select.e[1] == tb.select.w[1] and tb.select.e[2] ~= tb.select.w[2])then
		multiline_function(true)
	elseif (tb.select and tb.select.e and tb.select.w) and (tb.select.e[1] ~= tb.select.w[1] and tb.select.e[2] == tb.select.w[2])then
		multiline_function(true)
	end
	local cl = widget.getText("paste")
	local sl = string.len
	local ss = string.sub
	for i = 1,sl(cl) do
		addLetter(tb.cursor[2], tb.cursor[1], ss(cl, i,i))
		moveCursor("right")
	end
	cursorFocus()
end

function pastestring(str)
	local cl = str
	local sl = string.len
	local ss = string.sub
	for i = 1,sl(cl) do
		addLetter(tb.cursor[2], tb.cursor[1], ss(cl, i,i))
		moveCursor("right")
	end
	cursorFocus()
end

--

textraw = "" --test
timesnap = 0
snapshot = {}
resnapshot = {}

textlist = {
	{}
}

textbox = {}

tb = {
	view = {0,0},
	cursor = {1,1},
	select = nil, --{w = {1,1}, e = {1,4}}
	panning = nil --{start = {0,0}, cur = {0,0}, original = {}}
}

repackThread = nil
repacking = false
repacktype = "save"

function ucon(str)
	local esc = ""
	for i = 1, string.len(str) do
		esc = esc..utf8.char(string.byte(string.sub(str,i,i)))
	end
	return esc
end

function repack()
	local str = ""
	local lp = 0
	local tc = table.concat
	for i,v in ipairs(textlist) do
		if textlist[i + 1] then
			str = str..tc(v, "").."\n"
		else
			str = str..tc(v, "")
		end
		if lp > 60 then
			coroutine.yield()
			lp = 0
		else
			lp = lp + 1
		end
	end
	
	if repacktype ~= "rejson" and config.getParameter("scriptConfig").saveraw then
		local s, resu = pcall(json.decode, str)
		if not s then
			sb.logError(string.gsub(resu, "%[.+: ", "", 1))
		else
			world.sendEntityMessage(player.id(),"editor_rawSave", config.getParameter("scriptConfig").editoruuid, resu)
			pane.dismiss()
		end
	elseif repacktype == "save" then
		local newUI = root.assetJson("/itemeditork/saveparam/pane.json")
		newUI.scriptConfig = {etext = str, nameparam = config.getParameter("scriptConfig").nameparam, editoruuid = config.getParameter("scriptConfig").editoruuid}
		player.interact("ScriptPane", newUI)
	elseif repacktype == "rejson" then
		local json, e = pcall(json.decode, str)
		if json then
			local textt, e3 = pcall(sb.printJson, e, 1) --Sometimes it has issues parsing UTF-8 codes
			
			if textt then
				textlist = {}
				local ti = table.insert
				local ss = string.sub
				local sl = string.len
				for line,t in pairs(split(e3,"\n")) do
					textlist[line] = {}
					for c =1,sl(t) do
						ti(textlist[line], ss(t,c,c))
					end
				end
				moveCursor("check")
				clearSelect()
				cursorFocus()
			else
				sb.logError(e)
				local textt2, e2 = pcall(json.encode, json, 1) --raw parse
				if textt2 then
					textlist = {}
					local ti = table.insert
					local ss = string.sub
					local sl = string.len
					for line,t in pairs(split(ucon(e2),"\n")) do
						textlist[line] = {}
						for c =1,sl(t) do
							ti(textlist[line], ss(t,c,c))
						end
					end
					moveCursor("check")
					clearSelect()
					cursorFocus()
				else
					sb.logError(e2)
				end
			end
			
			
		end
		
	end
	repacking = false
end

repeatDel = 0
focusedP = false

--THEME


_buttons = {
	save = "/itemeditork/editjson/button.png",
	close = "/itemeditork/editjson/x.png",
	clear = "/itemeditork/editjson/clear.png",
	rejson = "/itemeditork/editjson/rejson.png",
}

_images = {
	bg2 = "/itemeditork/editjson/bg.png",
	bg1 = "/itemeditork/editjson/header.png"
}

_texts = {
	"paste",
	
}

themeColor = "72e372"
themeDarkColor = "#000000"

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

function init()
	pcall(setUIColor, status.statusProperty("rex_ui_color", root.assetJson("/itemeditork/info.config:defaultColor", "72e372")))
	shiftingEnabled = status.statusProperty("rex_ui_rainbow", false)
	textbox = widget.bindCanvas("textbox")
	local text = config.getParameter("scriptConfig").text
	local ti = table.insert
	local ss = string.sub
	local sl = string.len
	for line,t in pairs(split(text,"\n")) do
		textlist[line] = {}
		for c =1,sl(t) do
			ti(textlist[line], ss(t,c,c))
		end
	end
	timesnap = 3
	widget.focus("textbox")
end

function uninit()

end

function lerp(from, to, smooth)
	return from + (to - from) / smooth
end

function update(dt)
	if type(repackThread) == "thread" and coroutine.status(repackThread) == "suspended" then
		coroutine.resume(repackThread)
	elseif type(repackThread) == "thread" and coroutine.status(repackThread) == "dead"  then
		repacking = false
	end

	if not repacking then
		updateKeyboard(dt)
		updateMouse(dt)
	end
	
	if timesnap == 1 then
		takesnapshot()
		timesnap = 0
	elseif timesnap == 0 then
	
	elseif timesnap > 1 then
		timesnap = timesnap - 1
	end
	
	if scrolling then
		local scroll = (#textlist) * (( (guisize.y - 1) - (textbox:mousePosition()[2] + ((guisize.y - 1) / #textlist) * 10) ) / (guisize.y - 1))
	
		tb.view[2] = math.min( 
			math.max(
				lerp(tb.view[2], scroll, 4)
			,0
			),
			math.max( #textlist - (renderLines - 1), 0)
		)
	end
	shiftUI(dt)
	updateRender(dt)
end

function getCorner()
	return textbox:mousePosition()
end

function updateKeyboard(dt)

	if keyboard.backspace and repeatDel <= 0 then
		removeLetter(tb.cursor[2], tb.cursor[1])
		repeatDel = 2
	elseif keyboard.backspace then
		repeatDel = math.max(repeatDel - 1, 0)
	end
end

function cursorOverride(screenPosition)
	if widget.getChildAt(screenPosition) == ".textbox" then
		return "/itemeditork/editjson/text.cursor"
	elseif widget.getChildAt(screenPosition) == ".paste" then
		return "/itemeditork/editjson/tooltip1.cursor"
	end
end

function updateMouse(dt)

	

	if mouse[3] and mouse[3].down and not keyboard.backspace then
		if not panning then
			panning = {start = mouse[3].position, cur = mouse[3].position, original = tb.view}
		end
		panning.cur = textbox:mousePosition()
		
		local dif = vec2.mul(vec2.sub(panning.cur, panning.start), {-1/5, 1/8})
		if keyboard.rshift or keyboard.lshift then
			dif[1] = dif[1] * 2
			dif[2] = dif[2] * 2
		end
		
		local view = vec2.add(panning.original, dif)
		view[1] = math.max(view[1],0)
		view[2] = math.max(view[2],0)
		
		tb.view = view
	else
		if panning then
			panning = nil
		end
	end
	if mouse[1] and mouse[1].down and not keyboard.backspace then
		local position = textbox:mousePosition()
		local dif = vec2.sub({-10, guisize.y + 9}, {-position[1], position[2]})
		
		dif = vec2.mul(dif, {1/5, 1/8})
		dif[1] = math.floor(dif[1])
		dif[2] = math.floor(dif[2])
		
		local vf = vec2.add(tb.view, {0,0})
		tb.view[1] = math.floor(tb.view[1])
		tb.view[2] = math.floor(tb.view[2])
		
		local view = vec2.add(tb.view, dif)
		view[1] = math.max(view[1],1)
		view[2] = math.max(view[2],1)
		
		if #textlist >= view[2] then
			if tb.select then
				tb.select.e = {math.max( math.min(vec2.add(tb.view, dif)[1], #textlist[tb.select.e[2]]+ 1),1), math.max( math.min(vec2.add(tb.view, dif)[2], #textlist), 1)}
			end
			tb.cursor = view
			moveCursor("check")
		end
	end
end

function getChar(num)
	if num == 32 then
		return "/assetmissing.png"
	end
	if num > 32 and num < 128 then
		return "/itemeditork/text/33_127.png:"..(num - 33)
	end
	
	if num > 160 and num < 383 then
		return "/itemeditork/text/161_382.png:"..(num - 161)
	end
	
	if num > 1023 and num < 1320 then
		return "/itemeditork/text/1024_1320.png:"..(num - 1024)
	end
	
	return "/itemeditork/text/placeholder.png"
end

function updateSelect(dt)
	local drt = textbox
	local selected = absoluteSelected()
	for sy = selected.w[2], selected.e[2] do
		if selected.w[2] == selected.e[2] then
			drt:drawLine({ 15 + ((selected.e[1] - tb.view[1] - 0.5) * 5),
							(guisize.y + 3) - ((sy - tb.view[2]) * 8)}, 
						{15 + (((selected.w[1] - tb.view[1]) - 0.5) * 5), 
							(guisize.y + 3) - ((sy - tb.view[2]) * 8)}
							, "#fafafa32", 16)
		elseif sy == selected.e[2] then
			drt:drawLine({ 15 + ((selected.e[1] - tb.view[1] - 0.5) * 5),
							(guisize.y + 3) - ((sy - tb.view[2]) * 8)}, 
						{15 + (((0 - tb.view[1]) - 0.5) * 5), 
							(guisize.y + 3) - ((sy - tb.view[2]) * 8)}
							, "#fafafa32", 16)
		elseif sy == selected.w[2] then
			drt:drawLine(
				{15 + ((#textlist[sy] - tb.view[1] + 0.5) * 5),
					(guisize.y + 3) - ((sy - tb.view[2]) * 8)}, 
				{15 + (((selected.w[1] - tb.view[1]) - 0.5) * 5),
					(guisize.y + 3) - ((sy - tb.view[2]) * 8)}
				, "#fafafa32", 16)
		else
			drt:drawLine(
				{15 + ((0 - tb.view[1] - 0.5) * 5),
					(guisize.y + 3) - ((sy - tb.view[2]) * 8)}, 
				{15 + (((#textlist[sy] - tb.view[1]) + 0.5) * 5),
					(guisize.y + 3) - ((sy - tb.view[2]) * 8)}
				, "#fafafa32", 16)
		end
	end
end

function updateRender(dt)
	textbox:clear()
	if not repacking then	
		local mf = math.floor
		local mc = math.ceil
		local drt = textbox
		drt:drawLine({8, guisize.y}, {8, 0}, "#"..themeColor, 36)
		for y = math.max(mf(tb.view[2]), 1), math.min(mf(tb.view[2]) + renderLines, #textlist) do
			drt:drawText(y, {position = {1, (guisize.y + 3) - (y * 8) + tb.view[2] * 8}, horizontalAnchor = "left", verticalAnchor = "mid", wrapWidth = nil}, 6, themeDarkColor)
			local totalchar = #textlist[y]
			if totalchar > 0 and #textlist[y] + 1 > tb.view[1] then
				for x = math.max(math.min(mc(tb.view[1]), totalchar), 1), math.min(mf(tb.view[1]) + renderLineTexts, totalchar) do
					drt:drawImage(getChar(string.byte(textlist[y][x])), {15 + (x * 5) + tb.view[1] * -5, (guisize.y + 3) - (y * 8) + tb.view[2] * 8}, 0.5, "#"..themeColor, true)
				end
			end
		end
		textbox:drawLine(
			vec2.add({13 + (tb.cursor[1] * 5), guisize.y - (tb.cursor[2] * 8)}, vec2.mul(tb.view, {-5,8})), 
			vec2.add({13 + (tb.cursor[1] * 5), (guisize.y + 6) - (tb.cursor[2] * 8)}, vec2.mul(tb.view, {-5,8})), 
			{255,255,255,(math.sin(os.clock() * 4)) * 255}, 
			1
		)
		if tb.select then
			updateSelect(dt)
		end
		drt:drawLine({guisize.x - 7.5, guisize.y - 1.5}, {guisize.x - 7.5, 1.5}, "#4b4b4b", 16)	
		drt:drawLine({guisize.x - 7.5, guisize.y - 3}, {guisize.x - 7.5, 3}, "#343434", 10)
		drt:drawLine({guisize.x - 7.5, math.max((guisize.y - 2) - (((renderLines - 1) / math.max(#textlist, (renderLines - 1))) * (guisize.y - 3)) - (tb.view[2] / #textlist) * (guisize.y - 2), 2)}, {guisize.x - 7.5, math.max(math.min((guisize.y - 2) - (tb.view[2] / (#textlist - 1)) * (guisize.y - 1), (guisize.y - 3)), 1)}, "#"..themeColor, 10)
		drt:drawLine({guisize.x - 7.5, math.max(guisize.y - (((renderLines - 1) / math.max(#textlist, (renderLines - 1))) * (guisize.y - 3)) - (tb.view[2] / #textlist) * (guisize.y - 2), 2)}, {guisize.x - 7.5, math.max(math.min((guisize.y - 3) - (tb.view[2] / (#textlist - 1)) * (guisize.y - 1), (guisize.y - 3)), 1)}, "#"..themeColor, 10)
		--guisize.x 
		--(guisize.x - 1)
		--(guisize.x - 2)
	else
		if repacktype == "save" then
			textbox:drawText("Saving....", {position = {264 / 2, 176 / 2}, horizontalAnchor = "mid", verticalAnchor = "mid", wrapWidth = nil}, 16, "#"..themeColor)
		elseif repacktype == "rejson" then
			textbox:drawText("reFormatting....", {position = {264 / 2, 176 / 2}, horizontalAnchor = "mid", verticalAnchor = "mid", wrapWidth = nil}, 16, "#"..themeColor)
		end
	end
	
end