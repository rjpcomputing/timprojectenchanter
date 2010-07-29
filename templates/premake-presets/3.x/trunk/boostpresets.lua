-- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		03/26/2010
--	Version:	1.21
--
--	Copyright (C) 2008-2010 Ryan Pusztai
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
--		- call boost.Configure() after your project is setup, not before.
-- ----------------------------------------------------------------------------

-- Package options
addoption( "boost-shared", "Link against Boost as a shared library (including boost-utils)" )
addoption( "boost-single-threaded", "Link against Boost using a single threaded runtime" )
addoption( "boost-link-debug", "Link against the debug version in Debug configuration. Normally you link against the release version no matter the configuration." )
addoption( "boost-force-compiler-version", "Force the compiler version to be included in the file name" )

-- Namespace
boost = {}

---	Gets the Boost specific Toolset name. This only supports Visual C++ and
--	GCC.
--	TODO: Make this more flexable.
--	@param gccVer [DEF] {string} The version of GCC that you are building for.
--		Make sure that you leave the '.' out of the string. (i.e. "44" not "4.4")
--		Defaults to "44" on Windows and "44" on Linux.
--	@return {string} String that contains the Boost specific target name.
function boost.GetToolsetName( gccVer )
	local toolsetName = ""
	if windows then
		gccVer = gccVer or "44"
	else
		gccVer = gccVer or "44"
	end

	if target == "vs2003" then
		toolsetName = "vc71"
	elseif target == "vs2005" then
		toolsetName = "vc80"
	elseif target == "vs2008" then
		toolsetName = "vc90"
	elseif target == "gnu" or string.find( target or "", ".*-gcc" ) then
		if windows then
			toolsetName = "mgw"..gccVer
		else
			toolsetName = "gcc"..gccVer
		end
	end

	return toolsetName
end

---	Generates a valid Boost library name.
--	@param libraryName {string} Library name to build as a full Boost library
--		name.
--	@param isDebug [DEF] {boolean} If true it will generate the name of the debug
--		version of the library. Defaults to false.
--	@param gccVer [DEF] {string} The version of GCC that you are building for.
--		Defaults to "43" on Windows and "42" on Linux.
--	Supported but not displayed options:
--		- using-stlport - "Use the STLPort standard library rather than
--		                   the default one supplied with your compiler"
--	Comprimises:
--		- Only supports VC and GCC
function boost.LibName( libraryName, isDebug, gccVer )
	local name = ""

	-- Toolset - target/compiler.
	local toolset = ""
	if windows or options["boost-force-compiler-version"] then
		toolset = "-" .. boost.GetToolsetName( gccVer )
	end
	--print( "Toolset: ", toolset )

	-- Threading
	local threading = "-mt"
	if options["boost-single-threaded"] then
		threading = ""
	end
	--print( "Threading: ", threading )

	-- ABI
	local abi = ""
	if not options["dynamic-runtime"] then abi = abi.."s" end
	if isDebug then abi = abi.."d" end
	if options["using-stlport"] then abi = abi.."p" end
	-- Now add the '-' to finish the tag.
	if abi:len() > 0 then abi = "-"..abi end
	--print( "ABI:", abi )

	name = "boost_"..libraryName..toolset..threading..abi
	--print( name )

	return name
end

