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
dofile( "build/presets4.lua" )
dofile( "build/boostpresets4.lua" )
dofile( "build/qtpresets4.lua" )

-- OPTIONS --------------------------------------------------------------------
--
newoption
{
	trigger = "dynamic-runtime",
	description = "Use the dynamically loadable version of the runtime."
}

-- SOLUTION SETTINGS -----------------------------------------------------------
--
solution		"$(ProjectName)"
configurations 	{ "Debug", "Release" }
targetdir		"bin"
--[[  This would force all the solution's projects to seek the .lib files in ./lib.  Probably don't want that.
implibdir		"lib"
]]

-- force options
EnableOption( "unicode" )
EnableOption( "dynamic-runtime" )
EnableOption( "qt-shared" )
--EnableOption( "qt-copy-debug" )
--EnableOption( "boost-shared" )

-- PROJECTS -------------------------------------------------------------------
--
dofile	"$(ProjectName)4.lua"
