-- ----------------------------------------------------------------------------
--	Author:		Josh Lareau <joshua.lareau@gentex.com>
--	Date:		12/18/2010
--	Version:	1.0.0
--	Title:		Poco premake presets
-- ----------------------------------------------------------------------------

-- Package Options
addoption( "poco-shared", "Link against poco as a shared library" )
addoption( "poco-nocopy-debug", "Override copying the debug libraries in the CopyDynamicLibraries method" )
EnableOption( "no-extra-warnings" )

-- Namespaces
poco = {}

-- Version
poco.version = "2009.2.4" -- default poco version

-- Library Name
local POCO_LIB_PREFIX = "Poco"

-- Determine the poco version from the installed path
if windows then
	poco.root = os.getenv( "appinf.libraries.foundation.poco" )
	if not poco.root then
		error( "missing the POCO_BASE environment variable" )
	end

	-- determine version from POCO_BASE environment variable
	local slashIndex = 1;
	while true do
		local nextIndex = poco.root:find( "\\", slashIndex + 1, true )
		if nextIndex ~= nil then
			slashIndex = nextIndex
		else
			break
		end
	end

	local versionDir = poco.root:sub( slashIndex + 1 )
	poco.version = versionDir
end

--  Extracts the compiler type from either the target name, dotname name, or c/c++ compiler (cc) name
--  @returns The compiler type, i.e. "gcc" or "msvc2010"
function GetCompilerType()

	local compilerType

	if target then
		compilerType = target

		if string.find( target or "", ".*-gcc" ) then
			compilerType = "gcc"
		elseif target == "gnu" then
			compilerType = "gcc"
		elseif TARGET == "gmake" then
			compilerType = "gcc"
		elseif target == "vs2005" then
			compilerType = "vc8"
		elseif target == "vs2008" then
			compilerType = "vc9"
		elseif target == "vs2010" then
			compilerType = "vc10"
		end
	end

	if dotnet then
		if dotnet == "ms" then
			compilerType = "csc"
		elseif dotnet == "mono" then
			compilerType = "mcs"
		elseif dotnet == "mono2" then
			compilerType = "gmcs"
		elseif dotnet == "pnet" then
			compilerType = "cscc"
		end
	end

	if cc then
		compilerType = cc
	end

	return compilerType
end

--  Creates a poco deployment bundle.
--	@param pkg {table} Premake 'package' passed in that gets its settings manipulated.
--  @param bundleSpec {string} [REQ] The path of the bundle specification file. Cannot be empty.
--  @param isDebug {bool} Defaults to false. The build configuration.
--  @param includeBundleSpec {bool} Defaults to true. The bundleSpec will be added to the files table.
--  @param bundlePath {string} [DEF] The output of the bundle tool. Defaults to "./bundles".
--
function poco.Bundle( pkg, bundleSpec, isDebug, includeBundleSpec, bundlePath )
	if target then

		if nil == isDebug then
			isDebug = false
		end

		if nil == includeBundleSpec then
			includeBundleSpec = true
		end

		assert( type( pkg ) == "table", "poco.Bundle: Param1:pkg type missmatch, should be a table." )
		assert( bundleSpec ~= nil, "poco.Bundle: You myst specify the path of a bundle specification file!" )
		assert( type( isDebug ) == "boolean", "poco.Bundle: Param3:isDebug type missmatch, should be a boolean." )
		assert( type( includeBundleSpec ) == "boolean", "poco.Bundle: Param4:includeBundleSpec type missmatch, should be a boolean." )

		if bundleSpec then

			if includeBundleSpec then
				table.insert( pkg.files, bundleSpec )
			end

			local POCO_BUNDLE_OUTPUT = bundlePath or "\""..os.getcwd().."./bundles".."\""

			if windows then
				local compilerType = GetCompilerType()
				local bundleCommand = "\""..poco.root.."/bin/bundle.exe\" /output="..POCO_BUNDLE_OUTPUT.." "..bundleSpec.." ".."/define=compiler="..compilerType

				if isDebug then
					table.insert( pkg.config["Debug"].postbuildcommands, bundleCommand )
				else
					table.insert( pkg.config["Release"].postbuildcommands, bundleCommand )
				end
			end
		end
	end
