-----------------------------------------------------------------------------
-- JSON4Lua: JSON encoding / decoding support for the Lua language.
-- json Module.
-- Author: Craig Mason-Jones
-- Homepage: http://github.com/craigmj/json4lua/
-- Version: 1.0.0
-- This module is released under the MIT License (MIT).
-- Please see LICENCE.txt for details.
--
-- USAGE:
-- This module exposes two functions:
--   json.encode(o)
--     Returns the table / string / boolean / number / nil / json.null value as a JSON-encoded string.
--   json.decode(json_string)
--     Returns a Lua object populated with the data encoded in the JSON string json_string.
--
-- REQUIREMENTS:
--   compat-5.1 if using Lua 5.0
--
-- CHANGELOG
--   0.9.20 Introduction of local Lua functions for private functions (removed _ function prefix). 
--          Fixed Lua 5.1 compatibility issues.
--   		Introduced json.null to have null values in associative arrays.
--          json.encode() performance improvement (more than 50%) through table.concat rather than ..
--          Introduced decode ability to ignore /**/ comments in the JSON string.
--   0.9.10 Fix to array encoding / decoding to correctly manage nil/null values in arrays.
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Imports and dependencies
-----------------------------------------------------------------------------
-- Not generally required in most Lua installations (and especially not in Starbound, and will actually crash the game).
-- local math = require('math')
-- local string = require("string")
-- local table = require("table")

-----------------------------------------------------------------------------
-- Module declaration
-----------------------------------------------------------------------------
json = {}             -- Public namespace
local json_private = {}     -- Private namespace

-- Public functions

-- Private functions -- These *might* need to be global objects, being that we're using Lua 5.3.
local decode_scanArray
local decode_scanComment
local decode_scanConstant
local decode_scanNumber
local decode_scanObject
local decode_scanString
local decode_scanWhitespace
-- local encodeString
local isArray
local isEncodable

-----------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-----------------------------------------------------------------------------
--- Encodes an arbitrary Lua object / variable.
-- @param v The Lua object / variable to be JSON encoded.
-- @return String containing the JSON encoding in internal Lua string format (i.e. not unicode)
function json.encode (v)
  -- Handle nil values
  if v==nil then
    return "null"
  end
  
  local vtype = type(v)

  -- Handle strings
  if vtype=='string' then    
    return '"' .. json_private.encodeString(v) .. '"'	    -- Need to handle encoding in string
  end
  
  -- Handle booleans
  if vtype=='number' or vtype=='boolean' then
    return tostring(v)
  end
  
  -- Handle tables
  if vtype=='table' then
    local rval = {}
    -- Consider arrays separately
    local bArray, maxCount = isArray(v)
    if bArray then
      for i = 1,maxCount do
        table.insert(rval, json.encode(v[i]))
      end
    else	-- An object, not an array
      for i,j in pairs(v) do
        if isEncodable(i) and isEncodable(j) then
          table.insert(rval, '"' .. json_private.encodeString(i) .. '":' .. json.encode(j))
        end
      end
    end
    if bArray then
      return '[' .. table.concat(rval,',') ..']'
    else
      return '{' .. table.concat(rval,',') .. '}'
    end
  end
  
  -- Handle null values
  if vtype=='function' and v==null then
    return 'null'
  end
  
  assert(false,'encode attempt to encode unsupported type ' .. vtype .. ':' .. tostring(v))
end


