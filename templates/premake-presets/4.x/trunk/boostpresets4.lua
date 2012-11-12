-- ----------------------------------------------------------------------------
--	Name:		boostpresets4.lua, a Premake4 script
--	Author:		Ben Cleveland, based on boostpresets.lua by Ryan Pusztai
--	Date:		11/24/2010
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- Package options

newoption
{
	trigger = "boost-shared",
	description = "Link against Boost as a shared library (including boost-utils)"
}

newoption
{
	trigger = "boost-single-threaded",
	description = "Link against Boost using a single threaded runtime"
}

newoption
{
	trigger = "boost-link-debug",
	description = "Link against the debug version in Debug configuration. Normally you link against the release version no matter the configuration."
}

newoption
{
	trigger = "boost-force-compiler-version",
	description = "Force the compiler version to be included in the file name"
}

newoption
{
	trigger = "boost-nocopy-debug",
	description = "Override copying the debug libraries in the CopyDynamicLibraries method"
}

-- Namespace
boost = {}
boost.numeric_version = 1.40
boost.version = "1_40" -- default boost version

--	The version of GCC that you are building for.
--		Make sure that you leave the '.' out of the string. (i.e. "44" not "4.4")
--		Defaults to "44" on Windows and "44" on Linux.
boost.gcc_version = "44"

if "windows" == os.get() then
	boost.root = os.getenv( "BOOST_ROOT" )
	if not boost.root then
		error( "missing the BOOST_ROOT environment variable" )
	end

	-- determine version from BOOST_ROOT environment variable
	local slashIndex = 1;
	while true do
		local nextIndex = boost.root:find( "\\", slashIndex + 1, true )
		if nextIndex ~= nil then
			slashIndex = nextIndex
		else
			break
		end
	end

	local versionDir = boost.root:sub( slashIndex + 1 )
	local shortVersion = versionDir:gsub( "%.0", "" )
	local shortVersionString = shortVersion:gsub( "%.", "_" )
	boost.numeric_version = tonumber( shortVersion )
	boost.version = shortVersionString
end

---	Gets the Boost specific Toolset name. This only supports Visual C++ and
--	GCC.
--	TODO: Make this more flexable.

--	@return {string} String that contains the Boost specific target name.
function boost.GetToolsetName()
	local toolsetName = ""

	if _ACTION == "vs2003" then
		toolsetName = "vc71"
	elseif _ACTION == "vs2005" then
		toolsetName = "vc80"
	elseif _ACTION == "vs2008" then
		toolsetName = "vc90"
	elseif _ACTION == "vs2010" then
		toolsetName = "vc100"
	elseif ActionUsesGCC() then
		if "windows" == os.get() then
			toolsetName = "mgw"..boost.gcc_version
		else
			toolsetName = "gcc"..boost.gcc_version
		end
	end

	return toolsetName
end

---	Generates a valid Boost library name.
--	@param libraryName {string} Library name to build as a full Boost library
--		name.
--	@param isDebug [DEF] {boolean} If true it will generate the name of the debug
--		version of the library. Defaults to false.
--  @param makeDllName true to make the dll's name
--	Supported but not displayed options:
--		- using-stlport - "Use the STLPort standard library rather than
--		                   the default one supplied with your compiler"
--	Comprimises:
--		- Only supports VC and GCC
function boost.LibName( libraryName, isDebug )
	local name = ""

	-- Toolset - target/compiler.
	local toolset = ""
	if "windows" == os.get() or _OPTIONS["boost-force-compiler-version"] then
		toolset = "-" .. boost.GetToolsetName()
	end
	--print( "Toolset: ", toolset )

	-- Threading
	local threading = "-mt"
	if _OPTIONS["boost-single-threaded"] then
		threading = ""
	end
	--print( "Threading: ", threading )

	-- ABI
	local abi = ""
	if not _OPTIONS["dynamic-runtime"] then abi = abi.."s" end
	if isDebug and "windows" == os.get() then
		if ActionUsesGCC() then
			-- do nothing
		else
			abi = abi.."g"
		end
	end

	if isDebug then abi = abi.."d" end
	if _OPTIONS["using-stlport"] then abi = abi.."p" end
	-- Now add the '-' to finish the tag.
	if abi:len() > 0 then abi = "-"..abi end
	--print( "ABI:", abi )

	-- Boost version
	local boostVerSuffix = ""
	if (not os.is("linux")) and (_OPTIONS["boost-shared"] or boost.numeric_version >= 1.45) then
		if boost.version ~= "" then
			boostVerSuffix = "-" .. boost.version
		end
	end

	name = "boost_"..libraryName..toolset..threading..abi..boostVerSuffix
	--print( name )

	return name
end

function boost.LinkStaticLibFullPath( libraryName, isDebug )
	linkoptions( "-l:" .. boost.root .. "/lib/lib" .. boost.LibName( libraryName, isDebug ) .. ".a" )
end