end

--	Creates deployment packages. Runs "packager.lua" as a post build step.
--	@param pkg {table} [REQ] Premake 'package' passed in that gets its settings manipulated.
--	@param packagerPath {string} [DEF] The path of the lua packager script.  Defaults to "./build/packager.lua".
--  @param bundlespecs {string} [DEF] The path to the bundle specification files. Defaults to "./bundlespecs".
--  @param bundleOutput {string} [DEF] The output directory of the bundle tool. Will create a "bundles" dir here. Defaults to "./".
--  @param compilerType {string} [DEF] The compiler used to create the binaries or shared libraries in the bundle. Will default to using the premake target name.
--
function poco.Deploy( pkg, packagerPath, bundlespecs, bundleOutput, compilerType )
	if target then
		assert( type( pkg ) == "table", "poco.Deploy: Param1:pkg type missmatch, should be a table." )

		local PACKAGER_PATH = packagerPath or "./build/packager.lua"
		local BUNDLE_SPEC_LOCATION = bundlespecs or "./bundlespecs"
		local BUNDLE_OUTPUT = bundleOutput or "./"

		-- Lua Name
		local luaName = "lua "
		if windows then
			luaName = "lua.exe "
		end

		-- Compiler type
		local COMPILER_TYPE = compilerType or GetCompilerType()

		if windows then
			local postBuildCommand = luaName .. PACKAGER_PATH .. ' -b ' .. BUNDLE_SPEC_LOCATION .. ' -p ' .. poco.root .. ' -o ' .. BUNDLE_OUTPUT .. ' -c ' .. COMPILER_TYPE
			table.insert( pkg.postbuildcommands, { postBuildCommand } )
		end
	end
end

