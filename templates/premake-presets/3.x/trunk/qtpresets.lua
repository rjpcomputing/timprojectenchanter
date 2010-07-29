-- ----------------------------------------------------------------------------
--	Author:		Kyle Hendricks <kyle.hendricks@gentex.com>
--	Date:		03/31/2010
--	Version:	1.00
--	Title:		Qt Premake presets
-- ----------------------------------------------------------------------------

-- Namespace
qt = {}

-- Package Options
addoption( "qt-shared", "Link against Qt as a shared library" )

local QT_VC2005_LIB_DIR 	= "/lib"
local QT_VC2008_LIB_DIR 	= "/lib"
local QT_MINGW_LIB_DIR 		= "/lib/mingw"
local QT_GCC_LIB_DIR 		= "/lib/gcc"

local QT_MOC_REL_PATH		= "/bin/moc"
local QT_RCC_REL_PATH		= "/bin/rcc"
local QT_UIC_REL_PATH		= "/bin/uic"

local QT_MOC_FILES_PATH		= "qt_moc"
local QT_UI_FILES_PATH		= "qt_ui"
local QT_QRC_FILES_PATH		= "qt_qrc"

local QT_LIB_PREFIX			= "Qt"

function qt.Configure( package, mocfiles, qrcfiles, uifiles, libsToLink, qtMajorRev, qtPrebuildPath )

	local QT_PREBUILD_LUA_PATH	= qtPrebuildPath or "\""..os.getcwd().."/build/qtprebuild.lua".."\""


	-- Defaults
	local qtEnvSuffix = "";
	if not options["dynamic-runtime"] then
		qtEnvSuffix = qtEnvSuffix .. "STATIC"
	elseif target == "vs2008" then
		qtEnvSuffix = qtEnvSuffix .."VC9"
	end

	local QT_ENV;

	if windows then
		local qtEnv = "QTDIR" .. qtEnvSuffix
		QT_ENV = os.getenv(qtEnv)

		--Checks to make sure the QTDIR environment variable is set
		assert( QT_ENV ~= nil, "The " .. qtEnv .. " environment variable must be set to the QT root directory to use qtpresets.lua" )
	end

	libsToLink = libsToLink or { "Core" }

	if not iContainsEntry( libsToLink, "Core" ) then
		table.insert( libsToLink, "Core" )
	end

	mocfiles = mocfiles or {}
	qrcfiles = qrcfiles or {}
	uifiles = uifiles or {}
	qtMajorRev = qtMajorRev or "4"

	Flatten( mocfiles )
	Flatten( qrcfiles )
	Flatten( uifiles )

	-- Check Parameters
	assert( type( package ) == "table", "Param1:package type mismatch, should be a table." )
	assert( type( libsToLink ) == "table", "Param2:package type mismatch, should be a table." )

	assert( type( mocfiles ) == "table", "mocfiles type mismatch, should be a table." )
	assert( type( qrcfiles ) == "table", "qrcfiles type mismatch, should be a table." )
	assert( type( uifiles ) == "table", "uifiles type mismatch, should be a table." )

	package.includepaths = package.includepaths or {}

	-- Defines
	if( options[ "qt-shared" ] ) then
		table.insert( package.defines, { "WX_DLL" } )
	end

	table.insert( package.defines, { "QT_LARGEFILE_SUPPORT", "QT_THREAD_SUPPORT", "QT_NO_KEYWORDS" } )

	for _,lib in ipairs( libsToLink ) do
		if windows then
			table.insert( package.includepaths, { QT_ENV.."/include/"..QT_LIB_PREFIX..lib } )
			table.insert( package.config["Debug"].links, { QT_LIB_PREFIX..lib.."d"..qtMajorRev } )
			table.insert( package.config["Release"].links, { QT_LIB_PREFIX..lib..qtMajorRev } )
		else
			table.insert( package.includepaths, { "/usr/include/qt" .. qtMajorRev .. "/" ..QT_LIB_PREFIX .. lib } )
			table.insert( package.config["Debug"].links, { QT_LIB_PREFIX..lib.."d" } )
			table.insert( package.config["Release"].links, { QT_LIB_PREFIX..lib } )
		end
	end

	if target then
		if windows then
			-- Lib Paths
			if target == "vs2005" then
				table.insert( package.libpaths, { QT_ENV..QT_VC2005_LIB_DIR } )
			elseif target == "vs2008" then
				table.insert( package.libpaths, { QT_ENV..QT_VC2008_LIB_DIR } )
			elseif target:find( "gcc" ) then
				table.insert( package.libpaths, { QT_ENV..QT_MINGW_LIB_DIR } )
			end
			-- Include Paths
			table.insert( package.includepaths, { QT_ENV.."/include" } )

			-- Links
			table.insert( package.config["Debug"].links, { "qtmaind" } )
			table.insert( package.config["Release"].links, { "qtmain" } )
		else
			-- Include Paths
			table.insert( package.includepaths, { "/usr/include/qt" .. qtMajorRev } )

			-- Lib Paths
			table.insert( package.config["Debug"].libpaths, { "/usr/lib/debug/usr/lib" } )

			-- Links
			table.insert( package.links, { "audio", "png12", "gobject-2.0", "Xrender", "fontconfig", "Xext", "X11", "gthread-2.0" } )
		end
	end

	-- Include Paths
	table.insert( package.includepaths, { "./"..QT_MOC_FILES_PATH, "./"..QT_UI_FILES_PATH, "./"..QT_QRC_FILES_PATH } )

	os.mkdir( QT_MOC_FILES_PATH )
	os.mkdir( QT_QRC_FILES_PATH )
	os.mkdir( QT_UI_FILES_PATH )

	-- Set up Qt pre-build steps and add the future generated file paths to the package
	for _,file in ipairs( mocfiles ) do
		local mocFile = GetFileNameNoExtFromPath( file )
		local mocFilePath = QT_MOC_FILES_PATH.."/moc_"..mocFile..".cpp"
		table.insert( package.prebuildcommands, { 'lua ' .. QT_PREBUILD_LUA_PATH .. ' -moc "' .. file .. '" "' .. QT_ENV .. '"' } )
		table.insert( package.files, { mocFilePath } )
	end

	for _,file in ipairs( qrcfiles ) do
		local qrcFile = GetFileNameNoExtFromPath( file )
		local qrcFilePath = QT_QRC_FILES_PATH.."/qrc_"..qrcFile..".cpp"
		table.insert( package.prebuildcommands, { 'lua ' .. QT_PREBUILD_LUA_PATH .. ' -rcc "' .. file .. '" "' .. QT_ENV .. '"' } )
		table.insert( package.files, { file, qrcFilePath } )
	end

	for _,file in ipairs( uifiles ) do
		local uiFile = GetFileNameNoExtFromPath( file )
		local uiFilePath = QT_UI_FILES_PATH.."/ui_"..uiFile..".h"
		table.insert( package.prebuildcommands, { 'lua ' .. QT_PREBUILD_LUA_PATH .. ' -uic "' .. file .. '" "' .. QT_ENV .. '"' } )
		table.insert( package.files, { file, uiFilePath } )
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
