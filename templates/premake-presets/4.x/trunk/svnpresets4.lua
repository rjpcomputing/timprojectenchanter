-- ----------------------------------------------------------------------------
--	Author:		Chris Steenwyk <chris.steenwyk@gentex.com>, based on svn/presets4.lua
--	Date:		05/08/2014
--	Version:	1.00
--
--	NOTES:
--		- use the '/' slash for all paths.
--		- call svn.Configure() after your project is setup, not before.
--		- This is part of the "Sack" library
-- ----------------------------------------------------------------------------

-- Package options

-- Namespace
svn = {}

function svn:ReadVersion( path )

        local versionFile = io.open( path, "r" )

        if not versionFile then
                error( "Unable to open " .. path .. " for reading the Subversion Library version" )
        end

        self.versionMajor = nil
        self.versionMinor = nil
        self.versionPatch = nil

        for line in versionFile:lines() do
        	self.versionMajor = self.versionMajor or tonumber( line:match( "#define%s+SVN_VER_MAJOR%s+(%w+)" ) )
              	self.versionMinor = self.versionMinor or tonumber( line:match( "#define%s+SVN_VER_MINOR%s+(%w+)" ) )
              	self.versionPatch = self.versionPatch or tonumber( line:match( "#define%s+SVN_VER_PATCH%s+(%w+)" ) )
                if self.versionMajor and self.versionMinor and self.versionPatch then
                        self.version = self.versionMajor .. "." .. self.versionMinor .. "." .. self.versionPatch
                        return
                end
        end

        local errorMessage = "Unable to find these in " .. path .. ":"
        if not self.versionMajor then
		errorMessage = errorMessage .. " SVN_VER_MAJOR"
	end
	if not self.versionMinor then
		errorMessage = errorMessage .. " SVN_VER_MINOR"
	end
	if not self.versionPatch then
		errorMessage = errorMessage .. " SVN_VER_PATCH"
	end
        error( errorMessage )
end

--- Removes a value from a list like table.
--	@param tbl {table} Remove the value from this table
--	@param value {string} The value to search for. It can be a pattern
local function iRemoveValueFromTable( tbl, value )
	ignoreCase = ignoreCase or true
	local itemChanged = true
	while itemChanged do
		for idx, val in ipairs( tbl ) do
			if val:find( value ) then
				table.remove( tbl, idx )
				itemChanged = true
				break
			else
				itemChanged = false
			end
		end
	end
end


---	Configure a C/C++ package to use svn.
--
--	Options supported:
--
--	Appended to package setup:
--		package.includepaths			= (windows) { "$(SACK/include), $(SACK/include/apr), $(SACK/include/apr-util), $(SACK/include/apr-iconv)" }
--		package.libpaths				= (windows) { "$(SACK)/lib" }
--		package.links					= svn libs and (windows) { "advapi32", "shfolder", "secur32", "ole32", "crypt32", "rpcrt4", "mswsock", "ws2_32" }
--
--	Example:
--		svn.Configure()
function svn.Configure()

	local cfg = configuration()

	if not project() then
		error( "There is no currently active project. Please use the project() method to create a project first." )
	end

	configuration( {} )

	local svnroot = nil
	local aprroot = nil
	if os.is ( "windows" ) then
		svnroot = os.getenv( "SACK" )
	elseif os.is( "linux" ) then
		svnroot = "/usr"
	elseif os.is( "macosx" ) then
		svnroot = "/usr/local"
	else
		error( "Unsupported OS: svn does not support " .. os.get() )
	end

	svn:ReadVersion( svnroot .. "/include/subversion-1/svn_version.h" )
	local httplib = "serf"
	local httplibSuffix = ""
	if (1 == svn.versionMajor) and (svn.versionMinor < 8) then
		httplib = "neon"
	else
		if os.is( "linux" ) then
			httplibSuffix = "-1"
		end
	end
	if os.is( "macosx" ) then
		httplibSuffix = "-1"
	end

	local svnlibs = {
						"svn_client-1",
						"svn_ra-1",
						"svn_ra_local-1",
						"svn_ra_" .. httplib .. "-1",
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

	local ssldepslibs = {
						httplib .. httplibSuffix,
						"ssleay",
						"eay32",
						"z"
					}

	local depslibs = {
						httplib .. httplibSuffix,
						"z"
					}

	local aprlibs = {
						"aprutil-1",
						"apriconv-1",
						"apr-1"
					}

	local oslibs =	{
					}

	if ActionUsesGCC() then
		buildoptions { "-Wno-deprecated-declarations" }
	end

	if os.is ( "windows" ) then

		oslibs =	{
						"advapi32",
						"shfolder",
						"secur32",
						"ole32",
						"crypt32",
						"rpcrt4",
						"mswsock",
						"ws2_32",
						"gdi32"
					}


		local apiBuiltWithPremake = os.isdir( svnroot .. "/bin" )

		local runtimedir = "runtime-static"

		if _OPTIONS["dynamic-runtime"] then
			runtimedir = "runtime-dynamic"
		end

		local libdir = nil
		if apiBuiltWithPremake then

			libdir = _ACTION or ""
			if ActionUsesGCC() then
				libdir = "mingw"
				runtimedir = "runtime-dynamic"
			end

			local hasSSL = (svn.versionMinor > 6) or (svn.versionMajor > 1)
			if hasSSL then
				depslibs = ssldepslibs
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

		defines { "APR_DECLARE_STATIC", "APU_DECLARE_STATIC" }

		configuration( {  "Release", "x32 or native" } )
			libdirs( svnroot .. "/lib/" .. libdir .. "/link-static/" .. runtimedir .. "/release" 	)
		configuration( { "Debug", "x32 or native" } )
			libdirs( svnroot .. "/lib/" .. libdir .. "/link-static/" .. runtimedir .. "/debug" 	 )
		configuration( {  "Release", "x64" } )
			libdirs( svnroot .. "/lib64/" .. libdir .. "/link-static/" .. runtimedir .. "/release" 	)
		configuration( { "Debug", "x64" } )
			libdirs( svnroot .. "/lib64/" .. libdir .. "/link-static/" .. runtimedir .. "/debug" 	 )
		configuration( {} )

	elseif os.is( "linux" ) then
		-- Remove unneeded libraries
		iRemoveValueFromTable( svnlibs, "svn_ra_.*" )
		iRemoveValueFromTable( svnlibs, "svn_fs_.*" )
		iRemoveValueFromTable( depslibs, "z" )
		iRemoveValueFromTable( aprlibs, "apriconv.*" )
	
	elseif os.is( "macosx" ) then
		-- Remove unneeded libraries
		iRemoveValueFromTable( aprlibs, "apriconv.*" )
		libdirs( "/usr/local/Cellar/subversion/" .. svn.versionMajor .. "." .. svn.versionMinor .. "." .. svn.versionPatch .. "/libexec/serf/lib/" )
	end

	configuration "not StaticLib"
		links { svnlibs, depslibs, aprlibs, oslibs }
	configuration( {} )

	AddSystemPath( svnroot .. "/include/subversion-1" )
	if os.is( "macosx" ) then
		AddSystemPath( "/usr/include/apr-1" )
	else
		AddSystemPath( svnroot .. "/include/apr-1.0" )
	end

	configuration(cfg.terms)

end
