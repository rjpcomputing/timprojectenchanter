-- ----------------------------------------------------------------------------
--	Author:		Chris Steenwyk <chris.steenwyk@gentex.com>, based on svn/presets4.lua
--	Date:		05/08/2014
--	Version:	1.00
--
--	NOTES:
--		- use the '/' slash for all paths.
--		- call z.Configure() after your project is setup, not before.
--		- This is part of the "Sack" library
-- ----------------------------------------------------------------------------

-- Package options

-- Namespace
z = {}

---	Configure a C/C++ package to use z.
--
--	Options supported:
--
--	Appended to package setup:
--		package.includepaths			= (windows) { "$(SACK/include/zlib)" }
--		package.libpaths				= (windows) { "$(SACK)/lib" }
--		package.links					= z libs
--
--	Example:
--		z.Configure()
function z.Configure()

	local cfg = configuration()

	if not project() then
		error( "There is no currently active project. Please use the project() method to create a project first." )
	end

	configuration( {} )

	local zroot = nil
	if os.is ( "windows" ) then
		zroot = os.getenv( "SACK" )
	elseif os.is( "linux" ) then
		zroot = "/usr"
	elseif os.is( "macosx" ) then
		zroot = "/usr/local"
	else
		error( "Unsupported OS: z does not support " .. os.get() )
	end

	if os.is ( "windows" ) then
		
		AddSystemPath( zroot .. "/include/zlib" )

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
			libdirs( zroot .. "/lib/" .. libdir .. "/link-static/" .. runtimedir .. "/release" 	)
		configuration( { "Debug", "x32 or native" } )
			libdirs( zroot .. "/lib/" .. libdir .. "/link-static/" .. runtimedir .. "/debug" 	 )
		configuration( {  "Release", "x64" } )
			libdirs( zroot .. "/lib64/" .. libdir .. "/link-static/" .. runtimedir .. "/release" 	)
		configuration( { "Debug", "x64" } )
			libdirs( zroot .. "/lib64/" .. libdir .. "/link-static/" .. runtimedir .. "/debug" 	 )
		configuration( {} )

	end

	configuration "not StaticLib"
		links { "z" }
	configuration( {} )

	configuration(cfg.terms)

end
