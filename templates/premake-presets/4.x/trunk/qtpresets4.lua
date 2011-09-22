-- ----------------------------------------------------------------------------
--	Author:		Kyle Hendricks <kyle.hendricks@gentex.com>
--	Author:		Josh Lareau <joshua.lareau@gentex.com>
--	Date:		08/19/2010
--	Version:	1.1.0
--	Title:		Qt Premake presets
-- ----------------------------------------------------------------------------

-- Namespace
qt = {}
qt.version = "4" -- default Qt version

-- Package Options
newoption {
	trigger = "qt-shared",
	description = "Link against Qt as a shared library"
}

newoption {
	trigger = "qt-copy-debug",
	description = "Will copy the debug versions of the Qt libraries if copyDynamicLibraries is true for qt.Configure"
}

newoption {
	trigger = "qt-use-keywords",
	description = "Allow use of qt kewords (incompatible with Boost)"
}

newoption {
	trigger = "qt-adtf-support",
	description = "Updated Qt paths to use version for ADTF support for Linux"
}

local QT_VC2005_LIB_DIR 	= "/lib"
local QT_VC2008_LIB_DIR 	= "/lib"
local QT_VC2010_LIB_DIR 	= "/lib"
local QT_MINGW_LIB_DIR 		= "/lib"
local QT_GCC_LIB_DIR 		= "/lib/gcc"

local QT_MOC_REL_PATH		= "/bin/moc"
local QT_RCC_REL_PATH		= "/bin/rcc"
local QT_UIC_REL_PATH		= "/bin/uic"

local QT_MOC_FILES_PATH		= "qt_moc"
local QT_UI_FILES_PATH		= "qt_ui"
local QT_QRC_FILES_PATH		= "qt_qrc"

local QT_LIB_PREFIX			= "Qt"

