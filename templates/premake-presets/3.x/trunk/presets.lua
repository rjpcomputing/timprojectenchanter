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
addoption( "dynamic-runtime", "Use the dynamically loadable version of the runtime." )
addoption( "unicode", "Use the Unicode character set." )
addoption( "force-32bit", "Forces GCC to build as a 32bit only" )
addoption( "release-with-debug-symbols", "Adds Debug symbols to the release build." )

if windows then
	addoption( "disable-mingw-mthreads", "Disables the MinGW specific -mthreads compile option." )
else
	addoption( "rpath", "Linux only, set rpath on the linker line to find shared libraries next to executable")
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
--											  (GCC) { "no-import-lib" }
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
function Configure( pkg )
	-- GENERAL SETUP -------------------------------------------------------------
	--
	if not pkg.name then
		error( "No 'name' defined for this package. Make sure to define 'package.name' before continuing." )
	end

	pkg.language								= pkg.language or "c++"
	pkg.kind									= pkg.kind or "exe"
	pkg.target									= pkg.target or pkg.name
	pkg.config["Debug"].target					= pkg.config["Debug"].target or pkg.name.."d"

	-- COMPILER SETTINGS ----------------------------------------------------------
	--
	-- Build Flags
	pkg.buildflags								= pkg.buildflags or {}
	pkg.config["Debug"].buildflags				= pkg.config["Debug"].buildflags or {}
	pkg.config["Release"].buildflags			= pkg.config["Release"].buildflags or {}
	if not options["no-extra-warnings"] then
		table.insert( pkg.buildflags, { "extra-warnings" } )
	end
	if pkg.kind == "winexe" then
		table.insert( pkg.buildflags, { "no-main" } )
	end

	if options["unicode"] then
		table.insert( pkg.buildflags, { "unicode" } )
	end

	if options["dynamic-runtime"] then
		table.insert( pkg.config["Release"].buildflags, { "optimize" } )
	else
		table.insert( pkg.config["Debug"].buildflags, { "static-runtime" } )
		table.insert( pkg.config["Release"].buildflags, { "static-runtime", "optimize" } )
	end

	if not options["release-with-debug-symbols"] then
		table.insert( pkg.config["Release"].buildflags, { "no-symbols" } )
	end

	-- Defined Symbols
	pkg.defines									= pkg.defines or {}
	pkg.config["Debug"].defines					= pkg.config["Debug"].defines or {}
	pkg.config["Release"].defines				= pkg.config["Release"].defines or {}
	table.insert( pkg.config["Debug"].defines, { "DEBUG", "_DEBUG" } )
	table.insert( pkg.config["Release"].defines, { "NDEBUG" } )
	if options["unicode"] then
		table.insert( pkg.defines, { "UNICODE", "_UNICODE" } )
	end

	-- Files
	if 0 == #pkg.files then pkg.files = { matchrecursive( "*.cpp", "*.h" ) } end

	-- LINKER SETTINGS ------------------------------------------------------------
	--
	-- Linker directory paths.
	if 0 == #pkg.libpaths then pkg.libpaths = { "lib" } end

	-- COMPILER SPECIFIC SETUP ----------------------------------------------------
	--
	pkg.buildoptions							= pkg.buildoptions or {}
	pkg.linkoptions								= pkg.linkoptions or {}
	if target == "gnu" or string.find( target or "", ".*-gcc" ) then
		table.insert( pkg.buildoptions, { "-W", "-Wno-unknown-pragmas", "-Wno-deprecated", "-fno-strict-aliasing" } )
		table.insert( pkg.linkoptions, { "-Wl,-E" } )
		table.insert( pkg.buildflags, { "no-import-lib" } )
		if windows then
			if not options["disable-mingw-mthreads"] then
				table.insert( pkg.buildoptions, { "-mthreads" } )
				table.insert( pkg.linkoptions, { "-mthreads" } )
			end
		end
		-- Set object output directory.
		if options["unicode"] then
			pkg.objdir							= ".obju"
		else
			pkg.objdir							= ".obj"
		end
		-- Force gcc to build a 32bit target.
		if options["force-32bit"] then
			table.insert( pkg.buildoptions, { "-m32" } )
			table.insert( pkg.linkoptions, { "-m32" } )
		end
	end

	if linux then
		local useRpath = true
		local rpath="$$``ORIGIN"

		local rpathOption = options["rpath"]

		if rpathOption then
			if "no" == rpathOption or "" == rpathOption then
				useRpath = false
			else
				rpath = rpathOption
			end
		end

		if useRpath then
			table.insert( package.linkoptions, "-Wl,-rpath," .. rpath )
		end
	end

	if target == "vs2005" or target == "vs2008" then
		-- Visual C++ 2005/2008
		table.insert( pkg.buildflags, { "seh-exceptions", "no-64bit-checks" } )
		table.insert( pkg.defines, { "_CRT_SECURE_NO_DEPRECATE", "_SCL_SECURE_NO_WARNINGS", "_CRT_NONSTDC_NO_DEPRECATE" } )

		--[[
		supress warning C4503: decorated name length exceeded, name was truncated
		From MSDN:
		It is possible to ship an application that generates C4503, but if you get link time errors on a truncated symbol,
		it will be more difficult to determine the type of the symbol in the error. Debugging will also be more difficult;
		the debugger will also have difficultly mapping symbol name to type name.
		The correctness of the program, however, is unaffected by the truncated name.
		]]
		table.insert( pkg.buildoptions, "/wd4503" )


		-- Set object output directory.
		if options["unicode"] then
			pkg.objdir							= "obju"
		end

		if options["release-with-debug-symbols"] then
			table.insert( pkg.config["Release"].buildoptions, { "/Zi" } )
			table.insert( pkg.config["Release"].linkoptions, { "/DEBUG" } )
		end
	end

	if target == "vs2003" then
		-- Enable re-mapping of Windows exceptions.
		pkg.buildoptions = { "/EHa" }
		table.insert( pkg.buildflags, { "no-exceptions" } )

		-- Set object output directory.
		if options["unicode"] then
			pkg.objdir							= "obju"
		end

		if options["release-with-debug-symbols"] then
			table.insert( pkg.config["Release"].buildoptions, { "/Zi" } )
			table.insert( pkg.config["Release"].linkoptions, { "/DEBUG" } )
		end
	end

	-- OPERATING SYSTEM SPECIFIC SETTINGS -----------------------------------------
	--
	pkg.links									= pkg.links or {}
	pkg.config["Release"].links					= pkg.config["Release"].links or {}
	pkg.config["Debug"].links					= pkg.config["Debug"].links or {}

	if windows then														-- WINDOWS
		-- Maybe add "*.manifest" later, but it seems to get in the way.
		table.insert( pkg.files, { matchfiles( "*.rc" ) } )
		table.insert( pkg.defines, { "_WIN32", "WIN32", "_WINDOWS", "NOMINMAX" } )
		local winLibs 							= { "psapi", "ws2_32", "version" }
		table.insert( pkg.config["Release"].links, winLibs )
		table.insert( pkg.config["Debug"].links, winLibs )
	elseif linux then													-- LINUX
		local linLibs							= { "pthread", "dl", "m" }
		table.insert( pkg.config["Release"].links, linLibs )
		table.insert( pkg.config["Debug"].links, linLibs )
		-- lib is only needed because Premake automatically adds the -fPIC to dlls
		if ( "lib" == pkg.kind ) then
			table.insert( pkg.buildoptions, { "-fPIC" } )
		end
	else																-- MACOSX
	end
