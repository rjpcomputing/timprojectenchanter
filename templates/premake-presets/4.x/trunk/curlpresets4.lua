-- ----------------------------------------------------------------------------
--	Author:		Chris Steenwyk <chris.steenwyk@gentex.com>, based on svn/presets4.lua
--	Date:		05/08/2014
--	Version:	1.00
--
--	NOTES:
--		- use the '/' slash for all paths.
--		- call curl.Configure() after your project is setup, not before.
--		- This is part of the "Sack" library
-- ----------------------------------------------------------------------------

-- Package options

-- Namespace
curl = {}

---	Configure a C/C++ package to use curl.
--
--	Options supported:
--
--	Appended to package setup:
--		package.includepaths			= (windows) { "$(SACK/include)" }
--		package.libpaths				= (windows) { "$(SACK)/lib" }
--		package.links					= curl libs and (windows) {  "ssleay", "eay32", "z", "Wldap32", "crypt32", "gdi32" }
--
--	Example:
--		curl.Configure()
function curl.Configure()

	local cfg = configuration()

	if not project() then
		error( "There is no currently active project. Please use the project() method to create a project first." )
	end

	configuration( {} )

	local curlroot = nil
	if os.is ( "windows" ) then
		curlroot = os.getenv( "SACK" )
	elseif os.is( "linux" ) then
		curlroot = "/usr"
	elseif os.is( "macosx" ) then
		curlroot = "/usr/local"
	else
		error( "Unsupported OS: curl does not support " .. os.get() )
	end

	local curllibs = {}
	if os.is ( "windows" ) then
		
		AddSystemPath( curlroot .. "/include" )
		
		defines { "CURL_STATICLIB", "USE_SSLEAY", "USE_OPENSSL", "HAVE_LIBZ", "HAVE_ZLIB_H" }

		curllibs = 	{ "ssleay", "eay32", "z", "Wldap32", "crypt32", "gdi32" }

		local runtimedir = "runtime-static"
		if _OPTIONS["dynamic-runtime"] then
			runtimedir = "runtime-dynamic"
		end
		
		local libdir = _ACTION or ""
		if ActionUsesGCC() then
			libdir = "mingw"
			runtimedir = "runtime-dynamic"
		end

		configuration( {  "Release", "x32 or native" } )
			libdirs( curlroot .. "/lib/" .. libdir .. "/link-static/" .. runtimedir .. "/release" 	)
		configuration( { "Debug", "x32 or native" } )
			libdirs( curlroot .. "/lib/" .. libdir .. "/link-static/" .. runtimedir .. "/debug" 	 )
		configuration( {  "Release", "x64" } )
			libdirs( curlroot .. "/lib64/" .. libdir .. "/link-static/" .. runtimedir .. "/release" 	)
		configuration( { "Debug", "x64" } )
			libdirs( curlroot .. "/lib64/" .. libdir .. "/link-static/" .. runtimedir .. "/debug" 	 )
		configuration( {} )
	end

	configuration "not StaticLib"
		links { "curl", curllibs }
	configuration( {} )

	configuration(cfg.terms)

end