--  Generate Remote Procedure Call code using the Poco remoting framework.
--  @param pkg {table} [REQ] Premake 'package' passed in that gets its settings manipulated.
--  @param remoteFiles {string} [REQ] The header files that you want to generate remoting code for.
--  @param mode {string} [DEF] Specifies the target the generator should generate code for: server, client, both, or interface. Defaults to interface.
--	@param SOAPServiceLocation {string} [DEF] The URI of the remote SOAP service. Should always have the form: http://<host>:<port>/soap/<serviceClass>/<objectId>
--  @param OSPEnable {bool} [DEF] Specify whether code for Open Service Platform services should be generated.
--  @param BundleActivator {bool} [DEF] If OSPEnable is true, specify if you want the bundle activator to be generated.
--  @param exportMacro {string} [DEF] If the package is a DLL, this is the name of the export macro to include in the generated files. Defaults to empty. Note: Will automatically get appended with "_API", so don't include this suffix.
--  @param pocoPrebuildPath {string} [DEF] The path to the "pocoprebuild.lua" file that is used to invoke the remoting code generator.
--
function poco.RemoteGen( pkg, remoteFiles, mode, SOAPServiceLocation, OSPEnable, BundleActivator, exportMacro, pocoPrebuildPath )
	if target then

		local REMOTEGEN_HEADER_OUTPUT = "Generated Files/Header Files/"
		local REMOTEGEN_SOURCE_OUTPUT = "Generated Files/Source Files/"

		local REMOTEGEN_XML_OUTPUT = "Generated Files/XML/"
		local REMOTEGEN_WSDL_OUTPUT = "Generated Files/WSDL/"

		-- Add system paths
		AddSystemPath( pkg, REMOTEGEN_HEADER_OUTPUT )

		local remoteFileDirs= {}
		for _,remoteFile in pairs( remoteFiles ) do

			-- Get the path of the remote file so we can add it to the include path
			local remoteFileDir = GetDirNameFromFile( remoteFile )

			-- Only do this once per path
			if not iContainsEntry( remoteFileDirs, remoteFileDir ) then
				AddSystemPath( pkg, remoteFileDir )
				table.insert( remoteFileDirs, remoteFileDir )
			end
		end

		-- Add package files and prebuild step
		for _,remoteFile in pairs( remoteFiles ) do

			-- Get the name of the remote service we are generating from the header file name
			remoteServiceName = GetFileNameNoExtFromPath( remoteFile )

			mode = mode or "interface"

			-- The interface files are always generated
			local generatedFiles =	{	REMOTEGEN_HEADER_OUTPUT.."i"..remoteServiceName..".h",
										REMOTEGEN_SOURCE_OUTPUT.."i"..remoteServiceName..".cpp"
									}

			local fileTypes = {}

			-- Determine the types of files to generate based on the mode
			if string.find( mode or "", "server" ) or string.find( mode or "", "both" ) then
				table.insert( fileTypes, {	"RemoteObject", "ServerHelper", "Skeleton" } )
			end

			if string.find( mode or "", "client" ) or string.find( mode or "", "both" ) then
				table.insert( fileTypes, {	"Proxy", "ClientHelper", "ProxyFactory" } )

				-- Only generate the extensions.xml for the client
				if OSPEnable then
					local extensionsXML = REMOTEGEN_XML_OUTPUT.."extensions.xml"
					if not iContainsEntry( pkg.files, extensionsXML ) then
						table.insert( pkg.files, { extensionsXML } )
					end
				end
			end

			-- If OSP generation is enabled then add the bundleActivator files
			if OSPEnable and BundleActivator then
				table.insert( fileTypes, {	"BundleActivator" } )
				table.insert( pkg.files, REMOTEGEN_SOURCE_OUTPUT..remoteServiceName.."BundleActivatorImpl"..".cpp" )
			end

			Flatten( fileTypes )

			-- Create generated package file names from the file types determined by the mode setting
			for _,aType in pairs( fileTypes ) do
				table.insert( generatedFiles, REMOTEGEN_HEADER_OUTPUT..remoteServiceName..aType..".h" )
				table.insert( generatedFiles, REMOTEGEN_SOURCE_OUTPUT..remoteServiceName..aType..".cpp" )
			end

			Flatten( generatedFiles )

			-- Add the generated files to the package
			for _,pkgFile in pairs( generatedFiles ) do
				table.insert( pkg.files, pkgFile )
			end

			-- RemoteGen XML file
			local remoteGenXML = REMOTEGEN_XML_OUTPUT..remoteServiceName.."Gen.xml"
			table.insert( pkg.files, { remoteGenXML } )

			-- Lua Name
			local luaName = "lua "
			if windows then
				luaName = "lua.exe "
			end

			-- If the package is a DLL, we need to determine which export macro to use
			if "dll" == pkg.kind then
				exportMacro = exportMacro or ""
			else
				exportMacro = ""
			end

			-- Service location is used for SOAP RPC only
			SOAPServiceLocation = SOAPServiceLocation or ""

			-- WSDL file for SOAP RPC
			if "" ~= SOAPServiceLocation then
				local WSDLFile = REMOTEGEN_WSDL_OUTPUT..remoteServiceName..".wsdl"
				table.insert( pkg.files, { WSDLFile } )
			end

			-- OSP Generation
			local GenerateOSP = "false"
			local GenerateBundleActivator = "false"
			if OSPEnable then
				GenerateOSP = "true"
				if BundleActivator then
					GenerateBundleActivator = "true"
				end
			end

			-- The prebuild command
			pocoPrebuildPath = pocoPrebuildPath or "\""..os.getcwd().."/build/pocoprebuild.lua".."\""
			local preBuildCommand = luaName .. pocoPrebuildPath .. ' "' .. mode .. '" "' .. remoteFile .. '" "' .. poco.root .. '" "' .. target ..'" "' .. remoteGenXML .. '" "' .. REMOTEGEN_HEADER_OUTPUT .. '" "' .. REMOTEGEN_SOURCE_OUTPUT .. '" "' .. SOAPServiceLocation .. '" "' .. REMOTEGEN_WSDL_OUTPUT .. '" "' .. exportMacro .. '" "' .. GenerateOSP .. '" "' .. GenerateBundleActivator
			table.insert( pkg.prebuildcommands, { preBuildCommand } )
		end
	end
end