end

---	Change an option to be enabled by default.
--	@param name The name of the option to enable
--  @note Pass "no" to disable the option. Example @code --dynamic-runtime no @endcode
function EnableOption( name )
	if ( options[name] == "no" ) then
		options[name] = nil
	else
		options[name] = "yes"
	end
end

---	Explicitly disable an option
--	@param name The name of the option to disable
function DisableOption( name )
	options[name] = nil
end

-- Adds path to package (pkg) as a system path in gcc to warnings are ignored
function AddSystemPath( pkg, path )
	if string.find( target or "", ".*-gcc" ) then
		table.insert( pkg.buildoptions, { "-isystem " .. path } )
		pkg.includepaths[path] = nil -- remove from includes to make system path work properly
	elseif target == "gnu" then
		table.insert( pkg.buildoptions, { "-isystem \"" .. path .. "\"" } )
		pkg.includepaths[path] = nil -- remove from includes to make system path work properly
	else
		table.insert( pkg.includepaths, { path } )
	end
end

---	Looks if a single value is in a table.
--	@param tbl Table to seach in.
--	@param value String of the value to find in tbl.
function iContainsEntry( tbl, value )
	if type( tbl ) == "table" then
		for _, val in pairs( tbl ) do
			if true == iContainsEntry( val, value ) then
				return true
			end
		end
	else
		if tbl == value then
			return true
		end
	end

	return false
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
function MakeVersion( pkg, nameOfFile, workingDirectory )
	workingDirectory = workingDirectory or "./"
	local svnwcrev
	if windows then
		svnwcrev = "C:/Program Files/TortoiseSVN/bin/SubWCRev.exe"
		if not os.fileexists( svnwcrev )  then
			-- TortoiseSVN is not installed in the default location, so now it is required
			-- to be their PATH.
			svnwcrev = "SubWCRev.exe"
		end
	else
		svnwcrev = "svnwcrev"
	end

	local nameOfTemplate = nameOfFile .. '.template'
	local cmd = '"' .. svnwcrev .. '" ' .. workingDirectory .. ' ' .. nameOfTemplate .. ' ' .. nameOfFile
	table.insert( pkg.prebuildcommands, { cmd } )
	-- Check if the file is already added to the package's file table.
	if not iContainsEntry( pkg.files, nameOfFile ) then
		-- Only add it because it isn't already there.
		io.popen( cmd )
		table.insert( pkg.files, nameOfFile )
	end
	-- add template file to project so the template can be easily updated
	if not iContainsEntry( pkg.files, nameOfTemplate ) then
		table.insert( pkg.files, nameOfTemplate )
	end
