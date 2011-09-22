-- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		08/11/2008
--	Version:	1.00
--
--	Copyright (C) 2008 Ryan Pusztai
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
--		- use the '/' slash for all paths.
--		- call Configure() after your project is setup, not before.
-- ----------------------------------------------------------------------------

-- OPTIONS -------------------------------------------------------------------
--
newoption
{
   trigger     = "dynamic-runtime",
   description = "Use the dynamically loadable version of the runtime."
}

newoption
{
   trigger     = "unicode",
   description = "Use the Unicode character set."
}

newoption
{
   trigger     = "force-32bit",
   description = "Forces GCC to build as a 32bit only"
}

newoption
{
   trigger     = "release-with-debug-symbols",
   description = "Adds Debug symbols to the release build."
}

newoption
{
   trigger     = "no-extra-warnings",
   description = "Do not enable extra warnings."
}

newoption
{
   trigger     = "shared-libraries",
   description = "Build shared libraries."
}

if os.is("windows") then
	newoption
	{
	   trigger     = "disable-mingw-mthreads",
	   description = "Disables the MinGW specific -mthreads compile option."
	}
end

newoption
{
	trigger		= "with-gprof",
	description	= "Enable information to be added for profiling by gprof"
}

newoption
{
	trigger		= "with-gcov",
	description	= "Enable information to be added for profiling by gcov"
}

newoption
{
	trigger		= "with-trace",
	description	= "Enable trace statements"
}

if os.is("linux") then
	newoption
	{
		trigger		= "rpath",
		description	= "Linux only, set rpath on the linker line to find shared libraries next to executable"
	}
end

presets = {}

-- the version of the windows API for the _WIN32_WINNT macro, and others like it
presets.WindowsAPIVersion = "0x0500"

---	Change an option to be enabled by default.
--	@param name The name of the option to enable
--  @note Pass "no" to disable the option. Example @code --dynamic-runtime no @endcode
function EnableOption( name )
	if ( _OPTIONS[name] == "no" ) then
		_OPTIONS[name] = nil
	else
		_OPTIONS[name] = ""
	end
end

---	Explicitly disable an option
--	@param name The name of the option to disable
function DisableOption( name )
	_OPTIONS[name] = nil
end

if _OPTIONS["shared-libraries"] then
	EnableOption( "dynamic-runtime" )
end

