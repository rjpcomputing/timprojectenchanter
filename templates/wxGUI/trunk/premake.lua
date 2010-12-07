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
dofile( "build/presets.lua" )
dofile( "build/boostpresets.lua" )
dofile( "build/wxpresets.lua" )

-- OPTIONS --------------------------------------------------------------------
--
addoption( "dynamic-runtime", "Use the dynamicly loadable version of the runtime." )

-- PROJECT SETTINGS -----------------------------------------------------------
--
project.name									= "$(ProjectName)"
project.bindir									= "bin"
project.libdir									= "lib"

-- force options
EnableOption( "unicode" )

-- PACKAGES -------------------------------------------------------------------
--
dopackage( "$(ProjectName).lua" )
