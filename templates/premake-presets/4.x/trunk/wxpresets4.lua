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

-- Namespace
wx = {}

if "windows" == os.get() then
	wx.root = os.getenv( "WXWIN" )
	if not wx.root then
		error( "missing the WXWIN environment variable" )
	end
end

---	Configure a C/C++ package to use wxWidgets
--	wx.Configure( package, shouldSetTarget = true, wxVer = "28" )
function wx.Configure( shouldSetTarget, wxVer, copyDlls )
	-- Set the default values.
	if shouldSetTarget == nil then shouldSetTarget = true end
	local targetName = project().name
	local wx_ver = wxVer or "28"

	-- Set the defines.
	if _OPTIONS["unicode"] then
		defines { "wxUSE_UNICODE" }
	end
	defines "__WX__"

	configuration "Debug"
		defines { "__WXDEBUG__" }
	configuration( {} )

	if _OPTIONS["wx-shared"] then
		defines { "WXUSINGDLL" }
	end

	if _ACTION == "vs2005" or _ACTION == "vs2008" or _ACTION == "vs2010" then
		--linkoptions { "/MANIFEST:NO" }
		defines { "wxUSE_NO_MANIFEST=1" } -- Not needed in wxWidgets 2.8.8.
	end

	local kindVal = presets.GetCustomValue( "kind" ) or ""

	if "windows" == os.get() then
		-- ******* WINDOWS SETUP ***********
		-- *	Settings that are Windows specific.
		-- *********************************

		-- Set wxWidgets include paths
		if _ACTION == "cb-gcc" then
			-- Needed for the resource complier.
			includedirs { "$(#WX.include)" }
			buildoptions { "-isystem $(#WX.include)" }
		elseif _ACTION == "cl-gcc" then
			-- Needed for the resource complier.
			includedirs { wx.root .. "/include" }
			buildoptions { "-isystem " .. wx.root .. "/include" }
		elseif _ACTION == "gmake" then
			-- Needed for the resource complier.
			includedirs { wx.root .. "/include" }
			buildoptions { "-isystem \"" .. wx.root .. "/include\"" }
		else
			includedirs { wx.root .. "/include" }
		end

		-- Set the correct 'setup.h' include path.
		if _OPTIONS["unicode"] then
			if _ACTION == "codeblocks" then
				if _OPTIONS["wx-shared"] then
					configuration "Debug"
						includedirs { "$(#WX.lib)/gcc_dll/mswud" }
					configuration "Release"
						includedirs { "$(#WX.lib)/gcc_dll/mswu" }
				else
					configuration "Debug"
						includedirs { "$(#WX.lib)/gcc_lib/mswud" }
					configuration "Release"
						includedirs { "$(#WX.lib)/gcc_lib/mswu" }
				end
			elseif ActionUsesGCC() then
				if _OPTIONS["wx-shared"] then
					configuration "Debug"
						includedirs { wx.root .. "/lib/gcc_dll/mswud" }
					configuration "Release"
						includedirs { wx.root .. "/lib/gcc_dll/mswu" }
				else
					configuration "Debug"
						includedirs { wx.root .. "/lib/gcc_lib/mswud" }
					configuration "Release"
						includedirs { wx.root .. "/lib/gcc_lib/mswu" }
				end
			else
				if _OPTIONS["wx-shared"] then
					configuration "Debug"
						includedirs { wx.root .. "/lib/vc_dll/mswud" }
					configuration "Release"
						includedirs { wx.root .. "/lib/vc_dll/mswu" }
				else
					configuration "Debug"
						includedirs { wx.root .. "/lib/vc_lib/mswud" }
					configuration "Release"
						includedirs { wx.root .. "/lib/vc_lib/mswu" }
				end
			end
		else
			if _ACTION == "codeblocks" then
				if _OPTIONS["wx-shared"] then
					configuration "Debug"
						includedirs { "$(#WX.lib)/gcc_dll/mswd" }
					configuration "Release"
						includedirs { "$(#WX.lib)/gcc_dll/msw" }
				else
					configuration "Debug"
						includedirs { "$(#WX.lib)/gcc_lib/mswd" }
					configuration "Release"
						includedirs { "$(#WX.lib)/gcc_lib/msw" }
				end
			elseif ActionUsesGCC() then
				if _OPTIONS["wx-shared"] then
					configuration "Debug"
						includedirs { wx.root .. "/lib/gcc_dll/mswd" }
					configuration "Release"
						includedirs { wx.root .. "/lib/gcc_dll/msw" }
				else
					configuration "Debug"
						includedirs { wx.root .. "/lib/gcc_lib/mswd" }
					configuration "Release"
						includedirs { wx.root .. "/lib/gcc_lib/msw" }
				end
			else
				if _OPTIONS["wx-shared"] then
					configuration "Debug"
						includedirs { wx.root .. "/lib/vc_dll/mswd" }
					configuration "Release"
						includedirs { wx.root .. "/lib/vc_dll/msw" }
				else
					configuration "Debug"
						includedirs { wx.root .. "/lib/vc_lib/mswd" }
					configuration "Release"
						includedirs { wx.root .. "/lib/vc_lib/msw" }
				end
			end
		end
		configuration( {} )

		-- Set the linker options.
		local winWxRuntimePath = wx.root .. "\\lib\\gcc_dll\\"

		if _ACTION == "codeblocks" then
			if _OPTIONS["wx-shared"] then
				libdirs { "$(#WX.lib)/gcc_dll" }
			else
				libdirs { "$(#WX.lib)/gcc_lib" }
			end
		elseif ActionUsesGCC() then
			if _OPTIONS["wx-shared"] then
				libdirs { wx.root .. "/lib/gcc_dll" }
			else
				libdirs { wx.root .. "/lib/gcc_lib" }
			end
		else
			winWxRuntimePath = wx.root .. "\\lib\\vc_dll\\"
			if _OPTIONS["wx-shared"] then
				libdirs { wx.root .. "/lib/vc_dll" }
			else
				libdirs { wx.root .. "/lib/vc_lib" }
			end
		end
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

		-- Set wxWidgets libraries to link. The order we insert matters for the linker.
		local releaseWxRuntimeName = "wxmsw"..wx_ver
		local debugWxRuntimeName = "wxmsw"..wx_ver
		if _OPTIONS["unicode"] then
			releaseWxRuntimeName = releaseWxRuntimeName .. "u"
			debugWxRuntimeName = debugWxRuntimeName .. "ud"
			configuration { "Debug" }
				links { debugWxRuntimeName, "wxexpatd", "wxjpegd", "wxpngd", "wxregexud", "wxtiffd", "wxzlibd" }
				for _, lib in ipairs( winLibs) do
					links { lib }
				end
			configuration { "Release" }
				links { releaseWxRuntimeName, "wxexpat", "wxjpeg", "wxpng", "wxregexu", "wxtiff", "wxzlib" }
				for _, lib in ipairs( winLibs) do
					links { lib }
				end
		else
			debugWxRuntimeName = debugWxRuntimeName .. "d"
			configuration { "Debug" }
				links { debugWxRuntimeName, "wxexpatd", "wxjpegd", "wxpngd", "wxregexd",	"wxtiffd", "wxzlibd" }
				for _, lib in ipairs( winLibs) do
					links { lib }
				end
			configuration { "Release" }
				links { releaseWxRuntimeName, "wxexpat", "wxjpeg", "wxpng", "wxregex",	"wxtiff", "wxzlib" }
				for _, lib in ipairs( winLibs) do
					links { lib }
				end
		end

		configuration( {} )

		if ActionUsesGCC() then
			releaseWxRuntimeName = releaseWxRuntimeName .. "_gcc"
			debugWxRuntimeName = debugWxRuntimeName .. "_gcc"
		elseif ActionUsesMSVC() then
			releaseWxRuntimeName = releaseWxRuntimeName .. "_vc"
			debugWxRuntimeName = debugWxRuntimeName .. "_vc"
		end

		releaseWxRuntimeName = releaseWxRuntimeName .. ".dll"
		debugWxRuntimeName = debugWxRuntimeName .. ".dll"

		-- Set the Windows defines.
		defines { "__WXMSW__" }
		-- Set the targets.
		if shouldSetTarget then
			if not ( kindVal == "WindowedApp" or kindVal == "ConsoleApp" ) then
				if ActionUsesGCC() then
					if _OPTIONS["unicode"] then
						configuration { "Debug" }
							targetdir { "wxmsw"..wx_ver.."umd_"..targetName.."_gcc" }
						configuration { "Release" }
							targetdir { "wxmsw"..wx_ver.."um_"..targetName.."_gcc" }
					else
						configuration { "Debug" }
							targetdir { "wxmsw"..wx_ver.."md_"..targetName.."_gcc" }
						configuration { "Release" }
							targetdir { "wxmsw"..wx_ver.."m_"..targetName.."_gcc" }
					end
				else
					if _OPTIONS["unicode"] then
						configuration { "Debug" }
							targetdir { "wxmsw"..wx_ver.."umd_"..targetName.."_vc" }
						configuration { "Release" }
							targetdir { "wxmsw"..wx_ver.."um_"..targetName.."_vc" }
					else
						configuration { "Debug" }
							targetdir { "wxmsw"..wx_ver.."md_"..targetName.."_vc" }
						configuration { "Release" }
							targetdir { "wxmsw"..wx_ver.."m_"..targetName.."_vc" }
					end
				end
			end
		end
		configuration( {} )

		if _OPTIONS["wx-shared"] or copyDlls then
			WindowsCopy( winWxRuntimePath .. releaseWxRuntimeName, SolutionTargetDir() )
			WindowsCopy( winWxRuntimePath .. debugWxRuntimeName, SolutionTargetDir() )
		end
	else
	-- ******* LINUX SETUP *************
	-- *	Settings that are Linux specific.
	-- *********************************
		-- Ignore resource files in Linux.
		excludes "**.rc"

		-- Set wxWidgets Debug build/link options.
		configuration { "Debug" }
			buildoptions { "`wx-config --debug=yes --cflags`" }
			linkoptions { "`wx-config --debug=yes --libs std, gl`" }

		-- Set the wxWidgets Release build/link options.
		configuration { "Release" }
			buildoptions { "`wx-config --debug=no --cflags`" }
			linkoptions { "`wx-config --libs std, gl`" }

		-- Set the Linux defines.
		configuration( {} )
		defines "__WXGTK__"

		-- Set the targets.
		if shouldSetTarget then
			if not ( kindVal == "WindowedApp" or kindVal == "ConsoleApp" ) then
				configuration { "Debug" }
					targetdir { wx.LibName( targetName, wxVer, true ) }	--"`wx-config --debug=yes --basename`_"..targetName.."-`wx-config --release`"
				configuration { "Release" }
					targetdir { wx.LibName( targetName, wxVer ) }	--"`wx-config --basename`_"..targetName.."-`wx-config --release`"
			end
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

