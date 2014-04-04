-- ----------------------------------------------------------------------------
--	Name:		loggingpresets.lua, a Premake4 script
--	Author:		Ben Cleveland, based on loggingpresets.lua by Ryan Mulder
--	Date:		11/24/2010
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- Package options

-- Namespace
logging = {}

---	Configure a C/C++ package to use the recommended logging system.
--	@param pkg {table} Premake 'package' passed in that gets all the settings manipulated.
--  @param includePath {string} [DEF] Path to logging include directory
--
--	Options supported:
--
--	Appended to package setup:
--		package.includepaths			= "../log4cplus/include"
--		package.links					= "log4cplus"
--
--	Example:
--		logging.Configure( package )
function logging.Configure( includePath )

	-- Check to make sure that the pkg is valid.

	local kindVal = presets.GetCustomValue( "kind" ) or ""

	if includePath then
		local success, msg = pcall( AddSystemPath, includePath )
		if not success then
			error( "logging.Configure: " .. msg, 2 )
		end
	else

		if ( (kindVal == "StaticLib") or (kindVal == "SharedLib") ) then
			AddSystemPath( "../log4cplus/include" )
		else
			AddSystemPath( "log4cplus/include" )
		end
	end

	if ( kindVal ~= "StaticLib" ) then
		links "Log4CPlus"
	end

	if _OPTIONS["log4cplus-shared"] then
		defines "LOG4CPLUS_BUILD_DLL"
	end
end
