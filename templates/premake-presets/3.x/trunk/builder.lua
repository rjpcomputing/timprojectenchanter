#!/usr/bin/env lua
-- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		11/24/2009
--	Version:	1.00
--
--	Copyright (C) 2009 Ryan Pusztai
--
--	Permission is hereby granted, free of charge, to any person obtaining a copy
--	of this software and associated documentation files (the "Software"), to deal
--	in the Software without restriction, including without limitation the rights
--	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--	copies of the Software, and to permit persons to whom the Software is
--	furnished to do so, subject to the following conditions:
--
--	The above copyright notice and this permission notice shall be included in
--	all copies or substantial portions of the Software.
--
--	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
--	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--	THE SOFTWARE.
--
--	NOTES:
--        For Visual C++ Express editions you need to drop a copy of
--        VCExpress.com in the <vc_install>\Common7\IDE directory.
--        Find it on \\znas2\electrical\User\Tester\rpusztai\Code\IDEs\Visual Studio\VS9
-- ----------------------------------------------------------------------------
require( "lfs" )

--[=[ Check for help commandline argument.
if arg[1] == "help" or arg[1] == "--help" or arg[1] == "-h" then
	print( "builder.lua - CI Build helper v2.00" )
	print( "Usage: lua builder.lua [target [config [buildfile_options]]] | help" )
	print( "", "target",	"What builder (Compiler/IDE) to invoke." )
	print( "", "config",	"What configuration to build. Available options are 'Release' and 'Debug'." )
	print( "", "buildfile_options",	"Options to pass to Premake to control project file generation. Ex: '--verbose'." )
	print( "", "help",		"Displays this message and exits" )
	return
end

local target = arg[1] or "gnu"
target = target:lower()
local config = arg[2] or "Release"
local buildfile_options = arg[3] or ""
]=]
-- HELPER FUNCTIONS -----------------------------------------------------------
--

function IsWindows()
	local sep = package.config:sub( 1, 1 )
	return sep == "\\"
end

function IsPosix()
	return not IsWindows()
end

-- Defaults to two processors
local function GetNumberOfProcessors()
	local numOfProcessors = "2"

	if IsWindows() then
		numOfProcessors = os.getenv( "NUMBER_OF_PROCESSOR" ) or numOfProcessors
	else
		local procHandle = io.popen( "grep -c processor /proc/cpuinfo" )
		numOfProcessors = procHandle:read( "*a" ) or numOfProcessors
		procHandle:close()
	end

	return numOfProcessors
end

-- Lua command line option parser.
-- Interface based on Pythons optparse.
-- http://docs.python.org/lib/module-optparse.html
-- (c) 2008 David Manura, Licensed under the same terms as Lua (MIT license)
--
-- To be used like this:
-- t={usage="<some usage message>", version="<version string>"}
-- op=OptionParser(t)
-- op=add_option{"<opt>", action=<action>, dest=<dest>, help="<help message for this option>"}
--
-- with :
--   <opt> the option string to be used (can be anything, if one letter opt, then should be -x val, more letters: -xy=val )
--   <action> one of
--   - store: store in options as key, val
--   - store_true: stores key, true
--   - store_false: stores key, false
--   <dest> is the key under which the option is saved
--
-- options,args = op.parse_args()
--
-- now options is the table of options (key, val) and args is the table with non-option arguments.
-- You can use op.fail(message) for failing and op.print_help() for printing the usage as you like.

