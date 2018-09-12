hueRGB = 0


function HueToColor(hue)
	return {
	    ((math.sin(math.rad(hue + 90) ) + 1) / 2) * 360,
	    ((math.sin(math.rad(hue + 0) ) + 1) / 2) * 360,
	    ((math.sin(math.rad(hue + -90)    ) + 1) / 2) * 360
	}
end

function colorhex(tab,max)
	return string.format("%02X",math.floor((tab[1] / max) * 255))..string.format("%02X",math.floor((tab[2] / max) * 255))..string.format("%02X",math.floor((tab[3] / max) * 255))
end

function shiftUI(dt)
	if shiftingEnabled then
		hueRGB = hueRGB + (dt * 30)
		if hueRGB > 360 then
			hueRGB = hueRGB - 360
		end
		setUIColor(colorhex(HueToColor( math.abs(math.sin(os.clock() / 2)) * 360 )
				, 
				360
			)
		)
	end
end