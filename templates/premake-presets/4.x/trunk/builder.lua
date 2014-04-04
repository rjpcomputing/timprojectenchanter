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
local lapp = require( "pl.lapp" )
local path = require( "pl.path" )
local dir = require( "pl.dir" )

-- HELPER FUNCTIONS -----------------------------------------------------------
--

function IsWindows()
	local sep = package.config:sub( 1, 1 )
	return sep == "\\"
end

function IsPosix()
	return not IsWindows()
end

function GccRoot()
	if not IsWindows() then
		return ""
	end
	
	local gccRoot = os.getenv( "GCC_ROOT" )
	if not gccRoot then
		gccRoot = "C:\\MinGW4"
	end
	if not path.exists( gccRoot ) then
		error( "No valid GCC installed at'" .. gccRoot .. "', make sure the environment variable 'GCC_ROOT' points to a valid GCC installation" )
	end
	return gccRoot
end

function GccBinDir()
	if not IsWindows() then
		return ""
	end
	
	return presets.GccRoot() .. "\\bin\\"
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
            --print( "\t "..f ); io.stdout:flush()
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
	local files = dir.getfiles( ".", pattern )
	for _, file in ipairs( files )do
		print( "Cleaning old file:", file ); io.stdout:flush()
		os.remove( file )
	end
end

-- BUILDER FUNCTIONS ----------------------------------------------------------
--

local function ExecuteCommand( commandLine )
	print( commandLine ); io.stdout:flush()
	local returnCode = os.execute( commandLine )

	if returnCode ~= 0 then
		print( string.format( "Error (%i) occured. Converted exit code to 1. Failed Command Line: " .. commandLine, returnCode or -1 ) ); io.stdout:flush()
		os.exit( 1 )
	end
end

---	Launch Premake to generate the project files.
local function GenerateProjectFiles( tget, options, args )
	if type( tget ) ~= "string" then
		error( "bad argument #1 to GenerateProjectFiles. (Expected string but received "..type( tget )..")" )
	end
	if type( args ) ~= "string" then
		error( "bad argument #2 to GenerateProjectFiles. (Expected string but received "..type( args )..")" )
	end

	local suffix = ""
	if IsWindows() then
		suffix = ".exe"
	end
	
	ExecuteCommand( "premake4" .. suffix .. " " .. options .. " " .. tget .. " " .. args )
	
	print( "" ); io.stdout:flush()
end

local function ExecuteGnuBuilder( cfg, shouldClean, premake4makefiles, platform )
	-- Check parameters
	if type( cfg ) ~= "string" then
		error( "bad argument #1 to ExecuteGnuBuilder. (Expected string but received "..type( cfg )..")" )
	end
	shouldClean = shouldClean or false

	print( "Make Builder invoked." ); io.stdout:flush()

	local make = "make"
	if IsWindows() then
		make = GccRoot() .. "\\mingwvars.bat /k && mingw32-make"
	end

	cfg = string.lower( cfg )
	if platform then
		cfg = cfg .. platform:sub( 2 )
	end

	-- Launch make to clean
	if shouldClean then
		ExecuteCommand( string.format( "%s config=%s clean", make, cfg ) )		
	end

	-- Launch make to build
	ExecuteCommand( string.format( "%s config=%s", make, cfg ) )	
end

local function ExecuteGmakeBuilder( cfg, shouldClean, platform )
	ExecuteGnuBuilder( cfg, shouldClean, true, platform )
end

local function ShouldUseMSBuild( year )
	return tonumber( year ) >= 2010
end

local function GetRegistryEntry( keyName, valueName )
	regValue = assert( io.popen( [[reg query "]] .. keyName .. [[" /v "]] .. valueName ..[["]] ) )
	  
	local value
	for line in regValue:lines() do
		value = line:match( valueName .. "%s+REG_[%u_]+%s+(.+)" )
		if value then
			break
		end
	end

	regValue:close()
	
	return value
end

local function GetMSBuildPath()
	local msBuildPath = os.getenv( "PROGRAMFILES" ) .. [[\MSBuild\12.0\bin\MSBuild.exe]]
	if path.exists( msBuildPath ) then
		return msBuildPath
	end
	
	local registryPath = [[HKLM\software\wow6432node\microsoft\visualstudio\sxs\vc7]]
	local rootPath = GetRegistryEntry( registryPath, "FrameworkDir32" )
	if not rootPath then
		registryPath = [[HKLM\software\microsoft\visualstudio\sxs\vc7]]
		rootPath = GetRegistryEntry( registryPath, "FrameworkDir32" )
	end
	
	if not rootPath then
		error( "Unable to locate MSBuild path in the registry" )
	end
	
	local version = GetRegistryEntry( registryPath, "FrameworkVer32" )
	if not version then
		error( "Unable to locate MSBuild version in the registry" )
	end
	
	return rootPath .. version .. [[\MSBuild.exe]]