---	Configure a C/C++ package to use Boost.
--	@param pkg {table} Premake 'package' passed in that gets all the settings manipulated.
--	@param libsToLink {table} [DEF] Table that contains the names of the Boost libraries needed to build.
--		Defaults to an empty table.
--	@param gccVer {string} [DEF] The version of GCC that you are building for.
--		Defaults to "44" on Windows and "44" on Linux.
--
--	Options supported:
--		boost-shared - "Link against Boost as a shared library"
--		boost-single-threaded - "Link against Boost using a single threaded runtime"
--		dynamic-runtime - "Use the dynamicly loadable version of the runtime."
--		unicode - "Use the Unicode character set."
--		using-stlport - "Use the STLPort standard library rather than
--		                 the default one supplied with your compiler"
--
--	Appended to package setup:
--		package.includepaths			= (windows) { "$(BOOST_ROOT)" }
--		package.libpaths				= (windows) { "$(BOOST_ROOT)/lib" }
--		package.linkoptions				= (GCC w/ dynamic-runtime) { "-static" }
--
--	NOTES:
--		Only supports VC and GCC
--
--	Example:
--		boost.Configure( package, { "libsToLink" }, "44" )
function boost.Configure( pkg, libsToLink, gccVer )
	libsToLink = libsToLink or {}
	-- Check to make sure that the pkg is valid.
	assert( type( pkg ) == "table", "Param1:pkg type missmatch, should be a table." )
	assert( type( libsToLink ) == "table", "Param2:libsToLink type missmatch, should be a table." )

	pkg.includepaths			= pkg.includepaths or {}
	if ( pkg.kind == "lib" ) then
		table.insert( pkg.includepaths, "../boost_utils" )
	else
		table.insert( pkg.includepaths, "boost_utils" )
	end

	if windows then
		pkg.libpaths				= pkg.libpaths or {}
		pkg.defines					= pkg.defines or {}
		pkg.buildoptions			= pkg.buildoptions or {}

		AddSystemPath( pkg, "$(BOOST_ROOT)" )

		table.insert( pkg.libpaths, { "$(BOOST_ROOT)/lib" } )
		table.insert( pkg.defines, { "_WIN32_WINNT=0x0500" } )	--(i.e. Windows 2000 target)
		--(the following line prevents in boost: socket_types.hpp(27) : fatal error C1189: #error :  WinSock.h has already been included)
		table.insert( pkg.defines, { "WIN32_LEAN_AND_MEAN" } )
	end

	if options["boost-shared"] and string.find( target or "", "vs20" ) then
		pkg.defines	= pkg.defines or {}
		table.insert( pkg.defines, "BOOST_ALL_DYN_LINK"	)
	end

	if target == "gnu" or string.find( target or "", ".*-gcc" ) then
		if not options["dynamic-runtime"] then
			pkg.linkoptions			= pkg.linkoptions or {}
			table.insert( pkg.linkoptions, { "-static" } )
		end
	end

	-- Only add link libraries if not VC.
	if not string.find( target or "", "vs*" ) then
		-- Set Boost libraries to link.
		local libs = {}
		if options["boost-link-debug"] then
			for _, v in ipairs( libsToLink ) do table.insert( libs, boost.LibName( v, true, gccVer ) ) end
			table.insert( pkg.config["Debug"].links, libs )
			libs = {}
			for _, v in ipairs( libsToLink ) do table.insert( libs, boost.LibName( v, false, gccVer ) ) end
			table.insert( pkg.config["Release"].links, libs )
		else
			for _, v in ipairs( libsToLink ) do table.insert( libs, boost.LibName( v, false, gccVer ) ) end
			table.insert( pkg.links, libs )
		end
	end
end

function boost.CopyDynamicLibraries( libsToLink, destinationDirectory, gccVer, boostVer )
	boostVer = boostVer or "1_40"

	-- copy dlls to bin dir
	if windows then
		os.mkdir( destinationDirectory )
		for _, v in ipairs( libsToLink ) do
			local libname = boost.LibName( v, false, gccVer ) .. '-' .. boostVer .. '.dll'
			local targetName = libname
			if "bzip2" == v then
				targetName = "libbz2.dll"
			end
			local sourcePath = '"%BOOST_ROOT%\\lib\\' .. libname .. '"'
			local destPath = '"' .. destinationDirectory .. '\\' .. targetName .. '"'
			local command = "copy " .. sourcePath .. ' ' .. destPath .. ' /B /V /Y'
			print( command )
			os.execute( command )
		end
	end
end