function wx.LibName( targetName, wxVer, isDebug )
	local name = ""
	-- Make the parameters optional.
	local wx_ver = wxVer or "28"
	local debug = ""
	local unicode = ""
	if isDebug then debug = "d" end
	if _OPTIONS["unicode"] then unicode = "u" end

	if "windows" == os.get() then
		local monolithic = ""
		local vc8 = ""

		if _OPTIONS["wx-shared"] then monolithic = "m" end
		name = "wxmsw"..wx_ver..unicode..monolithic..debug.."_"..targetName
	elseif "linux" == os.get() then
		wx_ver = wx_ver:sub( 1, 1 ).."."..wx_ver:sub( 2 )
		name = "wx_gtk2"..unicode..debug.."_"..targetName:lower().."-"..wx_ver
		--print( name )
	else
		local debug = "no"
		if isDebug then debug = "yes" end
		name = "`wx-config --debug="..debug.." --basename`_"..targetName.."-`wx-config --release`"
	end

	return name
end

---	Configure a C/C++ package to use wxAdditions.
--	wx.ConfigureAdditions( package, { "libsToLink" }, wxVer = "28" )
function wx.ConfigureAdditions( libsToLink, wxVer )
	local wxadditionsRoot = ""
	if os.is( "windows" ) then
		wxadditionsRoot = os.getenv( "WXADDITIONS" )
		if not wxadditionsRoot then
			error( "missing the WXADDITIONS environment variable", 1 )
		end
	end
	-- Check to make sure that the package is valid.
	assert( type( libsToLink ) == "table", "Param1:libsToLink type missmatch, should be a table." )

	local winWxRuntimePath = wxadditionsRoot .. "\\lib\\gcc_dll\\"
	local dllSuffix = "_gcc.dll"
	if not ActionUsesGCC() then
		winWxRuntimePath = wxadditionsRoot .. "\\lib\\vc_dll\\"
		dllSuffix = "_vc.dll"
	end

	local wx_ver = wxVer or "28"

	if os.is( "windows" ) then
		-- Set wxAdditions include paths
		AddSystemPath( wxadditionsRoot .. "/include" )

		-- Set the linker options.
		local toolchain = iif( ActionUsesGCC(), "gcc", "vc" )
		local linktype = iif( _OPTIONS["wx-shared"], "dll", "lib" )
		libdirs { wxadditionsRoot .. "/lib/" .. toolchain .. "_" .. linktype }
	end

	-- Set wxAdditions libraries to link.
	-- wx.LibName( targetName, wxVer, isDebug )

	local libs = {}
	for _, v in ipairs( libsToLink ) do
		local libname = wx.LibName( v, wx_ver, true )
		table.insert( libs, libname )
		if _OPTIONS["wx-shared"] or copyDlls then
			WindowsCopy( winWxRuntimePath .. libname .. dllSuffix, SolutionTargetDir() )
		end
	end
	configuration { "Debug" }
		for _, lib in ipairs( libs ) do
			links { lib }
		end
	libs = {}
	for _, v in ipairs( libsToLink ) do
		local libname = wx.LibName( v, wx_ver )
		table.insert( libs, libname )
		if _OPTIONS["wx-shared"] then
			WindowsCopy( winWxRuntimePath .. libname .. dllSuffix, SolutionTargetDir() )
		end
	end
	configuration { "Release" }
		for _, lib in ipairs( libs ) do
			links { lib }
		end

	configuration( {} )
end