end

local function FindVsRunner( solutionFile, cfg, platform, year, version )	
	local vsEnv = os.getenv( "VS" .. version .. "0COMNTOOLS" )
	if not vsEnv then
		error( "Microsoft Visual C++ " .. year .. " (" .. version .. ".0) is not installed on this machine." )
	end

	local runner = 	{
						path = "",
						cleanCmdFormat = "",
						buildCmdFormat = ""
					}
					
	if ShouldUseMSBuild( year ) then
		runner.path = GetMSBuildPath()
		local baseCmd = string.format( '"%s" "%s" /verbosity:normal /property:Configuration=%s;_IsNativeEnvironment=false', runner.path, solutionFile, cfg )
		if platform then
			baseCmd = baseCmd .. ";Platform=" .. platform .. ""
		end
		runner.cleanCmd = '"' .. baseCmd .. ' /target:Clean"'
		runner.buildCmd = '"' .. baseCmd .. '"'
	else		
		runner.path = vsEnv .. [[..\IDE\devenv.com]]
		
		if not FileExists( runner.path ) then
			runner.path = vsEnv .. [[..\IDE\VCExpress.com]]
		end
		
		if not FileExists( runner.path ) then
			error ( "Neither devenv.com nor VCExpress.com were found in " .. vsEnv .. [[..\IDE\]] )
		end
		
		if platform then
			cfg = cfg .. "|" .. platform
		end
		
		runner.cleanCmd = string.format( '""%s" "%s" /clean "%s""', runner.path, solutionFile, cfg )
		runner.buildCmd = string.format( '""%s" "%s" /build "%s""', runner.path, solutionFile, cfg )
	end
		
	print( "VS Runner: " .. runner.path ); io.stdout:flush()
	
	return runner
end

local function FindSolutionFile()
	local solutionFile = FindFirstFile( ".", ".sln" )
	if not solutionFile then
		error( "No Visual Studio solution file found. Make sure the project files are generated." )
	end
	print( "Using solution "..solutionFile ); io.stdout:flush()
	return solutionFile
end

local function ExecuteVsBuilder( cfg, shouldClean, platform, year, version )
	
	print( "VS" .. year .. " Builder invoked." ); io.stdout:flush()
	
	if type( cfg ) ~= "string" then
		error( "bad argument #1 to ExecuteVs" .. year .. "Builder. (Expected string but received "..type( cfg )..")" )
	end

	local runner = FindVsRunner( FindSolutionFile(), cfg, platform, year, version )

	if shouldClean then
		print( "Cleaning solution..." ); io.stdout:flush()	
		ExecuteCommand( runner.cleanCmd )
	end

	print( "Building solution..." ); io.stdout:flush()
	ExecuteCommand( runner.buildCmd )
end

local function ExecuteVs2005Builder( cfg, shouldClean, platform )
	ExecuteVsBuilder( cfg, shouldClean, platform, "2005", "8" )
end

local function ExecuteVs2008Builder( cfg, shouldClean, platform )
	ExecuteVsBuilder( cfg, shouldClean, platform, "2008", "9" )
end

local function ExecuteVs2010Builder( cfg, shouldClean, platform )
	ExecuteVsBuilder( cfg, shouldClean, platform, "2010", "10" )
end

local function ExecuteVs2012Builder( cfg, shouldClean, platform )
	ExecuteVsBuilder( cfg, shouldClean, platform, "2012", "11" )
end

local function ExecuteVs2013Builder( cfg, shouldClean, platform )
	ExecuteVsBuilder( cfg, shouldClean, platform, "2013", "12" )
end

