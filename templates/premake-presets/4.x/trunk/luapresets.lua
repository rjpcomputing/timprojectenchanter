-- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		04/22/2010
--	Version:	1.00
--
--	Copyright (C) 2008-2010 Ryan Pusztai
--
--	Permission is hereby granted, free of charge, to any person obtaining a copy
--	of this software and associated documentation files (the "Software"), to deal
--	in the Software without restriction, including without limitation the rights
--	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--	copies of the Software, and to permit persons to whom the Software is
--	furnished to do so, subject to the following conditions:
--
--	The above copyright notice and this permission notice shall be included in
--	all copies or substantial portions of the Software.
--
--	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
--	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--	THE SOFTWARE.
--
--	NOTES:
--		- use the '/' slash for all paths.
--		- call lua.Configure() after your project is setup, not before.
-- ----------------------------------------------------------------------------

-- Package options
addoption( "lua-shared", "Link against Lua as a shared library" )
if windows then
	addoption( "lua-link-debug", "Link against the debug version in Debug configuration. Normally you link against the release version no matter the configuration." )
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
--		package.includepaths			= (windows) { "$(LUA_DEV)/include" }
--										= (Linux)   { "/usr/include/lua" .. luaVer }
--		package.libpaths				= (windows) { "$(LUA_DEV)/lib" }
--		package.links					= (windows) { "lua5.1" }
--
--	NOTES:
--		Only supports VC and GCC
--
--	Example:
--		lua.Configure( package, "5.2" )
function lua.Configure( pkg, luaVer )
	-- Check to make sure that the pkg is valid.
	assert( type( pkg ) == "table", "Param1:pkg type missmatch, should be a table." )
	luaVer = luaVer or "5.1"

	pkg.includepaths				= pkg.includepaths or {}
	if windows then
		pkg.libpaths				= pkg.libpaths or {}
		table.insert( pkg.libpaths, "$(LUA_DEV)/lib" )
		table.insert( pkg.includepaths, "$(LUA_DEV)/include" )
	else
		table.insert( pkg.includepaths, "/usr/include/lua" .. luaVer )
	end

	if windows and options["lua-link-debug"] then
		table.insert( pkg.config["Debug"].links,   "lua" .. luaVer .. "d" )
		table.insert( pkg.config["Release"].links, "lua" .. luaVer )
	else
		table.insert( pkg.links, "lua" .. luaVer )
	end

	-- GCC only settings
	--[[if target == "gnu" or string.find( target or "", ".*-gcc" ) then
	end]]

	-- VC Only setting
	--[[if not string.find( target or "", "vs*" ) then
	end]]
end

