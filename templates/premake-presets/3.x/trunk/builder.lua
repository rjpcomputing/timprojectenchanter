#!/usr/bin/env lua
-- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		02/09/2010
--	Version:	1.10
--
--	Copyright (C) 2010 Ryan Pusztai
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
require( "pl.lapp" )
require( "pl.path" )
require( "pl.dir" )

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
		numOfProcessors = os.getenv( "NUMBER_OF_PROCESSORS" ) or numOfProcessors
	else
		local procHandle = io.popen( "grep -c processor /proc/cpuinfo" )
		numOfProcessors = procHandle:read( "*n" ) or numOfProcessors
		procHandle:close()
	end

	return numOfProcessors
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

---	Removes all files in the current working directory using the supplied pattern.
--	@param pattern The file pattern to remove.
local function RemoveAll( pattern )
	local files = pl.dir.getfiles( ".", pattern )
	for _, file in ipairs( files )do
		print( "Cleaning old file:", file )
		os.remove( file )
	end
end

-- BUILDER FUNCTIONS ----------------------------------------------------------
--
---	Launch Premake to generate the project files.
local function GenerateProjectFiles( tget, options, args, shouldUsePremake4 )
	if type( tget ) ~= "string" then
		error( "bad argument #1 to GenerateProjectFiles. (Expected string but recieved "..type( tget )..")" )
	end
	if type( args ) ~= "string" then
		error( "bad argument #2 to GenerateProjectFiles. (Expected string but recieved "..type( args )..")" )
	end

	local premakeRet = -1
	local suffix = ""
	if IsWindows() then
		suffix = ".exe"
	end
	if shouldUsePremake4 then
		local premakeCmd = "premake4" .. suffix .. " " .. options .. " " .. tget .. " " .. args
		print( premakeCmd ); io.stdout:flush()
		premakeRet = os.execute( premakeCmd )
	else
		local premakeCmd = "premake" .. suffix .. " --target " .. tget .. " " .. options .. " " .. args
		print( premakeCmd ); io.stdout:flush()
		premakeRet = os.execute( premakeCmd )
	end

	if premakeRet ~= 0 then
		print( string.format( "Premake error (%i) occured.", premakeRet ) )
		os.exit( premakeRet )
	end
	print( "" )
end

local function ExecuteGnuBuilder( cfg, shouldClean, premake4makefiles )
	-- Check parameters
	if type( cfg ) ~= "string" then
		error( "bad argument #1 to ExecuteGnuBuilder. (Expected string but recieved "..type( cfg )..")" )
	end
	shouldClean = shouldClean or false

	print( "Make Builder invoked." ); io.stdout:flush()

	-- Launch make to build
	local make = "make"
	if IsWindows() then
		make = "mingw32-make"
	end

	local configLabel = "CONFIG"
	if premake4makefiles then
		configLabel = "config"
		cfg = string.lower( cfg )
	end

	-- Launch make to clean
	if shouldClean then
		local cleanCmd = string.format( "%s %s=%s clean", make, configLabel, cfg )
		print( cleanCmd ); io.stdout:flush()
		local makeRet = os.execute( cleanCmd )
		if makeRet ~= 0 then
			print( string.format( "Make clean error (%i) occured. Converted exit code to 1", makeRet ) )
			os.exit( 1 )
		end
	end

	-- Launch make to build
	local makeCmd = ""
	if IsWindows() then
		makeCmd = string.format( "%s -j %s %s=%s", make, GetNumberOfProcessors(), configLabel, cfg )
	else
		makeCmd = string.format( "%s %s=%s", make, configLabel, cfg )
	end
	print( makeCmd ); io.stdout:flush()
	local makeRet = os.execute( makeCmd )
	if makeRet ~= 0 then
		print( string.format( "Make error (%i) occured. Converted exit code to 1", makeRet ) )
		os.exit( 1 )
	end
end

local function ExecuteGmakeBuilder( cfg, shouldClean )
	ExecuteGnuBuilder( cfg, shouldClean, true )
end

