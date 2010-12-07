-- ----------------------------------------------------------------------------
--	Premake script for Mobileye data visualizer plugin.
--	Author:		Tim Bochenek <Tim.Bochenek@gentex.com>
--	Date:		09/08/2010
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- PROJECT CONFIGURATION -------------------------------------------------------
package.name						= "MobileyeVisualizer"
package.kind						= "winexe"
package.files						= 	{ 	matchfiles( "*.cpp", "*.hpp", "*.h", "*.lua", "inc/*.h", "pgm/*", "clipread.lib" ) }

package.defines						= 	{ "CRB_GUI_EXTENSION", "QT_CORE_LIB" }
if options["boost-shared"] then
	table.insert( package.defines, "BOOST_UTILS_USING_DLL" )
end

if options["devicecomm-shared"] then
	table.insert( package.defines, "DEVICECOMM_USING_DLL" )
end

if options["lua-shared"] and string.find( target or "", "vs20" ) then
	table.insert( package.defines, "LUA_BUILD_AS_DLL" )
end

if options["loki-shared"] then
	table.insert( package.defines, "LOKI_DLL" )
end

package.links						= 	{ 	"DeviceComm", "Loki", "LuaLib", "boost_utils" }

package.includepaths                = 	{
											"boost_utils", "devicecomm"
										}

if linux and ( not options["no-origin"] ) then
	table.insert( package.linkoptions, "-Wl,-rpath,$$``ORIGIN" )
end

MakeVersion( package, "install/windows/" .. package.name .. ".iss" )
MakeVersion( package, "MobileyeVisualizerVersion.h" )

-- PACKAGE SETUP --------------------------------------------------------------
Configure( package )
local mocfiles				= { "DirMonitorHooks.h", "mainwindow.h", "MobileyeWidget.h" }
local qrcfiles				= {  }
local uifiles				= { matchfiles( "*.ui" ) }
local libsToLink			= { "Core", "Gui" }
local qtMajorRev			= 4
local qtPrebuildPath		= "build/qtprebuild.lua"
local copyDynamicLibraries	= nil
qt.Configure( package, mocfiles, qrcfiles, uifiles, libsToLink, qtMajorRev, qtPrebuildPath, copyDynamicLibraries )
local boostlibs = { "iostreams", "date_time", "filesystem", "regex", "serialization", "signals", "system", "thread", "wserialization" }
if windows then
	table.insert( boostlibs, "zlib" )
	table.insert( boostlibs, "bzip2" )
end
boost.Configure( package, boostlibs )
if options["boost-shared"] then
	boost.CopyDynamicLibraries( boostlibs, project.bindir )
end
unittest.Configure (package, matchrecursive("tests/*.cc", "tests/*.hh"), { "main.cpp" }, true )
