-- ----------------------------------------------------------------------------
--	Name:		wxpresents4.lua, a Premake4 script
--	Author:		Ben Cleveland, based on wxpresents.lua by Ryan Pusztai
--	Date:		11/24/2010
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- Package options
newoption
{
	trigger = "wx-shared",
	description = "Link against wxWidgets as a shared library"
}

local function GetVersion()
	if os.is("windows") then
		local path = path.translate( path.join( path.translate( wx.root, "/" ), path.translate( "include/wx/version.h", "/" ) ) )
		local versionFile = io.open( path, "r" )

		if not versionFile then
			error( "Unable to open " .. path .. " for reading the Wx version - check the value of WXWIN (" .. wx.root .. ")" )
		end

		local versionMajor = nil
		local versionMinor = nil
		local versionRelease = nil

		for line in versionFile:lines() do
			versionMajor = versionMajor or line:match( "#define%s+wxMAJOR_VERSION%s+(%d+)" )
			versionMinor = versionMinor or line:match( "#define%s+wxMINOR_VERSION%s+(%d+)" )
			versionRelease = versionRelease or line:match( "#define%s+wxRELEASE_NUMBER%s+(%d+)" )
			if versionMajor and versionMinor and versionRelease then
				return versionMajor .. versionMinor
			end
		end

		local errorMessage = "Unable to find these in " .. path .. ":"
		if not versionMajor then
			errorMessage = errorMessage .. " wxMAJOR_VERSION"
		end
		if not versionMinor then
			errorMessage = errorMessage .. " wxMINOR_VERSION"
		end
		if not versionRelease then
			errorMessage = errorMessage .. " wxRELEASE_NUMBER"
		end
		error( errorMessage )
	elseif os.is( "linux" ) or os.is( "macosx" ) then
		local cmdline = "wx-config --release"
		local file = assert( io.popen( cmdline ))
		local output = file:read( '*all' )
		file:close()

		local major, minor = output:match( "(%d+).(%d+)" )
		return major .. minor
	else
		error( "This operating system is not currently supported for automatic detection of wxWidgets version" )
	end
end

local function ProcessBacktickCmd( cmd )
	local file = assert( io.popen( cmd ))
	local output = file:read( '*all' )
	file:close()
	return output
end

local function ProcessLinks( debug )
	if not os.is( "macosx" ) then
		local cmd = "wx-config --debug=" .. iif( debug, "yes", "no" ) .. " --libs gl, stc, propgrid, aui, std"
		local output = ProcessBacktickCmd( cmd )
		local staticLib = "StaticLib" == presets.GetCustomValue( "kind" )

		for i in string.gmatch(output, "%S+") do
			if 1 == i:find( "-l" ) then
				if not staticLib then
					links{ i:sub( 3 ) }
				end
			else
				linkoptions{ i }
			end
		end
	else
		local cmd = "wx-config --debug=" .. iif( debug, "yes", "no" ) .. " --libs" -- Is this correct? DOes it need gl, stc, propgrid, aui, std?
		local output = ProcessBacktickCmd( cmd )
		linkoptions{ output }
	end
end

local function ProcessBuildOptions( debug )
	local cmd = "wx-config --debug=" .. iif( debug, "yes", "no" ) .. " --cflags"
	local output = ProcessBacktickCmd( cmd )

	for i in string.gmatch(output, "%S+") do
		buildoptions{ i }
	end
end

local function UseUnicode()
	return _OPTIONS["unicode"] or ( 30 <= tonumber( wx.version ) )
end

-- Namespace
wx = {}
wx.hasCopiedDlls = false
wx.hasCopiedAdditionsDlls = false
wx.compilerVersion = ""
wx.version = ""

if os.is("windows") then
	wx.root = os.getenv( "WXWIN" )
	if not wx.root then
		error( "missing the WXWIN environment variable" )
	end
end

wx.version = GetVersion()

if os.is("windows") then
	if 30 <= tonumber( wx.version ) then
		if ActionUsesMSVC() then
			if _ACTION == "vs2005" then
				wx.compilerVersion = "80"
			elseif _ACTION == "vs2008" then
				wx.compilerVersion = "90"
			elseif _ACTION == "vs2010" then
				wx.compilerVersion = "100"
			elseif _ACTION == "vs2012" then
				wx.compilerVersion = "110"
			elseif _ACTION == "vs2013" then
				wx.compilerVersion = "120"
			else
				error( "Unsupported version of Visual Studio" )
			end
		elseif ActionUsesGCC()then
			wx.compilerVersion = presets.GetGccVersion()
		end
	end

	if tonumber( wx.version ) <= 28 then
		presets.VerifyDllVersion( wx.root, "/lib/vc" .. wx.compilerVersion .. "_dll/wxbase" .. wx.version .. "_net_vc" .. wx.compilerVersion .. ".dll", "WXWIN" )
	end
