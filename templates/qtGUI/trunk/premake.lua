-- ----------------------------------------------------------------------------
--	Premake script for Mobileye data visualizer plugin.
--	Author:		Tim Bochenek <Tim.Bochenek@gentex.com>
--	Date:		09/08/2010
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

dofile( "build/presets.lua")
dofile( "build/qtpresets.lua" )
dofile( "build/boostpresets.lua")
dofile( "build/unittestpresets.lua")

EnableOption( "qt-shared" )
EnableOption( "qt-copy-debug" )
--EnableOption( "boost-shared" )
EnableOption( "dynamic-runtime" )
EnableOption( "no-extra-warnings" )
--EnableOption( "devicecomm-shared" )
--EnableOption( "lua-shared" )
--EnableOption( "loki-shared" )
EnableOption( "no-boost-logging" )
EnableOption( "with-mobileye" )

-- PROJECT SETTINGS -----------------------------------------------------------
project.name								= "MobileyeVisualizer"
project.bindir								= "bin"
project.libdir								= "lib"

-- PACKAGES -------------------------------------------------------------------
dopackage( "MobileyeVisualizer.lua" )
dopackage( "loki/loki.lua" )
dopackage( "lua/lualib.lua" )
dopackage( "devicecomm/devicecomm.lua" )
dopackage( "boost_utils/boost_utils.lua" )
