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
addoption( "qt-shared", "Link against Qt as a shared library" )
addoption( "qt-copy-debug", "Will copy the debug versions of the Qt libraries if copyDynamicLibraries is true for qt.Configure" )
addoption( "qt-use-keywords", "Allow use of qt kewords (incompatible with Boost)" )

local QT_VC2005_LIB_DIR 	= "/lib"
local QT_VC2008_LIB_DIR 	= "/lib"
local QT_MINGW_LIB_DIR 		= "/lib"
local QT_GCC_LIB_DIR 		= "/lib/gcc"

local QT_MOC_REL_PATH		= "/bin/moc"
local QT_RCC_REL_PATH		= "/bin/rcc"
local QT_UIC_REL_PATH		= "/bin/uic"

local QT_MOC_FILES_PATH		= "qt_moc"
local QT_UI_FILES_PATH		= "qt_ui"
local QT_QRC_FILES_PATH		= "qt_qrc"

local QT_LIB_PREFIX			= "Qt"

function qt.Configure( pkg, mocfiles, qrcfiles, uifiles, libsToLink, qtMajorRev, qtPrebuildPath, copyDynamicLibraries )

	if target then

		-- Determine if the user wants us to automatically copy the Qt libs to a specified location
		local shouldCopyLibs = copyDynamicLibraries

		if copyDynamicLibraries == nil then
			shouldCopyLibs = windows and options[ "qt-shared" ]
		end

		-- Figure out the relative path to the main premake project
		local QtCopyPath = string.gsub( pkg.path, "(%w+)", ".." )

		-- Extra slash for root directories
		local outdir = pkg.bindir or project.bindir
		if #QtCopyPath > 0 then
			QtCopyPath = QtCopyPath .. "/" .. outdir
		else
			QtCopyPath = outdir
		end

		-- fix windows slashes
		if windows then
			QtCopyPath = string.gsub( QtCopyPath, "([/]+)", "\\" )
		end

		if shouldCopyLibs then
			assert( windows, "You can only copy the Qt DLLs when you are building on Windows" )
			assert( options[ "qt-shared" ], "You can only copy the Qt DLLs when you enable the qt-shared option" )
			assert( QtCopyPath ~= nil, "The destination path is nil, cannot copy the Qt DLLs" )
		end

		local QT_PREBUILD_LUA_PATH	= qtPrebuildPath or "\""..os.getcwd().."/build/qtprebuild.lua".."\""

		-- Defaults
		local qtEnvSuffix = "";
		if not options["dynamic-runtime"] then
			qtEnvSuffix = qtEnvSuffix .. "STATIC"
		elseif target == "vs2008" then
			qtEnvSuffix = qtEnvSuffix .."VC9"
		elseif target == "gnu" or string.find( target or "", ".*-gcc" ) then
			qtEnvSuffix = qtEnvSuffix .."GCC"
		end

		local QT_ENV;

		if target and windows then
			local qtEnv = "QTDIR" .. qtEnvSuffix
			QT_ENV = os.getenv(qtEnv)

			-- Checks to make sure the QTDIR environment variable is set
			assert( QT_ENV ~= nil, "The " .. qtEnv .. " environment variable must be set to the QT root directory to use qtpresets.lua" )
		else
			QT_ENV = ""
		end

		libsToLink = libsToLink or { "Core" }

		if not iContainsEntry( libsToLink, "Core" ) then
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
		assert( type( pkg ) == "table", "Param1:pkg type mismatch, should be a table." )
		assert( type( libsToLink ) == "table", "Param2:pkg type mismatch, should be a table." )
		assert( type( mocfiles ) == "table", "mocfiles type mismatch, should be a table." )
		assert( type( qrcfiles ) == "table", "qrcfiles type mismatch, should be a table." )
		assert( type( uifiles ) == "table", "uifiles type mismatch, should be a table." )

		pkg.includepaths = pkg.includepaths or {}

		-- Defines
		if( options[ "qt-shared" ] ) then
			table.insert( pkg.defines, { "QT_DLL" } )
		end

		if not options["qt-use-keywords"] then
			table.insert( pkg.defines, "QT_NO_KEYWORDS" )
		end

		for _,lib in ipairs( libsToLink ) do
			if windows then
				table.insert( pkg.defines, { "QT_LARGEFILE_SUPPORT", "QT_THREAD_SUPPORT" } )
				AddSystemPath( pkg, QT_ENV.."/include/"..QT_LIB_PREFIX..lib  )
				table.insert( pkg.config["Debug"].links, { QT_LIB_PREFIX..lib.."d"..qtMajorRev } )
				table.insert( pkg.config["Release"].links, { QT_LIB_PREFIX..lib..qtMajorRev } )

				if shouldCopyLibs then
					local libname =  QT_LIB_PREFIX .. lib .. qtMajorRev .. '.dll'

					local sourcePath = '"' .. QT_ENV .. '\\bin\\' .. libname .. '"'
					local destPath = '"' .. QtCopyPath .. '\\' .. libname .. '"'

					os.mkdir( QtCopyPath )
					print( 'Copying ' .. sourcePath .. ' to ' .. destPath ); io.stdout:flush()
					local command = 'copy ' .. sourcePath .. ' "' .. destPath .. '" /B /V /Y'
					os.execute( command )

					--Copy debug versions of the Qt Libraries
					if( options[ "qt-copy-debug" ] ) then
						local libname =  QT_LIB_PREFIX .. lib .. 'd' .. qtMajorRev .. '.dll'

						local sourcePath = '"' .. QT_ENV .. '\\bin\\' .. libname .. '"'
						local destPath = '"' .. QtCopyPath .. '\\' .. libname .. '"'

						print( 'Copying ' .. sourcePath .. ' to ' .. destPath ); io.stdout:flush()
						local command = 'copy ' .. sourcePath .. ' "' .. destPath .. '" /B /V /Y'
						os.execute( command )
					end
				end

			else
				local qtLinks = QT_LIB_PREFIX .. table.concat( libsToLink, " " .. QT_LIB_PREFIX )
				qtLinks = qtLinks .. " gobject-2.0 xrender fontconfig xext x11 gthread-2.0"
				local qtLibs = "`pkg-config --libs " .. qtLinks .. "`"
				local qtFlags = "`pkg-config --cflags " .. qtLinks .. "`"

				table.insert( pkg.buildoptions, { qtFlags } )
				table.insert( pkg.linkoptions, { qtLibs } )
			end
		end

		-- Webkit has some extra dependencies
		if iContainsEntry( libsToLink, "Webkit" ) then
			local webkitDependencies = { "phonon4.dll", "QtXmlPatterns4.dll" }

			--Copy debug versions of the Qt Libraries
			if( options[ "qt-copy-debug" ] ) then
				webkitDependencies = { "phonon4.dll", "QtXmlPatterns4.dll", "phonond4.dll", "QtXmlPatternsd4.dll" }
			end

			--phonon doesn't build for MinGW
			if target == "gnu" or string.find( target or "", ".*-gcc" ) and windows then
				iRemoveEntry( webkitDependencies, "phonon4.dll" )
				iRemoveEntry( webkitDependencies, "phonond4.dll" )
			end


			for _,lib in ipairs( webkitDependencies ) do
				local sourcePath = '"' .. QT_ENV .. '\\bin\\' .. lib .. '"'
				local destPath = '"' .. QtCopyPath .. '\\' .. lib .. '"'

				print( 'Copying ' .. sourcePath .. ' to ' .. destPath )
				local command = 'copy ' .. sourcePath .. ' "' .. destPath .. '" /B /V /Y'
				os.execute( command ); io.stdout:flush()
			end
		end

		if target and  windows then
			-- Lib Paths
			if target == "vs2005" then
				table.insert( pkg.libpaths, { QT_ENV..QT_VC2005_LIB_DIR } )
			elseif target == "vs2008" then
				table.insert( pkg.libpaths, { QT_ENV..QT_VC2008_LIB_DIR } )
			elseif target == "gnu" or string.find( target or "", ".*-gcc" ) then
				table.insert( pkg.libpaths, { QT_ENV..QT_MINGW_LIB_DIR } )
			end
			-- Include Paths
			AddSystemPath( pkg, QT_ENV.."/include" )

			-- Links
			table.insert( pkg.config["Debug"].links, { "qtmaind" } )
			table.insert( pkg.config["Release"].links, { "qtmain" } )
		end

		-- Include Paths
		table.insert( pkg.includepaths, { "./"..QT_MOC_FILES_PATH, "./"..QT_UI_FILES_PATH, "./"..QT_QRC_FILES_PATH } )

		os.mkdir( QT_MOC_FILES_PATH )
		os.mkdir( QT_QRC_FILES_PATH )
		os.mkdir( QT_UI_FILES_PATH )

		local LUAEXE = "lua "

		if windows then
			LUAEXE = "lua.exe "
		end

		-- Set up Qt pre-build steps and add the future generated file paths to the pkg
		for _,file in ipairs( mocfiles ) do
			local mocFile = GetFileNameNoExtFromPath( file )
			local mocFilePath = QT_MOC_FILES_PATH.."/moc_"..mocFile..".cpp"
			table.insert( pkg.prebuildcommands, { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -moc "' .. file .. '" "' .. QT_ENV .. '"' } )
			table.insert( pkg.files, { mocFilePath } )
		end

		for _,file in ipairs( qrcfiles ) do
			local qrcFile = GetFileNameNoExtFromPath( file )
			local qrcFilePath = QT_QRC_FILES_PATH.."/qrc_"..qrcFile..".cpp"
			table.insert( pkg.prebuildcommands, { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -rcc "' .. file .. '" "' .. QT_ENV .. '"' } )
			table.insert( pkg.files, { file, qrcFilePath } )
		end

		for _,file in ipairs( uifiles ) do
			local uiFile = GetFileNameNoExtFromPath( file )
			local uiFilePath = QT_UI_FILES_PATH.."/ui_"..uiFile..".h"
			table.insert( pkg.prebuildcommands, { LUAEXE .. QT_PREBUILD_LUA_PATH .. ' -uic "' .. file .. '" "' .. QT_ENV .. '"' } )
			table.insert( pkg.files, { file, uiFilePath } )
		end
	end

end