end

---	Configure a C/C++ package to use wxWidgets
function wx.Configure()
	-- Set the defines.
	local useUnicode = UseUnicode()
	if useUnicode then
		defines { "wxUSE_UNICODE" }
		if not _OPTIONS["unicode"] then
			defines { "UNICODE_DEFINED_BY_WX" }
		end
	end
	defines "__WX__"

	configuration "Debug"
		defines { "__WXDEBUG__" }
	configuration( {} )

	if _OPTIONS["wx-shared"] then
		defines { "WXUSINGDLL" }
	end

	if ActionUsesMSVC() then
		defines { "wxUSE_NO_MANIFEST=1" }
	end

	if os.is( "windows" ) then
		if ActionUsesGCC() then
			includedirs { wx.root .. "/include" } -- Needed for the resource complier.
		end

		AddSystemPath( wx.root .. "/include" )

		local toolchain = iif( ActionUsesGCC(), "gcc", "vc" ) .. wx.compilerVersion
		local linktype = iif( _OPTIONS["wx-shared"], "dll", "lib" )
		local unicodeSuffix = iif( useUnicode, "u", "" )
		local rootPrefix = iif( _ACTION == "codeblocks", "$(#WX.lib)", wx.root .. "/lib" )

		local setupHincludeDir = rootPrefix .. "/" .. toolchain .. "_" .. linktype .. "/msw" .. unicodeSuffix
		local setupHincludeDir64 = setupHincludeDir:gsub( "/lib", "/lib64" )
		local libDir = rootPrefix .. "/" .. toolchain .. "_" .. linktype
		local libDir64 = libDir:gsub( "/lib", "/lib64" )

		configuration { "Debug", "not x64" }
			AddSystemPath( setupHincludeDir .. "d" )

		configuration { "Release", "not x64" }
			AddSystemPath( setupHincludeDir )

		configuration { "Debug", "x64" }
			AddSystemPath( setupHincludeDir64 .. "d" )

		configuration { "Release", "x64" }
			AddSystemPath( setupHincludeDir64 )

		configuration { "not x64" }
			libdirs { libDir }
			resoptions( "-D__i386__" )

		configuration { "x64" }
			libdirs { libDir64 }

		-- Set wxWidgets libraries to link. The order we insert matters for the linker.
		local wxLibs = { "wxmsw" .. wx.version .. unicodeSuffix, "wxexpat", "wxjpeg", "wxpng", "wxregex" .. unicodeSuffix, "wxtiff", "wxzlib" }
		if 30 <= tonumber( wx.version ) then
			wxLibs[ #wxLibs + 1 ] = "wxscintilla"
		end

		configuration { "Debug", "not StaticLib" }
			for _, lib in ipairs( wxLibs ) do
				links { lib .. "d" }
			end

		configuration { "Release", "not StaticLib" }
			for _, lib in ipairs( wxLibs ) do
				links { lib }
			end

		configuration { "not StaticLib" }
			local winLibs =
			{
				"wsock32", "comctl32", "psapi", "ws2_32", "opengl32",
				"ole32", "winmm", "oleaut32", "odbc32", "advapi32",
				"oleaut32", "uuid", "rpcrt4", "gdi32", "comdlg32",
				"winspool", "shell32", "kernel32"
			}

			if ActionUsesMSVC() then
				table.insert( winLibs, { "gdiplus" } )
			end

			for _, lib in ipairs( winLibs) do
				links { lib }
			end

		configuration( {} )

		-- Set the Windows defines.
		defines { "__WXMSW__" }

		configuration( {} )

		if not wx.hasCopiedDlls and _OPTIONS["wx-shared"] then
			local isx64 = presets.SolutionHasPlatform("x64")
			local runtimePrefix = wx.root .. "\\" .. iif( isx64, "lib64", "lib" ) .. "\\" .. toolchain .. "_" .. linktype .. "\\wxmsw" .. wx.version .. unicodeSuffix
			local runtimeSuffix = "_" .. toolchain .. iif( isx64 and ActionUsesMSVC() and 30 <= tonumber( wx.version ), "_x64", "" ) .. ".dll"

			presets.CopyFile( runtimePrefix .. runtimeSuffix, SolutionTargetDir() )
			presets.CopyFile( runtimePrefix .. "d" .. runtimeSuffix, SolutionTargetDir() )

			wx.hasCopiedDlls = true
		end

	else -- not windows

		excludes "**.rc"

		-- Set wxWidgets Debug build/link options.
		configuration { "Debug" }
			ProcessLinks( true )
			ProcessBuildOptions( true )

		-- Set the wxWidgets Release build/link options.
		configuration { "Release" }
			ProcessLinks( false )
			ProcessBuildOptions( false )

		-- Set the Linux defines.
		configuration( {} )
		if os.is( "linux" ) then
			defines "__WXGTK__"
		elseif os.is( "macosx" ) then
			defines "__WXMAC__"
		else
			error( "This operating system is not currently supported for wxWidgets configuration" )
		end
	end

	configuration( {} )
end

function wx.PosixLibName( targetName, isDebug )
	local dbg = isDebug or false
	local debug = "no"
	if dbg then debug = "yes" end

	return
end

function wx.LibName( targetName, isDebug )
	local name = ""
	-- Make the parameters optional.
	local debug = ""
	local unicode = iif( UseUnicode(), "u", "" )
	local wx_ver = wx.version
	if isDebug then debug = "d" end

	if "windows" == os.get() then
		local monolithic = ""

		if _OPTIONS["wx-shared"] then monolithic = "m" end
		name = "wxmsw" .. wx_ver .. unicode .. monolithic .. debug.. "_" .. targetName
	elseif "linux" == os.get() then
		wx_ver = wx_ver:sub( 1, 1 ).."."..wx_ver:sub( 2 )
		name = "wx_gtk2"..unicode..debug.."_"..targetName:lower().."-"..wx_ver
	else
		local debug = "no"
		if isDebug then debug = "yes" end
		name = "`wx-config --debug="..debug.." --basename`_"..targetName.."-`wx-config --release`"
	end
	return name
end

---	Configure a C/C++ package to use wxAdditions.
function wx.ConfigureAdditions( libsToLink )
	assert( type( libsToLink ) == "table", "Param1:libsToLink type missmatch, should be a table." )

	local libs = {}
	local debugLibs = {}
	for _, v in ipairs( libsToLink ) do
		local debugLibname = wx.LibName( v, true )
		table.insert( debugLibs, debugLibname )

		local libname = wx.LibName( v )
		table.insert( libs, libname )
	end

	configuration { "Debug", "not StaticLib" }
		for _, lib in ipairs( debugLibs ) do
			links { lib }
		end

	configuration { "Release", "not StaticLib" }
		for _, lib in ipairs( libs ) do
			links { lib }
		end

	configuration( {} )

	if os.is( "windows" ) then

		local wxadditionsRoot = os.getenv( "WXADDITIONS" )
		if not wxadditionsRoot then
			error( "missing the WXADDITIONS environment variable", 1 )
		end

		if not io.open( wxadditionsRoot .. "/include/wx/link_additions.h" ) then
			error( "can't find include/wx/link_additions.h! - check the value of WXADDTIIONS (" .. wxadditionsRoot .. ")" )
		end

		if tonumber( wx.version ) <= 28 then
			presets.VerifyDllVersion( wxadditionsRoot, "/lib/vc_dll/wxmsw" .. wx.version .. "_awx_vc.dll", "WXADDITIONS" )
		end

		AddSystemPath( wxadditionsRoot .. "/include" )

		local toolchain = iif( ActionUsesGCC(), "gcc", "vc" ) .. wx.compilerVersion
		local linktype = iif( _OPTIONS["wx-shared"], "dll", "lib" )

		configuration { "x64" }
			libdirs { wxadditionsRoot .. "/lib64/" .. toolchain .. "_" .. linktype }

		configuration { "not x64" }
			libdirs { wxadditionsRoot .. "/lib/" .. toolchain .. "_" .. linktype }

		configuration( {} )

		if not wx.hasCopiedAdditionsDlls and _OPTIONS["wx-shared"] then
			local runtimeLibDir = iif( presets.SolutionHasPlatform("x64"), "lib64", "lib" )

			local function BuildRuntimeName( libname )
				return wxadditionsRoot .. "\\" .. runtimeLibDir .. "\\" .. toolchain .. "_dll\\" .. libname .. "_" .. toolchain .. ".dll"
			end

			for _, lib in ipairs( libs ) do
				presets.CopyFile( BuildRuntimeName( lib ), SolutionTargetDir() )
			end

			for _, lib in ipairs( debugLibs ) do
				presets.CopyFile( BuildRuntimeName( lib ), SolutionTargetDir() )
			end
		end
	end
end