local function ExecuteINNOBuilder( file, shouldClean )
	print( "INNO Setup Installer Builder invoked." ); io.stdout:flush()
	-- Get the current working directory so we can restore it after the work is done.
	local curDir = lfs.currentdir()

	if type( file ) ~= "string" then
		error( "bad argument #1 to ExecuteINNOBuilder. (Expected string but received "..type( file )..")" )
	end

	-- Make sure the setup file exists before continuing
	if not FileExists( file ) then
		error( ("INNO Setup file (%q) does not exist."):format( file ) )
	end

	-- Change the directory to the installer file directory.
	lfs.chdir( path.dirname( file ) )

	-- Launch INNO Setup command line compiler to build the installer.
	local installerCmd = ""
	if IsWindows() then
		if shouldClean then
			-- Clean all old installer files.
			RemoveAll( "*.exe" )
			RemoveAll( "output/*.exe" )
		end
		local innoPath = os.getenv( "PROGRAMFILES" ) .. [[\Inno Setup 5\ISCC.exe]]
		installerCmd = string.format( [[""%s" %q"]], innoPath, path.basename( file ) )
		print( installerCmd ); io.stdout:flush()

		local installerRet = os.execute( installerCmd )

		print( "INNO process exited with code "..( installerRet or "<nil>" ) ); io.stdout:flush()

		if installerRet ~= 0 then
			lfs.chdir( curDir )
			print( string.format( "INNO error (%i) occured. Converted exit code to 1", installerRet ) ); io.stdout:flush()
			os.exit( 1 )
		end
	else
		print( "Only Windows is supported right now." ); io.stdout:flush()
		if shouldClean then
			-- Clean all old installer files.
			RemoveAll( "*.deb" )
		end
	end

	lfs.chdir( curDir )
end

local function ExecuteNSISBuilder( file )
	print( "NSIS Installer Builder invoked." ); io.stdout:flush()

	-- Get the current working directory so we can restore it after the work is done.
	local curDir = lfs.currentdir()

	if type( file ) ~= "string" then
		error( "bad argument #1 to ExecuteNSISBuilder. (Expected string but received "..type( file )..")" )
	end

	-- Make sure the setup file exists before continueing
	if not FileExists( file ) then
		error( ("NSIS Installer file (%q) does not exist."):format( file ) )
	end

	-- Change the directory to the installer file directory.
	lfs.chdir( path.dirname( file ) )

	-- Launch NSIS command line compiler to build the installer.
	local installerCmd = ""
	if IsWindows() then
		installerCmd = string.format( [["C:\Program Files\NSIS\makensis.exe" /V2 %q]], file )
		
		print( installerCmd ); io.stdout:flush()

		local installerRet = os.execute( installerCmd )

		print( "NSIS process exited with code "..( installerRet or "<nil>" ) ); io.stdout:flush()

		if installerRet ~= 0 then
			lfs.chdir( curDir )
			print( string.format( "NSIS error (%i) occured. Converted exit code to 1", installerRet ) ); io.stdout:flush()
			os.exit( 1 )
		end
	else
		print( "Only Windows is supported right now." ); io.stdout:flush()
	end

	lfs.chdir( curDir )
end

Targets =
{
  gnu = ExecuteGnuBuilder,
  vs2005 = ExecuteVs2005Builder,
  vs2008 = ExecuteVs2008Builder,
  vs2010 = ExecuteVs2010Builder,
  vs2012 = ExecuteVs2012Builder,
  vs2013 = ExecuteVs2013Builder,
  gmake = ExecuteGmakeBuilder
}

Installers =
{
  inno = ExecuteINNOBuilder,
  nsis = ExecuteNSISBuilder,
}

function main()
	local args = lapp [[
	Builds the current project. Run from the root level.

	-t,--target         (string)            One of the following: vs2005, vs2008, vs2010, vs2012, gnu, or gmake.
	-b,--build          (default Release)   Project-specific build configuration, usually Debug or Release.
	-i,--installer      (default none)      One of the following: inno or nsis.
	-f,--installerfile  (default none)      The installer source file to pass to the installer, if needed.
	-p,--premake        (default none)      Extra options passed on to premake.
	-m,--teamcity       (default true)      Enable teamcity output.
	-c,--clean                              Clean project sources before building.
	-q,--premake4                           Use premake4 (deprecated, only premake4 is supported)
	-s,--saveinstallers                     Save any previous installers in the install directory
	-a,--platform       (default none)      Platform to build
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
		premakeOptions = premakeOptions .. " --teamcity"
	end

	if args.platform and args.platform ~= "none" then
		premakeOptions = premakeOptions .. " --platform=" .. args.platform
	else
		args.platform = nil
	end

	-- Generate the project files
	TARGET = args.target or "none"
	if TARGET ~= "none" then
		if not ContainsKey( Targets, TARGET ) then
			error( "Invalid target: " .. TARGET )
		end

		if ( "gnu" == TARGET ) then
			TARGET = "gmake"
		end

		GenerateProjectFiles( TARGET, premakeOptions, premakeArgs )

		-- Actually build project
		Targets[ TARGET ]( build, shouldClean, args.platform )
	end

	-- Optionally build the installer
	if installer then
		local cleanInstallers = not args.saveinstallers
		Installers[ installer ]( installerFile, cleanInstallers )
	end
end

if not _LEXECUTOR then
	main()
end