--- Decodes a JSON string and returns the decoded value as a Lua data structure / value.
-- @param s The string to scan.
-- @param [startPos] Optional starting position where the JSON string is located. Defaults to 1.
-- @param Lua object, number The object that was scanned, as a Lua table / string / number / boolean or nil,
-- and the position of the first character after
-- the scanned JSON object.
function json.decode(s, startPos)
  startPos = startPos and startPos or 1
  startPos = decode_scanWhitespace(s,startPos)
  assert(startPos<=string.len(s), 'Unterminated JSON encoded object found at position in [' .. s .. ']')
  local curChar = string.sub(s,startPos,startPos)
  -- Object
  if curChar=='{' then
    return decode_scanObject(s,startPos)
  end
  -- Array
  if curChar=='[' then
    return decode_scanArray(s,startPos)
  end
  -- Number
  if string.find("+-0123456789.e", curChar, 1, true) then
    return decode_scanNumber(s,startPos)
  end
  -- String
  if curChar==[["]] or curChar==[[']] then
    return decode_scanString(s,startPos)
  end
  if string.sub(s,startPos,startPos+1)=='/*' then
    return json.decode(s, decode_scanComment(s,startPos))
  end
  -- Otherwise, it must be a constant
  return decode_scanConstant(s,startPos)
end

--- The null function allows one to specify a null value in an associative array (which is otherwise
-- discarded if you set the value with 'nil' in Lua. Simply set t = { first=json.null }
function null()
  return null -- so json.null() will also return null ;-)
end
-----------------------------------------------------------------------------
-- Internal, PRIVATE functions.
-- Following a Python-like convention, I have prefixed all these 'PRIVATE'
-- functions with an underscore.
-----------------------------------------------------------------------------

--- Scans an array from JSON into a Lua object
-- startPos begins at the start of the array.
-- Returns the array and the next starting position
-- @param s The string being scanned.
-- @param startPos The starting position for the scan.
-- @return table, int The scanned array as a table, and the position of the next character to scan.
function decode_scanArray(s,startPos)
  local array = {}	-- The return value
  local stringLen = string.len(s)
  assert(string.sub(s,startPos,startPos)=='[','decode_scanArray called but array does not start at position ' .. startPos .. ' in string:\n'..s )
  startPos = startPos + 1
  -- Infinite loop for array elements
  repeat
    startPos = decode_scanWhitespace(s,startPos)
    assert(startPos<=stringLen,'JSON String ended unexpectedly scanning array.')
    local curChar = string.sub(s,startPos,startPos)
    if (curChar==']') then
      -- Checks if Starbound's jarray() callback exists and then replaces empty arrays with jarray().
      if type(jarray) == "function" and #array == 0 then
        array = jarray()
      end
      return array, startPos+1
    end
    if (curChar==',') then
      startPos = decode_scanWhitespace(s,startPos+1)
    end
    assert(startPos<=stringLen, 'JSON String ended unexpectedly scanning array.')
    object, startPos = json.decode(s,startPos)
    table.insert(array,object)
  until false
  
end

--- Scans a comment and discards the comment.
-- Returns the position of the next character following the comment.
-- @param string s The JSON string to scan.
-- @param int startPos The starting position of the comment
function decode_scanComment(s, startPos)
  assert( string.sub(s,startPos,startPos+1)=='/*', "decode_scanComment called but comment does not start at position " .. startPos)
  local endPos = string.find(s,'*/',startPos+2)
  assert(endPos~=nil, "Unterminated comment in string at " .. startPos)
  return endPos+2  
end

--- Scans for given constants: true, false or null
-- Returns the appropriate Lua type, and the position of the next character to read.
-- @param s The string being scanned.
-- @param startPos The position in the string at which to start scanning.
-- @return object, int The object (true, false or nil) and the position at which the next character should be 
-- scanned.
function decode_scanConstant(s, startPos)
  local consts = { ["true"] = true, ["false"] = false, ["null"] = nil }
  local constNames = {"true","false","null"}

  for i,k in pairs(constNames) do
    if string.sub(s,startPos, startPos + string.len(k) -1 )==k then
      return consts[k], startPos + string.len(k)
    end
  end
  assert(nil, 'Failed to scan constant from string ' .. s .. ' at starting position ' .. startPos)
end

--- Scans a number from the JSON encoded string.
-- (in fact, also is able to scan numeric +- eqns, which is not
-- in the JSON spec.)
-- Returns the number, and the position of the next character
-- after the number.
-- @param s The string being scanned.
-- @param startPos The position at which to start scanning.
-- @return number, int The extracted number and the position of the next character to scan.
function decode_scanNumber(s,startPos)
  local endPos = startPos+1
  local stringLen = string.len(s)
  local acceptableChars = "+-0123456789.e"
  while (string.find(acceptableChars, string.sub(s,endPos,endPos), 1, true)
	and endPos<=stringLen
	) do
    endPos = endPos + 1
  end
  local stringValue = function() return tonumber(string.sub(s,startPos, endPos-1)) end
  local stringEval = stringValue
  assert(stringEval, 'Failed to scan number [ ' .. tostring(string.sub(s,startPos, endPos-1)) .. '] in JSON string at position ' .. startPos .. ' : ' .. endPos)
  return stringEval(), endPos
end

--- Scans a JSON object into a Lua object.
-- startPos begins at the start of the object.
-- Returns the object and the next starting position.
-- @param s The string being scanned.
-- @param startPos The starting position of the scan.
-- @return table, int The scanned object as a table and the position of the next character to scan.
function decode_scanObject(s,startPos)
  local object = {}
  local stringLen = string.len(s)
  local key, value
  assert(string.sub(s,startPos,startPos)=='{','decode_scanObject called but object does not start at position ' .. startPos .. ' in string:\n' .. s)
  startPos = startPos + 1
  repeat
    startPos = decode_scanWhitespace(s,startPos)
    assert(startPos<=stringLen, 'JSON string ended unexpectedly while scanning object.')
    local curChar = string.sub(s,startPos,startPos)
    if (curChar=='}') then
      return object,startPos+1
    end
    if (curChar==',') then
      startPos = decode_scanWhitespace(s,startPos+1)
    end
    assert(startPos<=stringLen, 'JSON string ended unexpectedly scanning object.')
    -- Scan the key
    key, startPos = json.decode(s,startPos)
    assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    startPos = decode_scanWhitespace(s,startPos)
    assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    assert(string.sub(s,startPos,startPos)==':','JSON object key-value assignment mal-formed at ' .. startPos)
    startPos = decode_scanWhitespace(s,startPos+1)
    assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
    value, startPos = json.decode(s,startPos)
    object[key]=value
  until false	-- infinite loop while key-value pairs are found
end
-- START SoniEx2
-- Initialize some things used by decode_scanString
-- You know, for efficiency
local escapeSequences = {
  ["\\t"] = "\t",
  ["\\f"] = "\f",
  ["\\r"] = "\r",
  ["\\n"] = "\n",
  ["\\b"] = "\b"
}
setmetatable(escapeSequences, {__index = function(t,k)
  -- skip "\" aka strip escape
  return string.sub(k,2)
end})
-- END SoniEx2

--- Scans a JSON string from the opening inverted comma or single quote to the
-- end of the string.
-- Returns the string extracted as a Lua string,
-- and the position of the next non-string character
-- (after the closing inverted comma or single quote).
-- @param s The string being scanned.
-- @param startPos The starting position of the scan.
-- @return string, int The extracted string as a Lua string, and the next character to parse.
function decode_scanString(s,startPos)
  assert(startPos, 'decode_scanString(..) called without start position')
  local startChar = string.sub(s,startPos,startPos)
  -- START SoniEx2
  -- PS: I don't think single quotes are valid JSON
  assert(startChar == [["]] or startChar == [[']],'decode_scanString called for a non-string')
  --assert(startPos, "String decoding failed: missing closing " .. startChar .. " for string at position " .. oldStart)
  local t = {}
  local i,j = startPos,startPos
  while string.find(s, startChar, j+1) ~= j+1 do
    local oldj = j
    i,j = string.find(s, "\\.", j+1)
    local x,y = string.find(s, startChar, oldj+1)
    if not i or x < i then
      i,j = x,y-1
    end
    table.insert(t, string.sub(s, oldj+1, i-1))
    if string.sub(s, i, j) == "\\u" then
      local a = string.sub(s,j+1,j+4)
      j = j + 4
      local n = tonumber(a, 16)
      assert(n, "String decoding failed: bad Unicode escape " .. a .. " at position " .. i .. " : " .. j)
      -- math.floor(x/2^y) == lazy right shift
      -- a % 2^b == bitwise_and(a, (2^b)-1)
      -- 64 = 2^6
      -- 4096 = 2^12 (or 2^6 * 2^6)
      local x
      if n < 0x80 then
        x = string.char(n % 0x80)
      elseif n < 0x800 then
        -- [110x xxxx] [10xx xxxx]
        x = string.char(0xC0 + (math.floor(n/64) % 0x20), 0x80 + (n % 0x40))
      else
        -- [1110 xxxx] [10xx xxxx] [10xx xxxx]
        x = string.char(0xE0 + (math.floor(n/4096) % 0x10), 0x80 + (math.floor(n/64) % 0x40), 0x80 + (n % 0x40))
      end
      table.insert(t, x)
    else
      table.insert(t, escapeSequences[string.sub(s, i, j)])
    end
  end
  table.insert(t,string.sub(j, j+1))
  assert(string.find(s, startChar, j+1), "String decoding failed: missing closing " .. startChar .. " at position " .. j .. "(for string at position " .. startPos .. ")")
  return table.concat(t,""), j+2
  -- END SoniEx2
end

--- Scans a JSON string skipping all whitespace from the current start position.
-- Returns the position of the first non-whitespace character, or nil if the whole end of string is reached.
-- @param s The string being scanned
-- @param startPos The starting position where we should begin removing whitespace.
-- @return int The first position where non-whitespace was encountered, or string.len(s)+1 if the end of string
-- was reached.
function decode_scanWhitespace(s,startPos)
  local whitespace=" \n\r\t"
  local stringLen = string.len(s)
  while ( string.find(whitespace, string.sub(s,startPos,startPos), 1, true)  and startPos <= stringLen) do
    startPos = startPos + 1
  end
  return startPos
end

function rhashString(str) --2049951663
  local hash = 216613626153532
  for i = 1, #str do
    hash = hash ~ str:byte(i)
    hash = (hash * 1677761940769234) & 0xffffffff
  end
  return hash
end

--- Encodes a string to be JSON-compatible.
-- This just involves back-quoting inverted commas, back-quotes and newlines, I think ;-)
-- @param s The string to return as a JSON encoded (i.e. backquoted string)
-- @return The string appropriately escaped.

local escapeList = {
    ['"']  = '\\"',
    ['\\'] = '\\\\',
    ['/']  = '\\/', 
    ['\b'] = '\\b',
    ['\f'] = '\\f',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t'
}

function json_private.encodeString(s)
 local s = tostring(s)
 return s:gsub(".", function(c) return escapeList[c] end) -- SoniEx2: 5.0 compat
end

-- Determines whether the given Lua type is an array or a table / dictionary.
-- We consider any table an array if it has indexes 1..n for its n items, and no
-- other data in the table.
-- I think this method is currently a little 'flaky', but can't think of a good way around it yet...
-- @param t The table to evaluate as an array
-- @return boolean, number True if the table can be represented as an array, false otherwise. If true,
-- the second returned value is the maximum
-- number of indexed elements in the array. 
function isArray(t)
  -- Next we count all the elements, ensuring that any non-indexed elements are not-encodable 
  -- (with the possible exception of 'n')
  local maxIndex = 0
  for k,v in pairs(t) do
    if (type(k)=='number' and math.floor(k)==k and 1<=k) then	-- k,v is an indexed pair
      if (not isEncodable(v)) then return false end	-- All array elements must be encodable
      maxIndex = math.max(maxIndex,k)
    else
      if (k=='n') then
        if v ~= table.getn(t) then return false end  -- False if n does not hold the number of elements
      else -- Else of (k=='n')
        if isEncodable(v) then return false end
      end  -- End of (k~='n')
    end -- End of k,v not an indexed pair
  end  -- End of loop across all pairs
  return true, maxIndex
end

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

--- Determines whether the given Lua object / table / variable can be JSON encoded. The only
-- types that are JSON encodable are: string, boolean, number, nil, table and json.null.
-- In this implementation, all other types are ignored.
-- @param o The object to examine.
-- @return boolean True if the object should be JSON encoded, false if it should be ignored.
function isEncodable(o)
  local t = type(o)
  return (t=='string' or t=='boolean' or t=='number' or t=='nil' or t=='table') or (t=='function' and o==null) 
end

return json