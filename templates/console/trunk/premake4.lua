-- ----------------------------------------------------------------------------
--	Premake script to build $(ProjectName).
--	Author:		Ryan Pusztai <ryan.pusztai@gentex.com>
--	Date:		$(Date)
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- INCLUDES -------------------------------------------------------------------
--
dofile( "build/presets4.lua")
--dofile( "build/boostpresets4.lua")

-- OPTIONS --------------------------------------------------------------------
--
newoption
{
	trigger = "dynamic-runtime",
	description = "Use the dynamicly loadable version of the runtime."
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


-- PROJECTS -------------------------------------------------------------------
--
dofile	"root4.lua"
