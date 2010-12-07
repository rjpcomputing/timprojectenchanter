-- ----------------------------------------------------------------------------
--	Copyright (C) 2010 Gentex Corporation
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
--		- call logging.Configure() after your project is setup, not before.
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
function logging.Configure( pkg, includePath )

	-- Check to make sure that the pkg is valid.
	assert( type( pkg ) == "table", "Param1:pkg type missmatch, should be a table." )

	pkg.libpaths				= pkg.libpaths or {}
	pkg.links					= pkg.links or {}
	pkg.buildoptions			= pkg.buildoptions or {}
	pkg.defines					= pkg.defines or {}
	pkg.includepaths			= pkg.includepaths or {}

	
	if includePath then
		AddSystemPath( pkg, includePath )	
	else
		if "lib" == pkg.kind then
			AddSystemPath( pkg, "../log4cplus/include" )	
		else
			AddSystemPath( pkg, "log4cplus/include" )	
		end
	end
	
	table.insert( pkg.links, "Log4CPlus" )	
end
