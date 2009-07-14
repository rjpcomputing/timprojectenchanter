-- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		01/26/2009
--	Version:	1.20
--
--	Copyright (C) 2008-2009 Ryan Pusztai
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
--		- call wx.Configure() after your project is setup, not before.
-- ----------------------------------------------------------------------------

-- Package options
addoption( "wx-shared", "Link against wxWidgets as a shared library" )

-- Namespace
wx = {}

---	Configure a C/C++ package to use wxWidgets
--	wx.Configure( package, wxVer = "28" )
function wx.Configure( package, wxVer )
	-- Check to make sure that the package is valid.
	assert( type( package ) == "table" )
	assert( package.name, "Must specify a 'package.name' before calling ConfigureWxWidgets()" )

	-- Set the default values.
	local targetName = package.name
	local wx_ver = wxVer or "28"

	-- Set the defines.
	if options["unicode"] then
		table.insert( package.defines, { "wxUSE_UNICODE" } )
	end

	table.insert( package.defines, "__WX__" )
	table.insert( package.config["Debug"].defines, { "__WXDEBUG__" } )
	if options["wx-shared"] then
		table.insert( package.defines, { "WXUSINGDLL" } )
	end

	if target == "vs2005" or target == "vs2008" then
		--table.insert( package.linkoptions, { "/MANIFEST:NO" } )
		table.insert( package.defines, { "wxUSE_NO_MANIFEST=1" } ) -- Not needed in wxWidgets 2.8.8.
	end

	if windows then
		-- ******* WINDOWS SETUP ***********
		-- *	Settings that are Windows specific.
		-- *********************************

		-- Set wxWidgets include paths
		if target == "cb-gcc" then
			-- Needed for the resource complier.
			table.insert( package.includepaths, { "$(#WX.include)" } )
			table.insert( package.buildoptions, { "-isystem $(#WX.include)" } )
		elseif target == "cl-gcc" then
			-- Needed for the resource complier.
			table.insert( package.includepaths, { "$(WXWIN)/include" } )
			table.insert( package.buildoptions, { "-isystem $(WXWIN)/include" } )
		elseif target == "gnu" then
			-- Needed for the resource complier.
			table.insert( package.includepaths, { "$(WXWIN)/include" } )
			table.insert( package.buildoptions, { "-isystem \"$(WXWIN)/include\"" } )
		else
			table.insert( package.includepaths, { "$(WXWIN)/include" } )
		end

		-- Set the correct 'setup.h' include path.
		if options["unicode"] then
			if target == "cb-gcc" then
				if options["wx-shared"] then
					table.insert( package.config["Debug"].includepaths, { "$(#WX.lib)/gcc_dll/mswud" } )
					table.insert( package.config["Release"].includepaths, { "$(#WX.lib)/gcc_dll/mswu" } )
				else
					table.insert( package.config["Debug"].includepaths, { "$(#WX.lib)/gcc_lib/mswud" } )
					table.insert( package.config["Release"].includepaths, { "$(#WX.lib)/gcc_lib/mswu" } )
				end
			elseif target == "gnu" or target == "cl-gcc" then
				if options["wx-shared"] then
					table.insert( package.config["Debug"].includepaths, { "$(WXWIN)/lib/gcc_dll/mswud" } )
					table.insert( package.config["Release"].includepaths, { "$(WXWIN)/lib/gcc_dll/mswu" } )
				else
					table.insert( package.config["Debug"].includepaths, { "$(WXWIN)/lib/gcc_lib/mswud" } )
					table.insert( package.config["Release"].includepaths, { "$(WXWIN)/lib/gcc_lib/mswu" } )
				end
			else
				if options["wx-shared"] then
					table.insert( package.config["Debug"].includepaths, { "$(WXWIN)/lib/vc_dll/mswud" } )
					table.insert( package.config["Release"].includepaths, { "$(WXWIN)/lib/vc_dll/mswu" } )
				else
					table.insert( package.config["Debug"].includepaths, { "$(WXWIN)/lib/vc_lib/mswud" } )
					table.insert( package.config["Release"].includepaths, { "$(WXWIN)/lib/vc_lib/mswu" } )
				end
			end
		else
			if target == "cb-gcc" then
				if options["wx-shared"] then
					table.insert( package.config["Debug"].includepaths, { "$(#WX.lib)/gcc_dll/mswd" } )
					table.insert( package.config["Release"].includepaths, { "$(#WX.lib)/gcc_dll/msw" } )
				else
					table.insert( package.config["Debug"].includepaths, { "$(#WX.lib)/gcc_lib/mswd" } )
					table.insert( package.config["Release"].includepaths, { "$(#WX.lib)/gcc_lib/msw" } )
				end
			elseif target == "gnu" or target == "cl-gcc" then
				if options["wx-shared"] then
					table.insert( package.config["Debug"].includepaths, { "$(WXWIN)/lib/gcc_dll/mswd" } )
					table.insert( package.config["Release"].includepaths, { "$(WXWIN)/lib/gcc_dll/msw" } )
				else
					table.insert( package.config["Debug"].includepaths, { "$(WXWIN)/lib/gcc_lib/mswd" } )
					table.insert( package.config["Release"].includepaths, { "$(WXWIN)/lib/gcc_lib/msw" } )
				end
			else
				if options["wx-shared"] then
					table.insert( package.config["Debug"].includepaths, { "$(WXWIN)/lib/vc_dll/mswd" } )
					table.insert( package.config["Release"].includepaths, { "$(WXWIN)/lib/vc_dll/msw" } )
				else
					table.insert( package.config["Debug"].includepaths, { "$(WXWIN)/lib/vc_lib/mswd" } )
					table.insert( package.config["Release"].includepaths, { "$(WXWIN)/lib/vc_lib/msw" } )
				end
			end
		end

		-- Set the linker options.
		if target == "cb-gcc" then
			if options["wx-shared"] then
				table.insert( package.libpaths, { "$(#WX.lib)/gcc_dll" } )
			else
				table.insert( package.libpaths, { "$(#WX.lib)/gcc_lib" } )
			end
		elseif target == "gnu" or target == "cl-gcc" then
			if options["wx-shared"] then
				table.insert( package.libpaths, { "$(WXWIN)/lib/gcc_dll" } )
			else
				table.insert( package.libpaths, { "$(WXWIN)/lib/gcc_lib" } )
			end
		else
			if options["wx-shared"] then
				table.insert( package.libpaths, { "$(WXWIN)/lib/vc_dll" } )
			else
				table.insert( package.libpaths, { "$(WXWIN)/lib/vc_lib" } )
			end
		end

		local winLibs =
		{
			"wsock32", "comctl32", "psapi", "ws2_32", "opengl32",
			"ole32", "winmm", "oleaut32", "odbc32", "advapi32",
			"oleaut32", "uuid", "rpcrt4", "gdi32", "comdlg32",
			"winspool", "shell32", "kernel32"
		}
		if string.find( target or "", "vs.*" ) then
			table.insert( winLibs, { "gdiplus" } )
		end

		-- Set wxWidgets libraries to link. The order we insert matters for the linker.
		if options["unicode"] then
			table.insert( package.config["Debug"].links, { "wxmsw"..wx_ver.."ud", "wxexpatd", "wxjpegd", "wxpngd",
												"wxregexud", "wxtiffd", "wxzlibd" } )
			table.insert( package.config["Debug"].links, winLibs )
			table.insert( package.config["Release"].links, { "wxmsw"..wx_ver.."u", "wxexpat", "wxjpeg", "wxpng", "wxregexu",
												"wxtiff", "wxzlib" } )
			table.insert( package.config["Release"].links, winLibs )
		else
			table.insert( package.config["Debug"].links, { "wxmsw"..wx_ver.."d", "wxexpatd", "wxjpegd", "wxpngd", "wxregexd",
												"wxtiffd", "wxzlibd" } )
			table.insert( package.config["Debug"].links, winLibs )
			table.insert( package.config["Release"].links, { "wxmsw"..wx_ver, "wxexpat", "wxjpeg", "wxpng", "wxregex",
												"wxtiff", "wxzlib" } )
			table.insert( package.config["Release"].links, winLibs )
		end

		-- Set the Windows defines.
		table.insert( package.defines, { "__WXMSW__" } )

		-- Set the targets.
		if string.len( package.target or "" ) <= 0 then
			if not ( package.kind == "winexe" or package.kind == "exe" ) then
				if string.find( target or "", ".*-gcc" ) or target == "gnu" then
					if options["unicode"] then
						package.config["Debug"].target = "wxmsw"..wx_ver.."umd_"..targetName.."_gcc"
						package.config["Release"].target = "wxmsw"..wx_ver.."um_"..targetName.."_gcc"
					else
						package.config["Debug"].target = "wxmsw"..wx_ver.."md_"..targetName.."_gcc"
						package.config["Release"].target = "wxmsw"..wx_ver.."m_"..targetName.."_gcc"
					end
				else
					if options["unicode"] then
						package.config["Debug"].target = "wxmsw"..wx_ver.."umd_"..targetName.."_vc"
						package.config["Release"].target = "wxmsw"..wx_ver.."um_"..targetName.."_vc"
					else
						package.config["Debug"].target = "wxmsw"..wx_ver.."md_"..targetName.."_vc"
						package.config["Release"].target = "wxmsw"..wx_ver.."m_"..targetName.."_vc"
					end
				end
			end
		end
	else
	-- ******* LINUX SETUP *************
	-- *	Settings that are Linux specific.
	-- *********************************
		-- Ignore resource files in Linux.
		table.insert( package.excludes, matchrecursive( "*.rc" ) )

		-- Set wxWidgets build options.
		table.insert( package.config["Debug"].buildoptions, { "`wx-config --debug=yes --cflags`" } )
		table.insert( package.config["Release"].buildoptions, { "`wx-config --debug=no --cflags`" } )

		-- Set the wxWidgets link options.
		table.insert( package.config["Debug"].linkoptions, { "`wx-config --debug=yes --libs std, gl, media`" } )
		table.insert( package.config["Release"].linkoptions, { "`wx-config --libs std, gl, media`" } )

		-- Set the Linux defines.
		table.insert( package.defines, "__WXGTK__" )

		-- Set the targets.
		if not ( package.kind == "winexe" or package.kind == "exe" ) then
			package.config["Debug"].target = "`wx-config --debug=yes --basename`_"..targetName.."-`wx-config --release`"
			package.config["Release"].target = "`wx-config --basename`_"..targetName.."-`wx-config --release`"
		end
	end
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

	if windows then
		local debug = ""
		local unicode = ""
		local monolithic = ""
		local vc8 = ""

		if options["unicode"] then unicode = "u" end
		if isDebug then debug = "d" end
		if options["wx-shared"] then monolithic = "m" end
		name = "wxmsw"..wx_ver..unicode..monolithic..debug.."_"..targetName
	else
		local debug = "no"
		if isDebug then debug = "yes" end
		name = "`wx-config --debug="..debug.." --basename`_"..targetName.."-`wx-config --release`"
	end

	return name
