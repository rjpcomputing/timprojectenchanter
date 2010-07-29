-- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		04/20/2010
--	Version:	1.20
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
--		- call subcpp.Configure() after your project is setup, not before.
-- ----------------------------------------------------------------------------

-- Package options

-- Namespace
subcpp = {}

---	Configure a C/C++ package to use SubCpp.
--	@param pkg {table} Premake 'package' passed in that gets all the settings manipulated.
--
--	Options supported:
--
--	Appended to package setup:
--		package.includepaths			= (windows) { "$(SUBVERSION/include), $(SUBVERSION/include/apr), $(SUBVERSION/include/apr-util), $(SUBVERSION/include/apr-iconv)" }
--		package.libpaths				= (windows) { "$(SUBVERSION)/lib" }
--		package.links					= svn libs and (windows) { "advapi32", "shfolder", "secur32", "ole32", "crypt32", "rpcrt4", "mswsock", "ws2_32" }
--
--	NOTES:
--		Only supports VC8, VC9 and Linux
--
--	Example:
--		subcpp.Configure( package )
function subcpp.Configure( pkg )
	-- Check to make sure that the pkg is valid.
	assert( type( pkg ) == "table", "Param1:pkg type missmatch, should be a table." )

	pkg.libpaths				= pkg.libpaths or {}
	pkg.links					= pkg.links or {}
	pkg.buildoptions			= pkg.buildoptions or {}
	pkg.defines					= pkg.defines or {}

	table.insert( pkg.links, { "SubCpp", "apr-1", "aprutil-1" } )

	if windows then
		if pkg.kind ~= "lib" then
			local libdir = "vc90"
			if  "vs2005" == target then
				libdir = "vc80"
			elseif target == "gnu" or string.find( target or "", ".*-gcc" ) then
				libdir = "mingw44"
			end
			
			if options["dynamic-runtime"] then
				table.insert( pkg.config["Release"].libpaths, { "$(SUBVERSION)/lib/" .. libdir .. "/link-static/runtime-dynamic/release" } )
				table.insert( pkg.config["Debug"].libpaths, { "$(SUBVERSION)/lib/" .. libdir .. "/link-static/runtime-dynamic/debug" } )
			else
				table.insert( pkg.config["Release"].libpaths, { "$(SUBVERSION)/lib/" .. libdir .. "/link-static/runtime-static/release" } )
				table.insert( pkg.config["Debug"].libpaths, { "$(SUBVERSION)/lib/" .. libdir .. "/link-static/runtime-static/debug" } )
			end
			
			local libs =
			{
				"libneon",
				"libsvn_client-1",
				"libsvn_delta-1",
				"libsvn_diff-1",
				"libsvn_fs-1",
				"libsvn_fs_fs-1",
				"libsvn_fs_util-1",
				"libsvn_ra-1",
				"libsvn_ra_local-1",
				"libsvn_ra_neon-1",
				"libsvn_ra_svn-1",
				"libsvn_repos-1",
				"libsvn_subr-1",
				"libsvn_wc-1",
				"apriconv-1",
				"aprutil-xml",
				"zlibstat",
				"advapi32",
				"shfolder",
				"secur32",
				"ole32",
				"crypt32",
				"rpcrt4",
				"mswsock",
				"ws2_32",
			}
			table.insert( pkg.links, libs )
		end

		table.insert( pkg.defines, { "APR_DECLARE_STATIC", "APU_DECLARE_STATIC" } )

		if target == "gnu" or string.find( target or "", ".*-gcc" ) then
			table.insert( pkg.buildoptions, { "-isystem $(SUBVERSION)/include/subversion-1", "-isystem $(SUBVERSION)/include/apr-1.0" } )
		else
			table.insert( pkg.includepaths, { "$(SUBVERSION)/include/subversion-1", "$(SUBVERSION)/include/apr-1.0" } )
		end
	elseif linux then
		if pkg.kind ~= "lib" then
			local libs =
			{
				"neon",
				"svn_client-1",
				"svn_delta-1",
				"svn_diff-1",
				"svn_fs-1",
				"svn_fs_fs-1",
				"svn_fs_util-1",
				"svn_ra-1",
				"svn_ra_local-1",
				"svn_ra_neon-1",
				"svn_ra_svn-1",
				"svn_repos-1",
				"svn_subr-1",
				"svn_wc-1",
			}
			table.insert( pkg.links, libs )
		end
		table.insert( pkg.buildoptions, { "-isystem /usr/include/subversion-1", "-isystem /usr/include/apr-1.0" } )
		--table.insert( pkg.links, { "xml2", "z" } )
	else
	end
end