---	Configures a target with  a set of this pre-configuration.
--	@param pkg Premake 'package' passed in that gets all the settings manipulated.
--
--	Options supported:
--		dynamic-runtime - "Use the dynamicly loadable version of the runtime."
--		unicode - "Use the Unicode character set."
--		disable-mingw-mthreads - "Disables the MinGW specific -mthreads compile option."
--
--	Required package setup:
--		package.name
--		package.includepaths	(if needed)
--		package.links			(if needed)
--	Default package setup: (if not specifically set)
--		package.language					= "c++"
--		package.kind						= "exe" (make this "winexe" if you don't want a console)
--		package.target						= package.name
--		package.config["Debug"].target		= package.name.."d"
--		package.files						= matchrecursive( "*.cpp", "*.h" )
--		package.libpaths					= { "libs" }
--	Appended to package setup:
--		package.buildflags (where appropriate)	= { "extra-warnings", "static-runtime", "no-symbols", "optimize", "no-main", "unicode" }
--											  (VC) { "seh-exceptions", "no-64bit-checks" }
--		package.buildoptions				= (GCC) { "-W", "-Wno-unknown-pragmas", "-Wno-deprecated", "-fno-strict-aliasing"[, "-mthreads"] }
--		package.linkoptions					= (GCC/Windows) { ["-mthreads"] }
--											  (Linux) { ["-fPIC"] }
--		package.defines						= { ["UNICODE", "_UNICODE"] }
--											  (Windows) { "_WIN32", "WIN32", "_WINDOWS" }
--											  (VC) { "_CRT_SECURE_NO_DEPRECATE" }
--		package.config["Debug"].defines		= { "DEBUG", "_DEBUG" }
--		package.config["Release"].defines	= { "NDEBUG" }
--		package.files						= (Windows) matchfiles( "*.rc" )
--		package.links						= (Windows) { "psapi", "ws2_32", "version" }
--											  (Linux) { "pthread", "dl", "m" }
--	Set and can not be changed:
--		pkg.objdir							= (VC) "obj[u]" (GCC) ".obj[u]
--
--	Console Example:
--		dofile( "build/presets.lua" )
--		package.name = "MyCoolApplication"
--		...
--		-- It will include all *.cpp and *.h files in all sub-directories,
--		-- so no need to specify.
--		-- Make this application a console app.
--		Configure( package )
--
--	Static Library Example:
--		dofile( "build/presets.lua" )
--		package.name = "MyCoolStaticLibrary"
--		package.kind = "lib"
--		...
--		-- It will include all *.cpp and *.h files in all sub-directories,
--		-- so no need to specify.
--		-- Make this application a console app.
--		Configure( package )
--
--	Dll Example:
--		dofile( "build/presets.lua" )
--		package.name = "MyCoolDll"
--		package.kind = "dll"
--		...
--		-- It will include all *.cpp and *.h files in all sub-directories,
--		-- so no need to specify.
--		-- Make this application a console app.
--		Configure( package )
--
--	GUI Example:
--		dofile( "build/presets.lua" )
--		package.name = "MyCoolGUIApplication"
--		package.kind = "winexe"
--		...
--		-- It will include all *.cpp and *.h files in all sub-directories,
--		-- so no need to specify.
--		-- Make this application a GUI app.
--		Configure( package )
function presets.GetCustomValue( item )
	local prj = project()
	for _, block in pairs( prj.blocks ) do
		if block[item] then
			return block[item]
		end
	end
	return nil
end

function Configure()

	cfg = configuration()

	if not project() then
		error( "There is no currently active project. Please use the project() method to create a project first." )
	end

	configuration( {} )

	if not language() then
		language "C++"
	end

	local kindVal = presets.GetCustomValue( "kind" )
	if kindVal then
		if "WindowedApp" == kindVal then
			flags( "WinMain" )
		elseif "StaticLib" == kindVal then
			if not presets.GetCustomValue( "targetdir" ) then
				targetdir( solution().basedir .. "/lib" )
			end
		end
	else
		kind( "ConsoleApp" )
	end

	if not presets.GetCustomValue( "objdir" ) then
		objdir( "obj/" .. iif( _ACTION, _ACTION, "" ) )
	end

	if (not _OPTIONS["no-extra-warnings"]) or (_OPTIONS["no-extra-warnings"] == "no") then
		flags( "ExtraWarnings" )
		if ActionUsesGCC() then
			buildoptions( "-W" )
		end
	end

	configuration( "not dynamic-runtime" )
		flags( "StaticRuntime" )

	configuration( "Debug" )
		if not presets.GetCustomValue( "targetsuffix" ) then
			targetsuffix( "d" )
		end
		defines( { "DEBUG", "_DEBUG" } )
		flags( "Symbols" )

	configuration( "Release" )
		defines( { "NDEBUG" } )
		flags( "Optimize" )

	configuration( "unicode" )
		flags( "Unicode" )
		defines( { "UNICODE", "_UNICODE" } )
		objdir( "obju/" .. iif( _ACTION, _ACTION, "" ) )

	-- COMPILER SPECIFIC SETUP ----------------------------------------------------
	--
	configuration( "gmake or codelite or codeblocks or xcode3" )
		buildoptions( { "-Wno-unknown-pragmas", "-Wno-deprecated", "-fno-strict-aliasing" } )
		linkoptions( { "-Wl,-E" } )
		if os.get() == "windows" then
			linkoptions( { "-Wl,--enable-auto-import" } )
			flags( "NoImportLib" )
			if not _OPTIONS["disable-mingw-mthreads"] then
				buildoptions( "-mthreads" )
				linkoptions( "-mthreads" )
			end
		end

		-- Force gcc to build a 32bit target.
		if _OPTIONS["force-32bit"] then
			buildoptions( "-m32" )
			linkoptions( "-m32" )
		end

	if os.is( "linux" ) then
		local useRpath = true
		local rpath="$$``ORIGIN"

		local rpathOption = _OPTIONS[ "rpath" ]

		if rpathOption then
			if "no" == rpathOption or "" == rpathOption then
				useRpath = false
			else
				rpath = rpathOption
			end
		end

		if useRpath then
			linkoptions( "-Wl,-rpath," .. rpath )
		end
	end

	configuration( "vs*" )
		flags( { "SEH", "No64BitChecks" } )
		defines( { "_CRT_SECURE_NO_DEPRECATE", "_SCL_SECURE_NO_WARNINGS", "_CRT_NONSTDC_NO_DEPRECATE" } )

	configuration( { "vs*", "release-with-debug-symbols", "Release", "not StaticLib" } )
		linkoptions "/DEBUG"

	configuration( "vs2008 or vs2010" )
		-- multi-process building
		flags( "NoMinimalRebuild" )
		buildoptions( "/MP" )

	-- OPERATING SYSTEM SPECIFIC SETTINGS -----------------------------------------
	--
	configuration( "windows" )
		-- Maybe add "*.manifest" later, but it seems to get in the way.
		files( "*.rc" )
		defines( { "_WIN32", "WIN32", "_WINDOWS", "NOMINMAX", "_WIN32_WINNT=" .. presets.WindowsAPIVersion } )

	configuration( { "windows", "not StaticLib" } )
		links( { "psapi", "ws2_32", "version", "winmm" } )

	configuration( { "linux", "not StaticLib" } )
		links( { "pthread", "dl", "m" } )

	configuration( { "linux", "StaticLib" } )
		-- lib is only needed because Premake automatically adds the -fPIC to dlls
		buildoptions( "-fPIC" )

	if _OPTIONS["with-gprof"] then
		-- Add profiling information
		configuration( "Debug gmake or codelite or codeblocks or xcode3" )
			buildoptions( "-pg" )
			linkoptions( "-pg" )
	end

	if _OPTIONS["with-gcov"] then
		-- Add coverage information
		configuration( "Debug gmake or codelite or codeblocks or xcode3" )
			buildoptions( { "-fprofile-arcs", "-ftest-coverage" } )
			links( "gcov" )
	end

	configuration(cfg.terms)

end

--[[	Configure a C/C++ project to use a library.
--  @param libName			{string} Name of the library
--  @param includePath		{string} [DEF] Path to include directory
--  @param sharedOptionName	{string} [DEF] Name of option controlling dynamic linkage
--  @param usingDllDefine	{string} [DEF] Define for using the library as a dll.
--	Appended to project setup:
--		includedirs	(	"../" .. includePath or libName	)
--		links		(	libName							)
--		if _OPTIONS[ sharedOptionName or ( string.lower( libName ) .. "-shared" ) ] then
--			defines( usingDllDefine or ( string.upper( libName ) .. "_USING_DLL" ) )
--		end
--
--	Example:
--		ConfigureLibrary( "boost_utils" )
--]]

function ConfigureLibrary( libName, includePath, sharedOptionName, usingDllDefine )

	if not libName then
		error( "ConfigureLibrary needs the name of the library", 2 )
	end

	if type( libName ) ~= "string" then
		error( "ConfigureLibrary expects the name of the library as a string", 2 )
	end

	local kindVal = presets.GetCustomValue( "kind" ) or ""
	if ( kindVal ~= "StaticLib" ) then
		links( libName )
	end

	if includePath then
		local success, msg = pcall( includedirs, includePath )
		if not success then
			error( "ConfigureLibrary( " .. libName .. " ): " .. msg, 2 )
		end
	else
		if unittest and unittest.projectUnderTestKind then
			kindVal = unittest.projectUnderTestKind
		end

		presets.Trace( "Configuring " .. libName .. " for " .. project().name .. ", when " .. project().name .. " is a " .. kindVal )

		if ( (kindVal == "StaticLib") or (kindVal == "SharedLib") ) then
			includedirs( "../" .. libName )
		else
			includedirs( libName )
		end
	end

	if _OPTIONS[ sharedOptionName or ( string.lower( libName ) .. "-shared" ) ] then
		defines( usingDllDefine or ( string.upper( libName ) .. "_USING_DLL" ) )
	end

end

-- Adds path as a system path in gcc so warnings are ignored
function AddSystemPath( path )
	if type(path) ~= "string" then
		error( "AddSystemPath only accepts a string", 2 )
	end
	if ("codelite" == _ACTION) or ("codeblocks" == _ACTION) or ("xcode3" == _ACTION) then
		buildoptions( "-isystem " .. path )
	elseif ("gmake" == _ACTION) then
		buildoptions( "-isystem \"" .. path .. "\"" )
	else
		includedirs( path )
	end
end

---	Removes a single value in a table.
--	@param tbl Table to seach in.
--	@param value String of the value to remove in tbl.
function iRemoveEntry( tbl, value )
	for i, val in ipairs( tbl ) do
		if type( val ) == "table" then
			if true == iRemoveEntry( val, value ) then
				return true
			end
		else
			if val == value then
				table.remove( tbl, i )
				return true
			end
		end
	end

	return false
end

function TableWrite( tbl, indent )
	indent = indent or "\t"
	local function FormatKey( k )
		if type( k ) == "string" then
			return k --'"' .. k .. '"]'
		elseif type( k ) == "number" then
			return "[" .. k .. "]"
		else
			return tostring( k )
		end
	end

	local function FormatValue( v )
		if type( v ) == "string" then
			return '"' .. v .. '"'
		else
			return tostring( v )
		end
	end

	local retVal = ""
	local indentCount = 0
	local function Stringify( tbl, indent )
		-- Start the table brace
		retVal = retVal .. indent:rep( indentCount ) .. "{\n"
		-- Indent the contents
		indentCount = indentCount + 1
		for key, value in pairs( tbl ) do
			if type( value ) == "table" then
				Stringify( value, indent )
			else
				retVal = retVal .. string.format( "%s%s = %s,\n", indent:rep( indentCount ), FormatKey( key ), FormatValue( value ) )
			end
		end
		-- Unindent to add the closing table brace
		indentCount = indentCount - 1
		-- End the table brace
		retVal = retVal .. indent:rep( indentCount ) .. "}\n"

		return retVal
	end

	return Stringify( tbl, indent )
end

function pprint( tbl, indent )
	print( TableWrite( tbl, indent ) ); io.stdout:flush()
end

---	Assumptions: Tool SubWCRev is installed
--	Make a version to be maintained by subversion
--	@param name of the file to be created for versioning ( nameOfFile.template must exist as the template for created file )
--	@example
--
--	#include "DeviceComm.h"
--
--	namespace devcomm
--	{
--		unsigned long DeviceComm::GetBuildNumber()
--		{
--			return $WCREV$;
--		}
--	}
--	$WCREV$ will be replaced by svn revision of working copy by tool SubWCRev
function MakeVersion( nameOfFile, workingDirectory )
	workingDirectory = workingDirectory or "./"
	if (type(nameOfFile) ~= "string") then
		error( "MakeVersion expects nameOfFile as string, but it was passed as: " .. type(nameOfFile), 2 )
	end
	if (type(workingDirectory) ~= "string") then
		error( "MakeVersion expects workingDirectory as string, but it was passed as: " .. type(workingDirectory), 2 )
	end
	local svnwcrev
	if ( os.is( "windows" ) ) then
		svnwcrev = "C:/Program Files/TortoiseSVN/bin/SubWCRev.exe"
		if not os.isfile( svnwcrev )  then
			-- TortoiseSVN is not installed in the default location, so now it is required
			-- to be their PATH.
			svnwcrev = "SubWCRev.exe"
		end
	else
		svnwcrev = "svnwcrev"
	end

	local nameOfTemplate = nameOfFile .. '.template'
	local cmd = '"' .. svnwcrev .. '" ' .. workingDirectory .. ' ' .. nameOfTemplate .. ' ' .. nameOfFile
	prebuildcommands { cmd }

	-- Check if the file is already added to the package's file table.
	if not table.contains( configuration().files, nameOfFile ) then
		-- Only add it because it isn't already there.
		io.popen( cmd )
		files { nameOfFile }
	end

	-- add template file to project so the template can be easily updated
	if not table.contains( configuration().files, nameOfTemplate ) then
		files { nameOfTemplate }
	end
end

function SolutionTargetDir()
	local sln = solution()
	if ( sln.blocks[1] and sln.blocks[1].targetdir ) then
		return solution().blocks[1].targetdir
	end
	return nil
end

function ActionUsesGCC()
	return ("gmake" == _ACTION or "codelite" == _ACTION or "codeblocks" == _ACTION or "xcode3" == _ACTION)
end

function ActionUsesMSVC()
	return (_ACTION and _ACTION:find("vs"))
end

function presets.CopyFile( sourcePath, destinationDirectory )
	sourceFile = string.gsub( sourcePath, "([\\]+)", "/" )
	local unquotedSource = string.gsub( sourceFile, '"', '' )

	destinationDirectory = string.gsub( destinationDirectory, "([\\]+)", "/" )
	local unquotedDestination = string.gsub( destinationDirectory, '"', '' )

	if not os.isdir( unquotedDestination ) then
		print( "Creating Directory: " .. unquotedDestination ); io.stdout:flush()
		local created, msg = os.mkdir( unquotedDestination )
		if( not created ) then
			error( "presets.CopyFile Failed: " .. msg, 2 )
		end
	end

	local sourceFileName = path.getname( unquotedSource )
	if sourceFileName ~= path.getname( unquotedDestination ) then
		unquotedDestination = unquotedDestination .. "/" .. sourceFileName
	end

	print( "os.copyfile( " .. unquotedSource .. ", " .. unquotedDestination .. " )" ); io.stdout:flush()

	local copied, msg = os.copyfile( unquotedSource, unquotedDestination )
	if not copied then
		error( "presets.CopyFile Failed: " .. msg, 2 )
	end
end

function WindowsCopy( ... )
	if os.is( "windows" ) then
		presets.CopyFile( ... )
	end
end

function CopyDebugCRT( destinationDirectory )
	CopyCRT( destinationDirectory, true )
end

-- Copy the redist runtime dlls
function CopyCRT( destinationDirectory, copyDebugCRT )

	local copyDebugCRT = copyDebugCRT or false

	if ( os.get() == "windows" ) then
		local sourcePath = ""
		if ( _ACTION:find( "vs20" ) ) then
			local vsdir = ""
			local vcname = ""
			if _ACTION == "vs2005" then
				vsdir = "Microsoft Visual Studio 8"
				vcname = "VC80"
			elseif _ACTION == "vs2008" then
				vsdir = "Microsoft Visual Studio 9.0"
				vcname = "VC90"
			elseif _ACTION == "vs2010" then
				vsdir = "Microsoft Visual Studio 10.0"
				vcname = "VC100"
			end

			local libsToCopy = {}
			local programFiles = os.getenv( "ProgramFiles" )
			if copyDebugCRT then
				libsToCopy = os.matchfiles(programFiles  .. '/' .. vsdir .. '/VC/redist/Debug_NonRedist/x86/Microsoft.' .. vcname .. '.DebugCRT/*' )
			else
				local crtPath = programFiles .. '/' .. vsdir .. '/VC/redist/x86/Microsoft.' .. vcname .. '.CRT/*'
				libsToCopy = os.matchfiles(crtPath)
				print ( "found " .. #libsToCopy .. " crt files to copy from " .. crtPath )
			end
			for _, lib in ipairs( libsToCopy ) do
				WindowsCopy( lib, destinationDirectory )
			end
		else
			sourcePath = "C:/MinGW4/bin/mingwm10.dll"
			WindowsCopy( sourcePath, destinationDirectory )

			sourcePath = "C:/MinGW4/bin/libgcc_s_dw2-1.dll"
			WindowsCopy( sourcePath, destinationDirectory )
		end
	end
end

---
-- Convert a file to a c header file for includsion as an array
-- @param sourceFile	The name of the file to convert
-- @param destFile		[DEF] The name of the destination file, defaults to path.getname( sourceFile ) .. ".h"
-- @param destFile		[DEF] The name of the variable, defaults to path.getname( sourceFile )
-- Adapted from
-- http://lua-users.org/wiki/BinToCee
-- Original author: Mark Edgar
-- Licensed under the same terms as Lua (MIT license).
--
function presets.Bin2C( sourceFile, destFile, variableName )

	local content = assert( io.open( sourceFile,"rb" ) ):read"*all"

	local dump do
		local numberTable={}
		for i = 0, 255 do
			numberTable[ string.char( i ) ] = ("0x%02X,"):format( i )
		end
		function dump( str )
			return ( str:gsub( ".", numberTable ):gsub( ("."):rep(75), "%0\n\t" ) )
		end
	end

	local filename = path.getname( sourceFile )
	variableName = variableName or string.lower( string.gsub( filename, "%.", "_" ) )
	destFile = destFile or filename .. ".h"
	local headerGuard = string.upper( string.gsub( path.getname( destFile ), "%.", "_" ) )
	local output = assert( io.open( destFile, "w" ) )
	output:write (
	"/* code automatically generated by bin2c -- DO NOT EDIT */\n",
	"#ifndef ", headerGuard, "\n",
	"#define ", headerGuard, "\n\n",
	"static const unsigned char ", variableName, "[] = \n",
	"{\n\t",
	dump(content), "\n",
	"};\n\n",
	"#endif //", headerGuard, "\n" )
end

---
-- call print if 'with-trace' is on
--
function presets.Trace( ... )
	if _OPTIONS["with-trace"] then
		print( ... ); io.stdout:flush()
	end
end