function qt.Configure( mocfiles, qrcfiles, uifiles, libsToLink, qtMajorRev, qtPrebuildPath, copyDynamicLibraries )

	if _ACTION then

		-- Determine if the user wants us to automatically copy the Qt libs to a specified location
		local shouldCopyLibs = _ACTION and copyDynamicLibraries

		if copyDynamicLibraries == nil then
			shouldCopyLibs = _ACTION and os.is("windows") and _OPTIONS[ "qt-shared" ]
		end

		-- Figure out the relative path to the main premake project
		local QtCopyPath = SolutionTargetDir()

		-- fix windows slashes
		if os.is("windows") then
			QtCopyPath = string.gsub( QtCopyPath, "([/]+)", "\\" )
		end

		if shouldCopyLibs then
			assert( os.is("windows"), "You can only copy the Qt DLLs when you are building on Windows" )
			assert( _OPTIONS[ "qt-shared" ], "You can only copy the Qt DLLs when you enable the qt-shared option" )
			assert( QtCopyPath ~= nil, "The destination path is nil, cannot copy the Qt DLLs" )
		end

		local QT_PREBUILD_LUA_PATH	= qtPrebuildPath or '"'..solution().basedir.."/build/qtprebuild.lua"..'"'

		-- Defaults
		local qtEnvSuffix = "";
		if not _OPTIONS["dynamic-runtime"] then
			qtEnvSuffix = qtEnvSuffix .. "STATIC"
		elseif _ACTION == "vs2008" then
			qtEnvSuffix = qtEnvSuffix .."VC9"
		elseif _ACTION == "vs2010" then
			qtEnvSuffix = qtEnvSuffix .."VC10"
		elseif _ACTION == "gmake" or _ACTION == "codelite" or _ACTION == "codeblocks" then
			qtEnvSuffix = qtEnvSuffix .."GCC"
		end

		local QT_ENV;

		if _ACTION and os.is("windows") then
			local qtEnv = "QTDIR" .. qtEnvSuffix
			QT_ENV = os.getenv(qtEnv)

			-- Checks to make sure the QTDIR environment variable is set
			assert( QT_ENV ~= nil, "The " .. qtEnv .. " environment variable must be set to the QT root directory to use qtpresets.lua" )
		else
			QT_ENV = ""
		end

		libsToLink = libsToLink or { "Core" }

		if not table.contains( libsToLink, "Core" ) then
			table.insert( libsToLink, "Core" )
		end

		mocfiles = mocfiles or {}
		qrcfiles = qrcfiles or {}
		uifiles = uifiles or {}
		qtMajorRev = qtMajorRev or qt.version

		Flatten( mocfiles )
		Flatten( qrcfiles )
		Flatten( uifiles )

		-- Check Parameters
		assert( type( libsToLink ) == "table", "libsToLink type mismatch, should be a table." )
		assert( type( mocfiles ) == "table", "mocfiles type mismatch, should be a table." )
		assert( type( qrcfiles ) == "table", "qrcfiles type mismatch, should be a table." )
		assert( type( uifiles ) == "table", "uifiles type mismatch, should be a table." )

		-- Defines
		if( _OPTIONS[ "qt-shared" ] ) then
			defines { "QT_DLL" }
		end

		if not _OPTIONS["qt-use-keywords"] then
			defines { "QT_NO_KEYWORDS" }
		end

		-- Include Paths
		includedirs { "./"..QT_MOC_FILES_PATH, "./"..QT_UI_FILES_PATH, "./"..QT_QRC_FILES_PATH }

		os.mkdir( QT_MOC_FILES_PATH )
		os.mkdir( QT_QRC_FILES_PATH )
		os.mkdir( QT_UI_FILES_PATH )

		local LUAEXE = "lua "

		if os.is("windows") then
			LUAEXE = "lua.exe "
		end

		-- Set up Qt pre-build steps and add the future generated file paths to the pkg
		for _,file in ipairs( mocfiles ) do
			local mocFile = GetFileNameNoExtFromPath( file )
			local mocFilePath = QT_MOC_FILES_PATH.."/moc_"..mocFile..".cpp"
			prebuildcommands { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -moc "' .. file .. '" "' .. QT_ENV .. '"' }
			files { mocFilePath }
		end

		for _,file in ipairs( qrcfiles ) do
			local qrcFile = GetFileNameNoExtFromPath( file )
			local qrcFilePath = QT_QRC_FILES_PATH.."/qrc_"..qrcFile..".cpp"
			prebuildcommands { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -rcc "' .. file .. '" "' .. QT_ENV .. '"' }
			files { file, qrcFilePath }
		end

		for _,file in ipairs( uifiles ) do
			local uiFile = GetFileNameNoExtFromPath( file )
			local uiFilePath = QT_UI_FILES_PATH.."/ui_"..uiFile..".h"
			prebuildcommands { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -uic "' .. file .. '" "' .. QT_ENV .. '"' }
			files { file, uiFilePath }
		end

		if os.is("windows") then
			defines { "QT_LARGEFILE_SUPPORT", "QT_THREAD_SUPPORT" }

			-- Lib Paths
			if "vs2005" == _ACTION then
				libdirs { QT_ENV..QT_VC2005_LIB_DIR }
			elseif "vs2008" == _ACTION then
				libdirs { QT_ENV..QT_VC2008_LIB_DIR }
			elseif "vs2010" == _ACTION then
				libdirs { QT_ENV..QT_VC2010_LIB_DIR }
			elseif ActionUsesGCC() then
				libdirs { QT_ENV..QT_MINGW_LIB_DIR }
			end
			-- Include Paths
			AddSystemPath( QT_ENV.."/include" )

			local libsToCopy = libsToLink;
			local debugLibsToLink = {}
			local releaseLibsToLink = {}

			for _, lib in ipairs( libsToLink ) do
				AddSystemPath( QT_ENV.."/include/"..QT_LIB_PREFIX..lib  )
				table.insert( debugLibsToLink, QT_LIB_PREFIX..lib.."d"..qtMajorRev )
				table.insert( releaseLibsToLink, QT_LIB_PREFIX..lib..qtMajorRev )
			end

			if shouldCopyLibs then

				local destPath = '"' .. QtCopyPath .. '"'

				-- Webkit has some extra dependencies
				if table.contains( libsToLink, "Webkit" ) then
					table.insert( libsToCopy, "XmlPatterns" )

					--phonon doesn't build for MinGW
					if not ActionUsesGCC() then

						local phononSourcePath = '"' .. QT_ENV .. '\\bin\\' .. 'phonon4.dll' .. '"'
						WindowsCopy( phononSourcePath, destPath )

						if( _OPTIONS[ "qt-copy-debug" ] ) then
							phononSourcePath = '"' .. QT_ENV .. '\\bin\\' .. 'phonond4.dll' .. '"'
							WindowsCopy( phononSourcePath, destPath )
						end
					end
				end


				for _, lib in ipairs( libsToCopy ) do
					local libname =  QT_LIB_PREFIX .. lib .. qtMajorRev .. '.dll'
					local sourcePath = '"' .. QT_ENV .. '\\bin\\' .. libname .. '"'
					WindowsCopy( sourcePath, destPath )

					--Copy debug versions of the Qt Libraries
					if( _OPTIONS[ "qt-copy-debug" ] ) then
						local libnamed =  QT_LIB_PREFIX .. lib .. 'd' .. qtMajorRev .. '.dll'
						local sourcePathd = '"' .. QT_ENV .. '\\bin\\' .. libnamed .. '"'
						WindowsCopy( sourcePathd, destPath )
					end
				end
			end

			if _ACTION:find("vs") then
				buildoptions( "/wd4127" ) -- conditional expression is constant
			end

			if ActionUsesGCC() then
				configuration "Debug"
					for _, v in ipairs( debugLibsToLink ) do
						linkoptions( "-l:" .. v .. ".dll" )
					end
					linkoptions( "-lqtmaind" )

				configuration "Release"
					for _, v in ipairs( releaseLibsToLink ) do
						linkoptions( "-l:" .. v .. ".dll" )
					end
					linkoptions( "-lqtmain" )
			else
				configuration "Debug"
					links( debugLibsToLink )
					links( "qtmaind" )

				configuration "Release"
					links( releaseLibsToLink )
					links( "qtmain" )
			end

			-- Links
			configuration {} -- reset configuration

		else
			local pkgConfigPath = ""
			if ( _OPTIONS["qt-adtf-support"] ) then
				pkgConfigPath = "export PKG_CONFIG_PATH=/opt/adtf/qt/qt/lib/pkgconfig && "
			end
			
			local qtLinks = QT_LIB_PREFIX .. table.concat( libsToLink, " " .. QT_LIB_PREFIX )
			qtLinks = qtLinks .. " gobject-2.0 xrender fontconfig xext x11 gthread-2.0"

			local qtLibs = pkgConfigPath .. "pkg-config --libs " .. qtLinks
			local qtFlags = pkgConfigPath .. "pkg-config --cflags " .. qtLinks
			local libPipe = io.popen( qtLibs, 'r' )
			local flagPipe= io.popen( qtFlags, 'r' )

			qtLibs = libPipe:read( '*line' )
			qtFlags = flagPipe:read( '*line' )
			libPipe:close()
			flagPipe:close()

			buildoptions { qtFlags }
			linkoptions { qtLibs }
		end
	end

end

function GetFileNameNoExtFromPath( path )

	local i = 0
	local lastSlash = 0
	local lastPeriod = 0
	local returnFilename
	while true do
		i = string.find( path, "/", i+1 )
		if i == nil then break end
		lastSlash = i
	end

	i = 0

	while true do
		i = string.find( path, "%.", i+1 )
		if i == nil then break end
		lastPeriod = i
	end

	if lastPeriod < lastSlash then
		returnFilename = path:sub( lastSlash + 1 )
	else
		returnFilename = path:sub( lastSlash + 1, lastPeriod - 1 )
	end

	return returnFilename
end

function Flatten(t)
        local tmp = {}
        for si,sv in ipairs(t) do
			if type( sv ) == "table" then
                for _,v in ipairs(sv) do
                        table.insert(tmp, v)
                end
			elseif type( sv ) == "string" then
				table.insert( tmp, sv )
			end
                t[si] = nil
        end
        for _,v in ipairs(tmp) do
                table.insert(t, v)
        end
end