--  Configure a C/C++ package to use poco.
--	@param pkg {table} Premake 'package' passed in that gets all the settings manipulated.
--	@param pocoLibs {table} [DEF] Table that contains the names of the poco libraries needed to build. Can be empty.
--	@param pocoVer {string} [DEF] The version of poco to build against. Can be empty.
--
function poco.Configure( pkg, pocoLibs, pocoVer )
	if target then
		pocoVer = pocoVer or poco.version
		pocoLibs = pocoLibs or { "Foundation" }

		-- Check to make sure that the pkg is valid.
		assert( type( pkg ) == "table", "poco.Configure Param1:pkg type missmatch, should be a table." )
		assert( type( pocoLibs ) == "table", "poco.Configure Param2:pocoLibs type missmatch, should be a table." )

		-- Make sure that an entry point is not defined, so we can use the POCO_SERVER_MAIN macros
		table.insert( pkg.buildflags, { "no-main" } )

		-- Always link against foundation
		if not iContainsEntry( pocoLibs, "Foundation" ) then
			table.insert( pocoLibs, "Foundation" )
		end

		pkg.includepaths			= pkg.includepaths or {}

		if windows then
			pkg.libpaths				= pkg.libpaths or {}
			pkg.defines					= pkg.defines or {}
			pkg.buildoptions			= pkg.buildoptions or {}

			table.insert( pkg.libpaths, { poco.root .. "/lib" } )
			table.insert( pkg.defines, { "_WIN32_WINNT=0x0500" } )	--(i.e. Windows 2000 target)

			--Poco wraps Windows.h in UnWindows.h which undefines a bunch of annoying predefined macros.
			--However, this sometimes causes conflicts, especially when trying to mix poco and other libraries like boost
			table.insert( pkg.defines, { "POCO_NO_UNWINDOWS" } )
		end

		-- Use poco as a collection of shared libraries
		if options["poco-shared"] then
			pkg.defines	= pkg.defines or {}
			table.insert( pkg.defines, "POCO_DLL" )
		end

		local libsToLink = deepcopy( pocoLibs )

		-- set the include paths
		for _,libInclude in pairs( pocoLibs ) do
			AddSystemPath( pkg, poco.root..'/'..libInclude..'/include' )

			-- Add additional dependencies for the poco frameworks
			if string.find( libInclude or "", "Remoting" ) then
				AddSystemPath( pkg, poco.root..'/'..libInclude.."/Binary/include" )
				AddSystemPath( pkg, poco.root..'/'..libInclude.."/SoapLite/include" )
				table.insert( libsToLink, { "Binary","SoapLite" } )

				-- Make sure the "Net" library is linked against when using remoting
				if not iContainsEntry( libsToLink, "Net" ) then
					table.insert( libsToLink, { "Net" } )
					AddSystemPath( pkg, poco.root..'/'..'Net'..'/include' )
				end

				-- Make sure the "Util" library is linked against when using remoting
				if not iContainsEntry( libsToLink, "Util" ) then
					table.insert( libsToLink, { "Util" } )
					AddSystemPath( pkg, poco.root..'/'..'Util'..'/include' )
				end

				-- Make sure the "XML" library is linked against when using remoting
				if not iContainsEntry( libsToLink, "XML" ) then
					table.insert( libsToLink, { "XML" } )
					AddSystemPath( pkg, poco.root..'/'..'XML'..'/include' )
				end

			end

			if string.find( libInclude or "", "Data" ) then
				AddSystemPath( pkg, poco.root..'/'..libInclude.."/SQLite/include" )
				AddSystemPath( pkg, poco.root..'/'..libInclude.."/ODBC/include" )
				table.insert( libsToLink, { "SQLite", "ODBC" } )
			end

			if string.find( libInclude or "", "OSP" ) then
				AddSystemPath( pkg, poco.root..'/'..libInclude.."/BundleSign/include" )
				AddSystemPath( pkg, poco.root..'/'..libInclude.."/Shell/include" )
				AddSystemPath( pkg, poco.root..'/'..libInclude.."/Web/include" )
				table.insert( libsToLink, { "OSPBundleSign", "OSPShell", "OSPWeb" } )

				-- Make sure the "Net" library is linked against when using OSP
				if not iContainsEntry( libsToLink, "Net" ) then
					table.insert( libsToLink, { "Net" } )
					AddSystemPath( pkg, poco.root..'/'..'Net'..'/include' )
				end

				-- Make sure the "Util" library is linked against when using OSP
				if not iContainsEntry( libsToLink, "Util" ) then
					table.insert( libsToLink, { "Util" } )
					AddSystemPath( pkg, poco.root..'/'..'Util'..'/include' )
				end

				-- Make sure the "XML" library is linked against when using OSP
				if not iContainsEntry( libsToLink, "XML" ) then
					table.insert( libsToLink, { "XML" } )
					AddSystemPath( pkg, poco.root..'/'..'XML'..'/include' )
				end

				-- Make sure the "Zip" library is linked against when using OSP
				if not iContainsEntry( libsToLink, "Zip" ) then
					table.insert( libsToLink, { "Zip" } )
					AddSystemPath( pkg, poco.root..'/'..'Zip'..'/include' )
				end

			end
		end

		Flatten( libsToLink )

		-- set the libs to link against
		for _,libLink in pairs( libsToLink ) do
			table.insert( pkg.config["Debug"].links, { POCO_LIB_PREFIX..libLink.."d" } )
			table.insert( pkg.config["Release"].links, { POCO_LIB_PREFIX..libLink } )
			--print( 'Linking ' .. libLink ); io.stdout:flush()
		end
	end