end

---	Configure a C/C++ package to use wxAdditions.
--	wx.ConfigureAdditions( package, { "libsToLink" }, wxVer = "28" )
function wx.ConfigureAdditions( package, libsToLink, wxVer )
	-- Check to make sure that the package is valid.
	assert( type( package ) == "table", "Param1:package type missmatch, should be a table." )
	assert( type( libsToLink ) == "table", "Param2:libsToLink type missmatch, should be a table." )

	local wx_ver = wxVer or "28"

	if ( windows ) then
		-- Set wxAdditions include paths
		if target == "gnu" or string.find( target or "", ".*-gcc" ) then
			table.insert( package.buildoptions, { "-isystem $(WXADDITIONS)/include" } )
		else
			table.insert( package.includepaths, { "$(WXADDITIONS)/include" } )
		end

		-- Set the linker options.
		if target == "gnu" or string.find( target or "", ".*-gcc" ) then
			if options["wx-shared"] then
				table.insert( package.libpaths, { "$(WXADDITIONS)/lib/gcc_dll" } )
			else
				table.insert( package.libpaths, { "$(WXADDITIONS)/lib/gcc_lib" } )
			end
		else
			if options["wx-shared"] then
				table.insert( package.libpaths, { "$(WXADDITIONS)/lib/vc_dll" } )
			else
				table.insert( package.libpaths, { "$(WXADDITIONS)/lib/vc_lib" } )
			end
		end
	end

	-- Set wxAdditions libraries to link.
	-- wx.LibName( targetName, wxVer, isDebug )
	local libs = {}
	for _, v in ipairs( libsToLink ) do table.insert( libs, wx.LibName( v, wx_ver, true ) ) end
	table.insert( package.config["Debug"].links, libs )
	libs = {}
	for _, v in ipairs( libsToLink ) do table.insert( libs, wx.LibName( v, wx_ver ) ) end
	table.insert( package.config["Release"].links, libs )
end
