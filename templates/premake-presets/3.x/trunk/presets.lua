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
addoption( "dynamic-runtime", "Use the dynamicly loadable version of the runtime." )
addoption( "unicode", "Use the Unicode character set." )
addoption( "force-32bit", "Forces GCC to build as a 32bit only" )
if windows then
	addoption( "disable-mingw-mthreads", "Disables the MinGW specific -mthreads compile option." )
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
	table.insert( pkg.buildflags, { "extra-warnings" } )
	if pkg.kind == "winexe" then
		table.insert( pkg.buildflags, { "no-main" } )
	end

	if options["unicode"] then
		table.insert( pkg.buildflags, { "unicode" } )
	end

	if options["dynamic-runtime"] then
		table.insert( pkg.config["Release"].buildflags, { "no-symbols", "optimize" } )
	else
		table.insert( pkg.config["Debug"].buildflags, { "static-runtime" } )
		table.insert( pkg.config["Release"].buildflags, { "static-runtime", "no-symbols", "optimize" } )
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
	if target == "gnu" or string.find( target or "", ".*-gcc" ) then
		table.insert( pkg.buildoptions, { "-W", "-Wno-unknown-pragmas", "-Wno-deprecated", "-fno-strict-aliasing" } )
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

	if target == "vs2005" or target == "vs2008" then
		-- Visual C++ 2005/2008
		table.insert( pkg.buildflags, { "seh-exceptions", "no-64bit-checks" } )
		table.insert( pkg.defines, { "_CRT_SECURE_NO_DEPRECATE", "_SCL_SECURE_NO_WARNINGS" } )

		-- Set object output directory.
		if options["unicode"] then
			pkg.objdir							= "obju"
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
	end

	-- OPERATING SYSTEM SPECIFIC SETTINGS -----------------------------------------
	--
	pkg.links									= pkg.links or {}
	pkg.config["Release"].links					= pkg.config["Release"].links or {}
	pkg.config["Debug"].links					= pkg.config["Debug"].links or {}

	if windows then														-- WINDOWS
		-- Maybe add "*.manifest" later, but it seems to get in the way.
		table.insert( pkg.files, { matchfiles( "*.rc" ) } )
		table.insert( pkg.defines, { "_WIN32", "WIN32", "_WINDOWS" } )
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
	elseif target == "gnu" then
		table.insert( pkg.buildoptions, { "-isystem \"" .. path .. "\"" } )
	else
		table.insert( pkg.includepaths, { path } )
	end
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
function MakeVersion( pkg, nameOfFile )
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

	local cmd = '"' .. svnwcrev .. '" ./ ' .. nameOfFile .. '.template ' .. nameOfFile
	table.insert( pkg.prebuildcommands, { cmd } )
	-- Check if the file is already added to the package's file table.
	if not iContainsEntry( pkg.files, nameOfFile ) then
		-- Only add it because it isn't already there.
		io.popen( cmd )
		table.insert( pkg.files, nameOfFile )
	end
end