local function ExecuteVs2005Builder( cfg, shouldClean )
	-- Check parameters
	if type( cfg ) ~= "string" then
		error( "bad argument #1 to ExecuteVs2005Builder. (Expected string but recieved "..type( cfg )..")" )
	end
	shouldClean = shouldClean or false

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
	if not solutionFile then
		error( "No VS2005 solution file found. Make sure the project files are generated." )
	end
	print( "Using solution "..solutionFile ); io.stdout:flush()

	-- Launch vc to clean
	if shouldClean then
		print( "Cleaning solution..." ); io.stdout:flush()
		local cleanCmd = string.format( '""%s" "%s" /clean %s"', vsPath, solutionFile, cfg )
		local vsRet = os.execute( cleanCmd )
		--print( "VS2005 clean process exited with code "..( vsRet or "<nil>" ) )
		if vsRet ~= 0 then
			print( string.format( "VS2005 clean error (%i) occured. Converted exit code to 1", vcRet or -1 ) )
			os.exit( 1 )
		end
	end

	-- Launch vc to build
	print( "Building solution..." ); io.stdout:flush()
	local buildCmd = string.format( '""%s" "%s" /build %s"', vsPath, solutionFile, cfg )
	local vsRet = os.execute( buildCmd )
	--print( "VS2005 build process exited with code "..( vsRet or "<nil>" ) )
	if vsRet ~= 0 then
		print( string.format( "VS2005 build error (%i) occured. Converted exit code to 1", vcRet or -1 ) )
		os.exit( 1 )
	end
end

local function ExecuteVs2008Builder( cfg, shouldClean )
	-- Check parameters
	if type( cfg ) ~= "string" then
		error( "bad argument #1 to ExecuteVs2008Builder. (Expected string but recieved "..type( cfg )..")" )
	end
	shouldClean = shouldClean or false

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
	if not solutionFile then
		error( "No VS2008 solution file found. Make sure the project files are generated." )
	end
	print( "Using solution "..solutionFile ); io.stdout:flush()

	-- Launch vc to clean
	if shouldClean then
		print( "Cleaning solution..." ); io.stdout:flush()
		local cleanCmd = string.format( '""%s" "%s" /clean %s"', vsPath, solutionFile, cfg )
		local vsRet = os.execute( cleanCmd )
		--print( "VS2008 clean process exited with code "..( vsRet or "<nil>" ) )
		if vsRet ~= 0 then
			print( string.format( "VS2008 clean error (%i) occured. Converted exit code to 1", vcRet or -1 ) )
			os.exit( 1 )
		end
	end

	-- Launch vc to build
	print( "Building solution..." ); io.stdout:flush()
	local buildString = string.format( '""%s" "%s" /build %s"', vsPath, solutionFile, cfg )
	local vsRet = os.execute( buildString )
	--print( "VS2008 build process exited with code "..( vsRet or "<nil>" ) )
	if vsRet ~= 0 then
		print( string.format( "VS2008 build error (%i) occured. Converted exit code to 1", vcRet or -1 ) )
		os.exit( 1 )
	end
end


local function ExecuteINNOBuilder( file )
	print( "INNO Setup Installer Builder invoked." ); io.stdout:flush()
	-- Get the current working directory so we can restore it after the work is done.
	local curDir = lfs.currentdir()

	if type( file ) ~= "string" then
		error( "bad argument #1 to ExecuteINNOBuilder. (Expected string but recieved "..type( file )..")" )
	end

	-- Change the directory to the installer file directory.
	lfs.chdir( pl.path.dirname( file ) )

	-- Launch INNO Setup command line compiler to build the installer.
	local installerCmd = ""
	if IsWindows() then
		-- Clean all old installer files.
		RemoveAll( "*.exe" )
		RemoveAll( "output/*.exe" )
		local innoPath = os.getenv( "PROGRAMFILES" ) .. [[\Inno Setup 5\ISCC.exe]]
		installerCmd = string.format( [[""%s" %q"]], innoPath, pl.path.basename( file ) )
		print( installerCmd ); io.stdout:flush()

		local installerRet = os.execute( installerCmd )

		print( "INNO process exited with code "..( installerRet or "<nil>" ) )

		if installerRet ~= 0 then
			lfs.chdir( curDir )
			print( string.format( "INNO error (%i) occured. Converted exit code to 1", installerRet ) )
			os.exit( 1 )
		end
	else
		print( "Only Windows is supported right now." )
		-- Clean all old installer files.
		RemoveAll( "*.deb" )
	end

	lfs.chdir( curDir )