local function OptionParser(t)
	local usage = t.usage
	local version = t.version

	local o = {}
	local option_descriptions = {}
	local option_of = {}

	function o.fail(s) -- extension
		io.stderr:write(s .. '\n')
		os.exit(1)
	end

	function o.add_option( optdesc )
		option_descriptions[#option_descriptions + 1] = optdesc
		for _,v in ipairs( optdesc ) do
			option_of[v] = optdesc
		end
	end

	function o.parse_args()
		-- expand options (e.g. "--input=file" -> "--input", "file")
		local arg = { unpack( arg ) }
		for i=#arg,1,-1 do local v = arg[i]
			local flag, val = v:match( '^(%-%-%w+)=(.*)' )
			if flag then
				arg[i] = flag
				table.insert( arg, i+1, val )
			end
		end

		local options = {}
		local args = {}
		local i = 1
		while i <= #arg do local v = arg[i]
			local optdesc = option_of[v]
			if optdesc then
				local action = optdesc.action
				local val

				if action == 'store' or action == nil then
					i = i + 1
					val = arg[i]
					if not val then o.fail('option requires an argument ' .. v) end
				elseif action == 'store_true' then
					val = true
				elseif action == 'store_false' then
					val = false
				end

				options[optdesc.dest] = val
			else
				if v:match('^%-') then o.fail('invalid option ' .. v) end
				args[#args+1] = v
			end
				i = i + 1
		end

		if options.help then
			o.print_help()
			os.exit()
		end

		if options.version then
			io.stdout:write(t.version .. "\n")
			os.exit()
		end

		return options, args
	end

	local function flags_str(optdesc)
		local sflags = {}
		local action = optdesc.action
		for _,flag in ipairs(optdesc) do
			local sflagend
			if action == nil or action == 'store' then
				local metavar = optdesc.metavar or optdesc.dest:upper()
				sflagend = #flag == 2 and ' ' .. metavar
									  or  '=' .. metavar
			else
				sflagend = ''
			end

			sflags[#sflags+1] = flag .. sflagend
		end

		return table.concat(sflags, ', ')
	end

	function o.print_help()
		io.stdout:write("Usage: " .. usage:gsub('%%prog', arg[0]) .. "\n")
		io.stdout:write("\n")
		io.stdout:write("Options:\n")
		local pad = 0
		for _,optdesc in ipairs(option_descriptions) do
			pad = math.max( pad, #flags_str(optdesc) )
		end
		for _,optdesc in ipairs( option_descriptions ) do
			io.stdout:write("  " .. flags_str( optdesc ) .. string.rep(' ', pad - #flags_str(optdesc)) .. "  " .. optdesc.help .. "\n")
		end
	end

	o.add_option{ "--help", action = "store_true", dest = "help",
					help = "show this help message and exit" }
	if t.version then
		o.add_option{ "--version", action = "store_true", dest = "version",
						help = "output version info." }
	end

	return o
end

---	Looks if a single key is in a table.
--	@param tbl Table to seach in.
--	@param key String of the key to find in tbl.
local function ContainsKey( tbl, key )
	if tbl then
		for k, _ in pairs( tbl ) do
			if type( k ) == "table" then
				if true == ContainsKey( k, key ) then
					return true
				end
			else
				if k == key then
					return true
				end
			end
		end
	end

	return false
end

---	Looks if a single key is in a table.
--	@param tbl Table to seach in.
--	@param key String of the key to find in tbl.
local function ContainsValue( tbl, value )
	for _, val in pairs( tbl ) do
		if type( val ) == "table" then
			if true == ContainsValue( val, value ) then
				return true
			end
		else
			if val == value then
				return true
			end
		end
	end

	return false
end

---	Looks if a single value is in a table.
--	@param tbl Table to seach in.
--	@param value String of the value to find in tbl.
local function iContainsEntry( tbl, value )
	for _, val in ipairs( tbl ) do
		if type( val ) == "table" then
			if true == iContainsEntry( val, value ) then
				return true
			end
		else
			if val == value then
				return true
			end
		end
	end

	return false
end

---	Checks for the existance of a file.
--	@param fileName The file path and name as a string.
--	@return True if the file exists, else false.
local function FileExists( fileName )
	local file = io.open( fileName )
	if file then
		io.close( file )
		return true
	else
		return false
	end
end

---	Finds the first file matching the pattern and returns it.
--	@param
--	@returns nil if not found, else the file path first found.
local function FindFirstFile( path, pattern )
    for file in lfs.dir( path ) do
        if file ~= "." and file ~= ".." then
            local f = path.."/"..file
            --print( "\t "..f )
            local attr = lfs.attributes( f )
            assert ( type( attr ) == "table" )
            if attr.mode == "directory" then
                FindFirstFile( f, pattern )
            else
				if f:find( pattern ) then
					return f
				end
            end
        end
    end

	return nil
end

-- BUILDER FUNCTIONS ----------------------------------------------------------
--
---	Launch Premake to generate the project files.
local function GenerateProjectFiles( tget )
	if type( tget ) ~= "string" then
		error( "bad argument #1 to GenerateProjectFiles. (Expected string but recieved "..type( tget )..")" )
	end

	local premakeRet = os.execute( "premake "..buildfile_options.." --target "..tget )
	--print( "Premake process exited with code "..( premakeRet or "<nil>" ) )
	if premakeRet ~= 0 then
		print( string.format( "Premake error (%i) occured.", premakeRet ) )
		os.exit( premakeRet )
	end
	print( "" )
end

local function ExecuteGnuBuilder( cfg )
	print( "Make Builder invoked." ); io.stdout:flush()
	--io.stdout:write( "Make Builder invoked.\n" )
	--io.stdout:flush()
	if type( cfg ) ~= "string" then
		error( "bad argument #1 to ExecuteGnuBuilder. (Expected string but recieved "..type( cfg )..")" )
	end
	local multiProccessorFlag = " -j "..GetNumberOfProcessors()
	-- Launch make to build
	local makeCmd = "make CONFIG="..cfg..multiProccessorFlag
	if IsWindows() then
		makeCmd = "mingw32-make CONFIG="..cfg..multiProccessorFlag
	end
	print( makeCmd ); io.stdout:flush()
	--io.stdout:write( makeCmd.."\n" )
	--io.stdout:flush()
	local makeRet = os.execute( makeCmd )
	--print( "Make process exited with code "..( makeRet or "<nil>" ) )
	if makeRet ~= 0 then
		print( string.format( "Make error (%i) occured. Converted exit code to 1", makeRet ) )
		os.exit( 1 )
	end
end

local function ExecuteVs2005Builder( cfg )
	-- Check parameters
	if type( cfg ) ~= "string" then
		error( "bad argument #1 to ExecuteVs2008Builder. (Expected string but recieved "..type( cfg )..")" )
	end

	print( "VS2005 Builder invoked." ); io.stdout:flush()

	-- Determine Visual Studio path
	local vsPath = os.getenv( "VS80COMNTOOLS" ).."..\\IDE\\devenv.com"
	print( vsPath ); io.stdout:flush()

	if not FileExists( vsPath ) then
		vsPath = os.getenv( "VS80COMNTOOLS" ).."..\\IDE\\VCExpress.com"
		-- Make sure that exists
		if not FileExists( vsPath ) then
			error( "Microsoft Visual C++ 2005 (8.0) is not installed on this machine." )
		end
	end

	-- Find solution file
	local solutionFile = FindFirstFile( ".", ".sln" )
	print( "Running solution "..solutionFile ); io.stdout:flush()

	if not solutionFile then
		error( "No VS2005 solution file found. Make sure the project files are generated." )
	end

	-- Launch vc to build
	local buildString = string.format( '""%s" "%s" /build %s"', vsPath, solutionFile, cfg )
	local vsRet = os.execute( buildString )
	--print( "VS2005 process exited with code "..( vsRet or "<nil>" ) )
	if vsRet ~= 0 then
		print( string.format( "VS2005 error (%i) occured. Converted exit code to 1", vcRet or -1 ) )
		os.exit( 1 )
	end
end

local function ExecuteVs2008Builder( cfg )
	-- Check parameters
	if type( cfg ) ~= "string" then
		error( "bad argument #1 to ExecuteVs2008Builder. (Expected string but recieved "..type( cfg )..")" )
	end

	print( "VS2008 Builder invoked." ); io.stdout:flush()

	-- Determine Visual Studio path
	local vsPath = os.getenv( "VS90COMNTOOLS" ).."..\\IDE\\devenv.com"
	print( vsPath ); io.stdout:flush()
	if not FileExists( vsPath ) then
		vsPath = os.getenv( "VS90COMNTOOLS" ).."..\\IDE\\VCExpress.com"
		-- Make sure that exists
		if not FileExists( vsPath ) then
			error( "Microsoft Visual C++ 2008 (9.0) is not installed on this machine." )
		end
	end

	-- Find solution file
	local solutionFile = FindFirstFile( ".", ".sln" )
	print( "Running solution "..solutionFile ); io.stdout:flush()
	if not solutionFile then
		error( "No VS2008 solution file found. Make sure the project files are generated." )
	end

	-- Launch vc to build
	local buildString = string.format( '""%s" "%s" /build %s"', vsPath, solutionFile, cfg )
	local vsRet = os.execute( buildString )
	--print( "VS2008 process exited with code "..( vsRet or "<nil>" ) )
	if vsRet ~= 0 then
		print( string.format( "VS2008 error (%i) occured. Converted exit code to 1", vcRet or -1 ) )
		os.exit( 1 )
	end
end


local function ExecuteINNOBuilder( file )
	print( "INNO Setup Installer Builder invoked." ); io.stdout:flush()

	if type( file ) ~= "string" then
		error( "bad argument #1 to ExecuteINNOBuilder. (Expected string but recieved "..type( file )..")" )
	end

	-- Launch INNO Setup command line compiler to build the installer.
	local installerCmd = ""
	if IsWindows() then
		installerCmd = string.format( [[C:\Program Files\Inno Setup 5\ISCC.exe %q]], file )
		print( installerCmd ); io.stdout:flush()

		local installerRet = os.execute( installerCmd )

		print( "INNO process exited with code "..( installerRet or "<nil>" ) )

		if installerRet ~= 0 then
			print( string.format( "INNO error (%i) occured. Converted exit code to 1", installerRet ) )
			os.exit( 1 )
		end
	else
		print( "Only Windows is supported right now." )
		return
	end
end

local function ExecuteNSISBuilder( file )
	print( "NSIS Installer Builder invoked." ); io.stdout:flush()

	if type( file ) ~= "string" then
		error( "bad argument #1 to ExecuteNSISBuilder. (Expected string but recieved "..type( file )..")" )
	end

	-- Launch NSIS command line compiler to build the installer.
	local installerCmd = ""
	if IsWindows() then
		installerCmd = string.format( [["C:\Program Files\NSIS\makensis.exe" /V2 %q]], file )
		print( installerCmd ); io.stdout:flush()

		local installerRet = os.execute( installerCmd )

		print( "NSIS process exited with code "..( installerRet or "<nil>" ) )

		if installerRet ~= 0 then
			print( string.format( "NSIS error (%i) occured. Converted exit code to 1", installerRet ) )
			os.exit( 1 )
		end
	else
		print( "Only Windows is supported right now." )
		return
	end
end

function LoadConfigurationFile( file )
	if FileExists( file ) then
		dofile( file )
	else
		print( "WARNING: Did not find a configuration file, only the defaults will be used." )
	end
end

-- Main builder class.
local Builder =
{
	configurations =
	{
		["GCC.Release"] =
		{
			target				= "gnu",
			config				= "Release",
			buildFileOptions	= "",
			installer			= "",
			installerSourceFile	= "",
		},
		["GCC.Debug"] =
		{
			target				= "gnu",
			config				= "Debug",
			buildFileOptions	= "",
			installer			= "",
			installerSourceFile	= "",
		},
		["VS2005.Release"] =
		{
			target				= "vs2005",
			config				= "Release",
			buildFileOptions	= "",
			installer			= "",
			installerSourceFile	= "",
		},
		["VS2005.Debug"] =
		{
			target				= "vs2005",
			config				= "Debug",
			buildFileOptions	= "",
			installer			= "",
			installerSourceFile	= "",
		},
		["VS2008.Release"] =
		{
			target				= "vs2008",
			config				= "Release",
			buildFileOptions	= "",
			installer			= "",
			installerSourceFile	= "",
		},
		["VS2008.Debug"] =
		{
			target				= "vs2008",
			config				= "Debug",
			buildFileOptions	= "",
			installer			= "",
			installerSourceFile	= "",
		},
	},
	-- Add more installers here to make them available as builders.
	installerBuilders =
	{
		inno	= ExecuteINNOBuilder,
		nsis	= ExecuteNSISBuilder,
	},
	-- Add more targets here to make them available as builders.
	targetBuilders =
	{
		gnu		= ExecuteGnuBuilder,
		vs2005	= ExecuteVs2005Builder,
		vs2008	= ExecuteVs2008Builder,
	}
}

-- MAIN ENTRY POINT ------------------------------------------------------------
--
function main()
	-- Setup the build options.
	op = OptionParser{ usage="builder.lua config [settings_file] | --help", version="1.00-Alpha" }
	op.add_option{ "--file", action = "store", dest="settings_file", help="Path to the settings file to use. (Defaults to BuildSettings.lua)" }
	local options, args = op.parse_args()

	-- Check to make sure the required arguments are
	if #args == 0 then
		local availableConfigurations = {}
		for k, _ in pairs( Builder.configurations ) do table.insert( availableConfigurations, k ) end
		error( "No configuration was supplied. Please make sure to specify a configuration to run. Available built-in configurations are "..table.concat( (availableConfigurations or {} ), ", " ) )
	end

for k, v in pairs( args ) do print( "Script arguments:" ); print( "", k, v ) end
for k, v in pairs( options ) do print( "Options:" ); print( "", k, v ) end

	-- Load the configuration file
	local config = LoadConfigurationFile( options.file or "BuildSettings.lua" )

	-- Check to see if the configuration supplied exists.
	if not ContainsKey( Builder.configurations, args[1] ) then
		local availableConfigurations = {}
		for k, _ in pairs( Builder.configurations ) do table.insert( availableConfigurations, k ) end
		error( "No matching configuration found. Check to make sure that you spelled and passed the correct one on the command line. Available configurations are "..table.concat( (availableConfigurations or {} ), ", " ) )
	end

	-- Check to see if it is an available builder.
	if not ContainsKey( Builder.targetBuilders, target ) then
		local availableTargets = {}
		for k, _ in pairs( Builder.targetBuilders ) do table.insert( availableTargets, k ) end
		error( "Unsupported target specified. Available targets are "..table.concat( availableTargets, ", " ) )
	end

	-- Generate the required build files.
	--GenerateProjectFiles( target )

	-- Launch the correct Builder.
	--targetBuilders[target]( config )
end

if not _LEXECUTOR then
	main()
end
