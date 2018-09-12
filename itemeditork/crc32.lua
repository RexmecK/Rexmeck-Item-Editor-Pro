function crc32(asr)
	local bit32 = {}

	local function checkint( name, argidx, x, level )
		local n = tonumber( x )
		if not n then
			error( string.format(
				"bad argument #%d to '%s' (number expected, got %s)",
				argidx, name, type( x )
			), level + 1 )
		end
		return math.floor( n )
	end
	
	local function checkint32( name, argidx, x, level )
		local n = tonumber( x )
		if not n then
			error( string.format(
				"bad argument #%d to '%s' (number expected, got %s)",
				argidx, name, type( x )
			), level + 1 )
		end
		return math.floor( n ) % 0x100000000
	end
	
	function bit32.bnot( x )
		x = checkint32( 'bnot', 1, x, 2 )
	
		-- In two's complement, -x = not(x) + 1
		-- So not(x) = -x - 1
		return ( -x - 1 ) % 0x100000000
	end
	
	local logic_and = {
		[0] = { [0] = 0, 0, 0, 0},
		[1] = { [0] = 0, 1, 0, 1},
		[2] = { [0] = 0, 0, 2, 2},
		[3] = { [0] = 0, 1, 2, 3},
	}
	local logic_or = {
		[0] = { [0] = 0, 1, 2, 3},
		[1] = { [0] = 1, 1, 3, 3},
		[2] = { [0] = 2, 3, 2, 3},
		[3] = { [0] = 3, 3, 3, 3},
	}
	local logic_xor = {
		[0] = { [0] = 0, 1, 2, 3},
		[1] = { [0] = 1, 0, 3, 2},
		[2] = { [0] = 2, 3, 0, 1},
		[3] = { [0] = 3, 2, 1, 0},
	}
	
	local function comb( name, args, nargs, s, t )
		for i = 1, nargs do
			args[i] = checkint32( name, i, args[i], 3 )
		end
	
		local pow = 1
		local ret = 0
		for b = 0, 31, 2 do
			local c = s
			for i = 1, nargs do
				c = t[c][args[i] % 4]
				args[i] = math.floor( args[i] / 4 )
			end
			ret = ret + c * pow
			pow = pow * 4
		end
		return ret
	end
	
	function bit32.band( ... )
		return comb( 'band', { ... }, select( '#', ... ), 3, logic_and )
	end
	
	function bit32.bor( ... )
		return comb( 'bor', { ... }, select( '#', ... ), 0, logic_or )
	end
	
	function bit32.bxor( ... )
		return comb( 'bxor', { ... }, select( '#', ... ), 0, logic_xor )
	end
	
	function bit32.btest( ... )
		return comb( 'btest', { ... }, select( '#', ... ), 3, logic_and ) ~= 0
	end
	
	
	function bit32.extract( n, field, width )
		n = checkint32( 'extract', 1, n, 2 )
		field = checkint( 'extract', 2, field, 2 )
		width = checkint( 'extract', 3, width or 1, 2 )
		if field < 0 then
			error( "bad argument #2 to 'extract' (field cannot be negative)", 2 )
		end
		if width <= 0 then
			error( "bad argument #3 to 'extract' (width must be positive)", 2 )
		end
		if field + width > 32 then
			error( 'trying to access non-existent bits', 2 )
		end
	
		return math.floor( n / 2^field ) % 2^width
	end
	
	function bit32.replace( n, v, field, width )
		n = checkint32( 'replace', 1, n, 2 )
		v = checkint32( 'replace', 2, v, 2 )
		field = checkint( 'replace', 3, field, 2 )
		width = checkint( 'replace', 4, width or 1, 2 )
		if field < 0 then
			error( "bad argument #3 to 'replace' (field cannot be negative)", 2 )
		end
		if width <= 0 then
			error( "bad argument #4 to 'replace' (width must be positive)", 2 )
		end
		if field + width > 32 then
			error( 'trying to access non-existent bits', 2 )
		end
	
		local f = 2^field
		local w = 2^width
		local fw = f * w
		return ( n % f ) + ( v % w ) * f + math.floor( n / fw ) * fw
	end
	
	local function checkdisp( name, x )
		x = checkint( name, 2, x, 3 )
		return math.min( math.max( -32, x ), 32 )
	end
	
	function bit32.lshift( x, disp )
		x = checkint32( 'lshift', 1, x, 2 )
		disp = checkdisp( 'lshift', disp )
	
		return math.floor( x * 2^disp ) % 0x100000000
	end
	
	function bit32.rshift( x, disp )
		x = checkint32( 'rshift', 1, x, 2 )
		disp = checkdisp( 'rshift', disp )
	
		return math.floor( x / 2^disp ) % 0x100000000
	end
	
	function bit32.arshift( x, disp )
		x = checkint32( 'arshift', 1, x, 2 )
		disp = checkdisp( 'arshift', disp )
	
		if disp <= 0 then
			return ( x * 2^-disp ) % 0x100000000
		elseif x < 0x80000000 then
			return math.floor( x / 2^disp )
		elseif disp > 31 then
			return 0xffffffff
		else
			return math.floor( x / 2^disp ) + ( 0x100000000 - 2 ^ ( 32 - disp ) )
		end
	end
	
	function bit32.lrotate( x, disp )
		x = checkint32( 'lrotate', 1, x, 2 )
		disp = checkint( 'lrotate', 2, disp, 2 ) % 32
	
		local x = x * 2^disp
		return ( x % 0x100000000 ) + math.floor( x / 0x100000000 )
	end
	
	function bit32.rrotate( x, disp )
		x = checkint32( 'rrotate', 1, x, 2 )
		disp = -checkint( 'rrotate', 2, disp, 2 ) % 32
	
		local x = x * 2^disp
		return ( x % 0x100000000 ) + math.floor( x / 0x100000000 )
	end

	local bit_band, bit_bxor, bit_rshift, str_byte, str_len = bit32.band, bit32.bxor, bit32.rshift, string.byte, string.len
	local consts = { 0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3, 0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988, 0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91, 0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7, 0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5, 0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172, 0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B, 0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59, 0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F, 0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924, 0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D, 0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433, 0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01, 0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E, 0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457, 0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65, 0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB, 0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0, 0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9, 0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F, 0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD, 0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A, 0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683, 0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1, 0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7, 0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC, 0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5, 0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B, 0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79, 0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236, 0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F, 0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D, 0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713, 0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38, 0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21, 0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777, 0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45, 0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2, 0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB, 0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9, 0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF, 0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94, 0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D }
	
	local function crc(s)
		local crc, l, i = 0xFFFFFFFF, str_len(s)
		for i = 1, l, 1 do
			crc = bit_bxor(bit_rshift(crc, 8), consts[bit_band(bit_bxor(crc, str_byte(s, i)), 0xFF) + 1])
		end
		return bit_bxor(crc, -1)
	end
	
	return crc(asr)
end