end

local function ExecuteNSISBuilder( file )
	print( "NSIS Installer Builder invoked." ); io.stdout:flush()

	-- Get the current working directory so we can restore it after the work is done.
	local curDir = lfs.currentdir()

	if type( file ) ~= "string" then
		error( "bad argument #1 to ExecuteNSISBuilder. (Expected string but recieved "..type( file )..")" )
	end

	-- Change the directory to the installer file directory.
	lfs.chdir( pl.path.dirname( file ) )

	-- Launch NSIS command line compiler to build the installer.
	local installerCmd = ""
	if IsWindows() then
		installerCmd = string.format( [["C:\Program Files\NSIS\makensis.exe" /V2 %q]], file )
		print( installerCmd ); io.stdout:flush()

		local installerRet = os.execute( installerCmd )

		print( "NSIS process exited with code "..( installerRet or "<nil>" ) )

		if installerRet ~= 0 then
			lfs.chdir( curDir )
			print( string.format( "NSIS error (%i) occured. Converted exit code to 1", installerRet ) )
			os.exit( 1 )
		end
	else
		print( "Only Windows is supported right now." )
	end

	lfs.chdir( curDir )
end

Targets =
{
  gnu = ExecuteGnuBuilder,
  vs2005 = ExecuteVs2005Builder,
  vs2008 = ExecuteVs2008Builder,
  gmake = ExecuteGmakeBuilder
}

Installers =
{
  inno = ExecuteINNOBuilder,
  nsis = ExecuteNSISBuilder
}

function main()
	local args = pl.lapp [[
	Builds the current project. Run from the root level.

	-t,--target         (string)            One of the following: vs2005, vs2008, or gnu.
	-b,--build          (default Release)   Project-specific build configuration, usually Debug or Release.
	-i,--installer      (default none)      One of the following: inno or nsis.
	-f,--installerfile  (default none)      The installer source file to pass to the installer, if needed.
	-p,--premake        (default none)      Extra options passed on to premake.
	-m,--teamcity       (default true)      Enable teamcity output.
	-c,--clean                              Clean project sources before building.
	-q,--premake4                           Use premake4
	]]

	-- Setup the build configuration
	local build = args.build or ""

	-- Setup if the build should clean first
	local shouldClean = args.clean

	-- Setup the installer support
	local installer = nil
	local installerFile = nil
	if args.installer and args.installer ~= "none" then
		installer = args.installer or ""
		if not ContainsKey( Installers, installer ) then
		  error( "Invalid installer: " .. installer )
		end
		if args.installerfile and args.installerfile ~= "none" then
		  installerFile = args.installerfile
		end
	end

	-- Setup the Premake extra arguments
	local premakeOptions = ""
	if args.premake and args.premake ~= "none" then
		premakeOptions = args.premake
	end

	local premakeArgs = ""
	if args.teamcity and args.teamcity ~= "false" then
		if args.premake4 then
			premakeArgs = "teamcity"
		else
			premakeArgs = "--teamcity"
		end
	end

	-- Generate the project files
	local target = args.target or "none"
	if target ~= "none" then
		if not ContainsKey( Targets, target ) then
			error( "Invalid target: " .. target )
		end

		GenerateProjectFiles( target, premakeOptions, premakeArgs, args.premake4 )

		-- Actually build project
		Targets[ target ]( build, shouldClean )
	end

	-- Optionally build the installer
	if installer then
		Installers[ installer ]( installerFile )
	end
end

if not _LEXECUTOR then
	main()
end
