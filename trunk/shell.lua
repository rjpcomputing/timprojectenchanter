-- shell.lua
shell = {}
local mt = {}
setmetatable( shell, mt )

local function GetPathSeparator()
	os.pathsep = package.config:sub(1,1)
	return os.pathsep
end

local function IsWindows()
	return GetPathSeparator() == "\\"
end

local function IsPosix()
	return not IsWindows()
end

function shell.command( cmd, no_lf )
	-- Echo command to run.
	print( ">>> "..cmd )
	
	-- Run the command and redirect both the stderr and stdout
	local cmdAddition
	if IsWindows() then
		cmdAddition = ' 2>&1 & echo "-retcode:%ERRORLEVEL%"'
	else
		cmdAddition = ' 2>&1; echo "-retcode:$?"'
	end
	
	local procHandle = io.popen( cmd..cmdAddition, "r" )
	local procOutput = procHandle:read( "*a" )
	procHandle:close()
	
	-- Find the return code.
	local i1, i2, ret = procOutput:find( "%-retcode:(%d+)\n$" )
	if no_lf and i1 > 1 then i1 = i1 - 1 end
	procOutput = procOutput:sub( 1, i1 - 1 )
	
	-- Return the <return_code> and <command_output>
	return tonumber( ret ), procOutput
end

local function concat( args )
   for i, s in ipairs( args ) do
       if type( s ) == "table" then
           args[i] = concat( s )
       else
           args[i] = s:find( "%s" ) and '"'..s..'"' or s
       end
   end
   
   return table.concat( args, " " )
end

function mt.__index( t, k )
   return function( ... )
       return shell.command( k.." "..concat( {...} ), false )
   end
end
