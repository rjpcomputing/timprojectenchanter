-- ----------------------------------------------------------------------------
--	Premake script to build $(ProjectName).
--	Author:		$(UserName)
--	Date:		$(Date)
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- INCLUDES -------------------------------------------------------------------
--
dofile( "build/presets.lua")
dofile( "build/boostpresets.lua")
dofile( "build/qtpresets.lua" )

-- OPTIONS --------------------------------------------------------------------
--
addoption( "dynamic-runtime", "Use the dynamicly loadable version of the runtime." )

-- PROJECT SETTINGS -----------------------------------------------------------
--
project.name								= "$(ProjectName)"
project.bindir								= "bin"
project.libdir								= "lib"

-- force options
EnableOption( "unicode" )
EnableOption( "dynamic-runtime" )
EnableOption( "qt-shared" )
--EnableOption( "qt-copy-debug" )
--EnableOption( "boost-shared" )

-- PACKAGES -------------------------------------------------------------------
--
dopackage( "$(ProjectName).lua" )