function boost.LinkLibName( libraryName, isDebug )
	links( boost.LibName( libraryName, isDebug ) )
end

function boost.LinkSharedLibExceptRegex( libraryName, isDebug )
	--[[
	Boost.Regex forces static build with mingw, because
	mingw has known bugs with a shared libraries. See:
		https://svn.boost.org/trac/boost/ticket/3430
	for the onging investigation.
	]]

	if "regex" == libraryName then
		links { boost.LibName( libraryName, true ) }
	else
		local libprefix = ""
		if boost.numeric_version >= 1.45 then
			libprefix = "lib"
		end
		-- force linking to the dll
		linkoptions { "-l:" .. libprefix .. boost.LibName( libraryName, true ) .. ".dll" }
	end
end

function boost.AddLinksToConfiguration( libsToLink, isDebug, LibLinker )
	local kindVal = presets.GetCustomValue( "kind" ) or ""
	if ( kindVal ~= "StaticLib" ) then
		for _, libraryName in ipairs( libsToLink ) do
			LibLinker( libraryName, isDebug )
		end
	end
end

function boost.AddLinks( libsToLink, LibLinker )
	if _OPTIONS["boost-link-debug"] then
		configuration "Debug"
			boost.AddLinksToConfiguration( libsToLink, true, LibLinker )
		configuration "Release"
		-- fall through to adding release libs
	end

	boost.AddLinksToConfiguration( libsToLink, false, LibLinker )
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
--
--	NOTES:
--		Only supports VC and GCC
--
--	Example:
--		boost.Configure( package, { "libsToLink" }, "44" )
function boost.Configure( libsToLink, gccVer, boostVer )
	boost.version = boostVer or boost.version
	boost.gcc_version = gccVer or boost.gcc_version

	libsToLink = libsToLink or {}
	-- Check to make sure that the libsToLink is valid.
	assert( type( libsToLink ) == "table", "Param1:libsToLink type missmatch, should be a table." )

	cfg = configuration()

	if ( cfg.kind == "StaticLib" ) then
		includedirs { "../boost_utils" }
	else
		includedirs { "boost_utils" }
	end

	if _OPTIONS["boost-shared"] then
		defines { "BOOST_ALL_DYN_LINK" }
	end

	-- Set Boost libraries to link.
	if os.is( "windows" ) then
		AddSystemPath( boost.root )

		--(the following line prevents in boost: socket_types.hpp(27) : fatal error C1189: #error :  WinSock.h has already been included)
		defines { "WIN32_LEAN_AND_MEAN" }

		if ActionUsesMSVC() then
			libdirs { boost.root .. "/lib" }
		else 
			-- Only add link libraries if not VC.
			if _OPTIONS["boost-shared"] then
				libdirs { boost.root .. "/lib" }
				boost.AddLinks( libsToLink, boost.LinkSharedLibExceptRegex )
			else
				defines( "BOOST_THREAD_USE_LIB" ) -- vc is LIB by default, mingw needs this
				boost.AddLinks( libsToLink, boost.LinkStaticLibFullPath )
			end
		end
	else
		boost.AddLinks( libsToLink, boost.LinkLibName )
	end

	configuration(cfg.terms)
end

function boost.CopyDynamicLibraries( libsToLink, destinationDirectory, gccVer, boostVer, copyDebug )
	if _ACTION and ( _ACTION ~= "clean") then
		boost.version = boostVer or boost.version
		boost.gcc_version = gccVer or boost.gcc_version
		local shouldCopyDebugLibs = copyDebug
		if copyDebug == nil then
			shouldCopyDebugLibs = true
		end

		if _OPTIONS["boost-nocopy-debug"] then
			shouldCopyDebugLibs = false
		end

		local libprefix = ""
		if boost.numeric_version >= 1.45 and ActionUsesGCC() then
			libprefix = "lib"
		end

		-- copy dlls to bin dir
		if os.is("windows") then
			function copyLibs( debugCopy )
				for _, v in ipairs( libsToLink ) do
					local libname = libprefix .. boost.LibName( v, debugCopy ) .. '.dll'
					if ("regex" == v and ActionUsesGCC() and boost.numeric_version < 1.45 ) then
						--[[
						Boost.Regex forces static build with mingw, because
						mingw has known bugs with a shared libraries. See:
							https://svn.boost.org/trac/boost/ticket/3430
						for the onging investigation.
						]]
					else
						local sourcePath = '"' .. boost.root .. '\\lib\\' .. libname .. '"'
						local destPath = '"' .. destinationDirectory .. '"'
						WindowsCopy( sourcePath, destPath )
					end
					if "bzip2" == v and string.find( _ACTION or "", "vs20" ) then
						os.copyfile( destinationDirectory .. "/" .. libname, destinationDirectory .. "/libbz2.dll" )
					end
				end
			end
			if shouldCopyDebugLibs then
				copyLibs( true )
			end
			copyLibs( false )
		end
	end
end
