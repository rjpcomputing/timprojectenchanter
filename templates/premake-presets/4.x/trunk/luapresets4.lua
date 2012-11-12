-- ----------------------------------------------------------------------------
--	Name:		luapresents4.lua, a Premake4 script
--	Author:		Ben Cleveland, based on luapresents.lua by Ryan Pusztai
--	Date:		03/07/20100
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- Package options
newoption
{
	trigger = "lua-shared",
	description = "Link against Lua as a shared library"
}

if "windows" == os.get() then
	newoption
	{
		trigger = "lua-link-debug",
		description = "Link against the debug version in Debug configuration. Normally you link against the release version no matter the configuration."
	}
end

-- Namespace
lua = {}

---	Configure a C/C++ package to use Lua.
--	@param pkg {table} Premake 'package' passed in that gets all the settings manipulated.
--	@param luaVer {string} [DEF] The version of Lua that you are building for.
--		Defaults to "5.1".
--
--	Options supported:
--		lua-shared - "Link against Lua as a shared library"
--		lua-link-debug - "Link against the debug version in Debug configuration." (Windows Only)
--		dynamic-runtime - "Use the dynamicly loadable version of the runtime."
--		unicode - "Use the Unicode character set."
--
--	Appended to package setup:
--		includedirs			= (windows) { "$(LUA_DEV)/include" }
--							= (Linux)   { "/usr/include/lua" .. luaVer }
--		libdirs				= (windows) { "$(LUA_DEV)/lib" }
--		links				= (windows) { "lua5.1" }
--
--	NOTES:
--		Only supports VC and GCC
--
--	Example:
--		lua.Configure( "5.2" )
function lua.Configure( luaVer )
	-- Check to make sure that the pkg is valid.
	luaVer = luaVer or "5.1"

	if "windows" == os.get() then
		libdirs		{ "$(LUA_DEV)/lib" }
		includedirs	{ "$(LUA_DEV)/include" }
	else
		includedirs	{ "/usr/include/lua" .. luaVer }
	end

	local kindVal = presets.GetCustomValue( "kind" ) or ""
	if "windows" == os.get() and _OPTIONS["lua-link-debug"] then
		cfg = configuration()

		configuration "Debug"
			if kindVal ~= "StaticLib" then
				links	{ "lua" .. luaVer .. "d" }
			end
		configuration( "Release" )
			if kindVal ~= "StaticLib" then
				links	{ "lua" .. luaVer }
			end

		configuration(cfg.terms)
	else
		if kindVal ~= "StaticLib" then
			links { "lua" .. luaVer }
		end
	end
end
