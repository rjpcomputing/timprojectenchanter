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
--	Example:
--		subcpp.Configure( package )
function subcpp.Configure( pkg )

	-- Check to make sure that the pkg is valid.
	assert( type( pkg ) == "table", "Param1:pkg type missmatch, should be a table." )

	pkg.libpaths				= pkg.libpaths or {}
	pkg.links					= pkg.links or {}
	pkg.buildoptions			= pkg.buildoptions or {}
	pkg.defines					= pkg.defines or {}

	local svnlibs = {
						"svn_client-1",
						"svn_ra-1",
						"svn_ra_local-1",
						"svn_ra_neon-1",
						"svn_ra_svn-1",
						"svn_repos-1",
						"svn_wc-1",
						"svn_diff-1",
						"svn_fs-1",
						"svn_fs_fs-1",
						"svn_fs_util-1",
						"svn_delta-1",
						"svn_subr-1"
					}

	local depslibs ={
						"neon",
						"z"
					}

	local aprlibs = {
						"aprutil-1",
						"apriconv-1",
						"apr-1"
					}

	local oslibs =	{
					}

	local svnroot = nil

	if windows then

		oslibs =	{
						"advapi32",
						"shfolder",
						"secur32",
						"ole32",
						"crypt32",
						"rpcrt4",
						"mswsock",
						"ws2_32"
					}

		svnroot = os.getenv( "SUBVERSION" )
		local apiBuiltWithPremake = os.direxists( svnroot .. "/bin" )

		local runtimedir = "runtime-static"

		if options["dynamic-runtime"] then
			runtimedir = "runtime-dynamic"
		end

		local libdir = nil
		if apiBuiltWithPremake then

			libdir = target or ""
			--if ("gnu" == target) or target:find( ".*-gcc" ) then
			if target == "gnu" or string.find( target or "", ".*-gcc" ) then
				libdir = "mingw"
				runtimedir = "runtime-dynamic"
			end

			table.insert( aprlibs,  2, "aprutilxml-1" )

		else

			libdir = "vc90"
			if  "vs2005" == target then
				libdir = "vc80"
			end

			table.insert( aprlibs,  2, "aprutil-xml" )
			depslibs =	{
							"libneon",
							"zlibstat"
						}

			for k, v in pairs( svnlibs ) do
				svnlibs[k] = "lib" .. v
			end

		end

		table.insert( pkg.config["Release"].libpaths,  	{ svnroot .. "/lib/" .. libdir .. "/link-static/" .. runtimedir .. "/release" 	} )
		table.insert( pkg.config["Debug"].libpaths,  	{ svnroot .. "/lib/" .. libdir .. "/link-static/" .. runtimedir .. "/debug" 	} )

		table.insert( pkg.defines,  { "APR_DECLARE_STATIC", "APU_DECLARE_STATIC" } )

	elseif linux then

		svnroot = "/usr"
		table.remove( depslibs ) 	-- remove "z"
		table.remove( aprlibs,  2 ) -- remove "apriconv-1"

	end

	AddSystemPath( pkg, svnroot .. "/include/subversion-1" )
	AddSystemPath( pkg, svnroot .. "/include/apr-1.0" )

	if pkg.kind ~= "lib" then
		table.insert( pkg.links, { "SubCpp", svnlibs, depslibs, aprlibs, oslibs } )
	end
end