end

function WindowsCopy( sourcePath, destinationDirectory )
	if windows then
		local command = 'copy ' .. sourcePath .. ' "' .. destinationDirectory .. '" /B /V /Y'
		print( command ); io.stdout:flush()
		os.execute( command )
	end
end

function CopyDebugCRT( destinationDirectory )
	CopyCRT( destinationDirectory, true )
end

-- Copy the redist runtime dlls
function CopyCRT( destinationDirectory, copyDebugCRT )
	if target then
		local copyDebugCRT = copyDebugCRT or false

		if windows then
			local sourcePath = ""
			os.mkdir( destinationDirectory )
			if string.find( target or "", "vs20" ) then
				local vsdir = ""
				local vsver = ""
				if target == "vs2005" then
					vsdir = "Microsoft Visual Studio 8"
					vsver = "VC80"
				elseif target == "vs2008" then
					vsdir = "Microsoft Visual Studio 9.0"
					vsver = "VC90"
				end

				if copyDebugCRT then
					sourcePath = '"%PROGRAMFILES%\\' .. vsdir .. '\\VC\\redist\\Debug_NonRedist\\x86\\Microsoft.' .. vsver .. '.DebugCRT\\*"'
				else
					sourcePath = '"%PROGRAMFILES%\\' .. vsdir .. '\\VC\\redist\\x86\\Microsoft.' .. vsver .. '.CRT\\*"'
				end
				WindowsCopy( sourcePath, destinationDirectory )
			else
				sourcePath = "C:\\MinGW4\\bin\\mingwm10.dll"
				WindowsCopy( sourcePath, destinationDirectory )

				sourcePath = "C:\\MinGW4\\bin\\libgcc_s_dw2-1.dll"
				WindowsCopy( sourcePath, destinationDirectory )
			end
		end
	end
end