end

function poco.CopyDynamicLibraries( pocoLibs, destinationDirectory, pocoVer, copyDebug )
	if target then

		pocoVer = pocoVer or poco.version
		pocoLibs = pocoLibs or { "Foundation" }

		assert( type( pocoLibs ) == "table", "poco.CopyDynamicLibraries argument type missmatch: pocoLibs should be a table." )

		-- Always copy at least foundation
		if not iContainsEntry( pocoLibs, "Foundation" ) then
			table.insert( pocoLibs, "Foundation" )
		end

		-- Determine if the debug libraries should be copied
		local shouldCopyDebugLibs = copyDebug
		if copyDebug == nil then
			shouldCopyDebugLibs = true
		end

		if options["poco-nocopy-debug"] then
			shouldCopyDebugLibs = false
		end

		-- Add additional dependencies for the poco frameworks
		local libsTocopy = deepcopy( pocoLibs )

		for _,vi in pairs( pocoLibs ) do
			if string.find( vi or "", "Remoting" ) then
				table.insert( libsTocopy, { "Binary","SoapLite" } )
			end

			if string.find( vi or "", "Data" ) then
				table.insert( libsTocopy, { "SQLite", "ODBC" } )
			end

			if string.find( vi or "", "OSP" ) then
				table.insert( libsTocopy, { "OSPBundleSign", "OSPShell", "OSPWeb" } )
			end
		end

		Flatten( libsTocopy )

		-- copy dlls to bin dir
		if windows then
			os.mkdir( destinationDirectory )
			function copyLibs( debugCopy )
				for _,v in pairs( libsTocopy ) do

					local libname =  POCO_LIB_PREFIX..v..'.dll'

					if debugCopy then
						libname =  POCO_LIB_PREFIX..v..'d.dll'
					end

					local targetName = libname
					local sourcePath = '"' .. poco.root .. '\\bin\\' .. libname .. '"'
					local destPath = '"' .. destinationDirectory .. '\\' .. targetName .. '"'

					--print( 'copying ' .. libname ); io.stdout:flush()
					WindowsCopy( sourcePath, destPath )

					-- Copy the PDB files over as well
					if debugCopy then
						local libDebug = POCO_LIB_PREFIX..v..'d.pdb'
						local sourcePathPDB = '"' .. poco.root .. '\\bin\\' .. libDebug .. '"'
						local destPathPDB = '"' .. destinationDirectory .. '\\' .. libDebug .. '"'
						WindowsCopy( sourcePathPDB, destPathPDB )
					end

				end
			end
			if shouldCopyDebugLibs then
				copyLibs( true )
			end
			copyLibs( false )
		end
	end
end
