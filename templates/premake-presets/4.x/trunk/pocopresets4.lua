-- ----------------------------------------------------------------------------
--	Author:		Josh Lareau <joshua.lareau@gentex.com>
--	Date:		10/06/2011
--	Version:	1.0.0
--	Title:		Poco premake4 presets
-- ----------------------------------------------------------------------------

-- Namespaces
poco = {}
poco.version = "1.4.2"
poco.libname = "Poco"

-- Package Options
newoption
{
	trigger = "poco-shared",
	description = "Link against poco as a shared library"
}

newoption
{
	trigger = "poco-external",
	description = "Link against poco built from source via an SVN external"
}

newoption
{
	trigger = "poco-full-osp",
	description = "Link against OSP with extra libraries"
}

newoption
{
	trigger = "poco-nocopy-debug",
	description = "Override copying the debug libraries in the CopyDynamicLibraries method"
}

--  Configure a C/C++ package to use poco.
--	@param pocoLibs {table} [DEF] Table that contains the names of the poco libraries needed to build. Can be empty.
function poco.Configure( pocoLibs )
	if _ACTION then

		pocoLibs = pocoLibs or { "Foundation" }

		assert( type( pocoLibs ) == "table", "poco.Configure Param1:pocoLibs type missmatch, should be a table." )

		-- Always link against foundation
		if not table.contains( pocoLibs, "Foundation" ) then
			table.insert( pocoLibs, "Foundation" )
		end

		if( _OPTIONS[ "poco-external" ] ) then
			poco.root = solution().basedir .. "/poco"
		else
			poco.root = os.getenv( "appinf.libraries.foundation.poco" )
			if not poco.root then
				error( "missing the POCO_BASE environment variable" )
			end
		end

		if os.is("windows") then

			if not _OPTIONS[ "poco-external" ]  then
				libdirs { poco.root .. "/lib" }
			end

			--Poco wraps Windows.h in UnWindows.h which undefines a bunch of annoying predefined macros.
			--However, this sometimes causes conflicts, especially when trying to mix poco and other libraries like boost
			defines	{ "POCO_NO_UNWINDOWS" }
		end

		-- Use poco as a collection of shared libraries
		if( _OPTIONS[ "poco-shared" ] ) then
			defines	{ "POCO_DLL" }
		else
			defines { "POCO_STATIC", "POCO_NO_AUTOMATIC_LIBS" }
			links	{ "Iphlpapi" }
		end

		local libsToLink = deepcopy( pocoLibs )

		-- set the include paths
		for _,libInclude in pairs( pocoLibs ) do

			if string.find( libInclude or "", "ODBC" ) then
				AddSystemPath( poco.root.."/Data/ODBC/include" )
			elseif string.find( libInclude or "", "SQLite" ) then
				AddSystemPath( poco.root.."/Data/SQLite/include" )
			else
				AddSystemPath( poco.root..'/'..libInclude..'/include' )
			end

			-- Add additional dependencies for the poco frameworks
			if string.find( libInclude or "", "Remoting" ) then
				AddSystemPath( poco.root..'/'..libInclude.."/Binary/include" )
				AddSystemPath( poco.root..'/'..libInclude.."/SoapLite/include" )
				table.insert( libsToLink, { "Binary","SoapLite" } )

				-- Make sure the "Net" library is linked against when using remoting
				if not table.contains( libsToLink, "Net" ) then
					table.insert( libsToLink, { "Net" } )
					AddSystemPath( poco.root..'/'..'Net'..'/include' )
				end

				-- Make sure the "Util" library is linked against when using remoting
				if not table.contains( libsToLink, "Util" ) then
					table.insert( libsToLink, { "Util" } )
					AddSystemPath( poco.root..'/'..'Util'..'/include' )
				end

				-- Make sure the "XML" library is linked against when using remoting
				if not table.contains( libsToLink, "XML" ) then
					table.insert( libsToLink, { "XML" } )
					AddSystemPath( poco.root..'/'..'XML'..'/include' )
				end
			end

			if string.find( libInclude or "", "OSP" ) then

				if( _OPTIONS[ "poco-full-osp" ] ) then
					AddSystemPath( poco.root..'/'..libInclude.."/BundleSign/include" )
					AddSystemPath( poco.root..'/'..libInclude.."/Shell/include" )
					AddSystemPath( poco.root..'/'..libInclude.."/Web/include" )
					table.insert( libsToLink, { "OSPBundleSign", "OSPShell", "OSPWeb" } )

					--Make sure the "Net" library is linked against when using full OSP
					if not table.contains( libsToLink, "Net" ) then
						table.insert( libsToLink, { "Net" } )
						AddSystemPath( poco.root..'/'..'Net'..'/include' )
					end
				end

				-- Make sure the "Util" library is linked against when using OSP
				if not table.contains( libsToLink, "Util" ) then
					table.insert( libsToLink, { "Util" } )
					AddSystemPath( poco.root..'/'..'Util'..'/include' )
				end

				-- Make sure the "XML" library is linked against when using OSP
				if not table.contains( libsToLink, "XML" ) then
					table.insert( libsToLink, { "XML" } )
					AddSystemPath( poco.root..'/'..'XML'..'/include' )
				end

				-- Make sure the "Zip" library is linked against when using OSP
				if not table.contains( libsToLink, "Zip" ) then
					table.insert( libsToLink, { "Zip" } )
					AddSystemPath( poco.root..'/'..'Zip'..'/include' )
				end
			end
		end

		Flatten( libsToLink )

		-- set the libs to link against
		for _,libLink in pairs( libsToLink ) do
			links { poco.libname..libLink }
		end
	end
end

--  Extracts the compiler type from the _ACTION (http://industriousone.com/premake/quick-start)
--  @returns The compiler type, i.e. "gcc" or "msvc2010"
function GetCompilerType()

	local compilerType

	if _ACTION then
		compilerType = _ACTION

		if _ACTION == "codeblocks" then
			compilerType = "gcc"
		elseif _ACTION == "codelite" then
			compilerType = "gcc"
		elseif _ACTION == "gmake" then
			compilerType = "gcc"
		elseif _ACTION == "vs2005" then
			compilerType = "vc8"
		elseif _ACTION == "vs2008" then
			compilerType = "vc9"
		elseif _ACTION == "vs2010" then
			compilerType = "vc10"
		end
	end

	return compilerType
end

--  Creates a poco deployment bundle.
--  @param bundleSpec {string} [REQ] The path of the bundle specification file. Cannot be empty.
--  @param isDebug {bool} Defaults to false. The build configuration.
--  @param includeBundleSpec {bool} Defaults to true. The bundleSpec will be added to the files table.
--  @param bundlePath {string} [DEF] The output of the bundle tool. Defaults to "./bundles".
--
function poco.Bundle( bundleSpec, isDebug, includeBundleSpec, bundlePath )
	if _ACTION then

		if nil == isDebug then
			isDebug = false
		end

		if nil == includeBundleSpec then
			includeBundleSpec = true
		end

		assert( bundleSpec ~= nil, "poco.Bundle: You myst specify the path of a bundle specification file!" )
		assert( type( isDebug ) == "boolean", "poco.Bundle: Param3:isDebug type missmatch, should be a boolean." )
		assert( type( includeBundleSpec ) == "boolean", "poco.Bundle: Param4:includeBundleSpec type missmatch, should be a boolean." )

		if bundleSpec then

			if includeBundleSpec then
				files { bundleSpec }
			end

			local POCO_BUNDLE_OUTPUT = bundlePath or "\""..os.getcwd().."/bundles".."\""

			if os.is( "windows" ) then

				local bundleToolPath = poco.root.."/bin/bundle.exe"

				if _OPTIONS[ "poco-external" ] then
					if isDebug then
						bundleToolPath = "bin/bundled.exe"
					else
						bundleToolPath = "bin/bundle.exe"
					end
				end

				local compilerType = GetCompilerType()
				local bundleCommand = "\""..bundleToolPath.."\" /output="..POCO_BUNDLE_OUTPUT.." "..bundleSpec.." ".."/define=compiler="..compilerType

				if isDebug then
					configuration "Debug"
						postbuildcommands { bundleCommand }
				else
					configuration "Release"
						postbuildcommands { bundleCommand }
				end

				configuration( {} )

			end
		end
	end
end

function poco.CopyDynamicLibraries( pocoLibs, destinationDirectory, copyDebug )

	if _OPTIONS[ "poco-external" ]  then
		error( "CopyDynamicLibraries is not comparible with the poco-external option." )
	end

	if _ACTION then
		pocoLibs = pocoLibs or { "Foundation" }

		assert( type( pocoLibs ) == "table", "poco.CopyDynamicLibraries argument type missmatch: pocoLibs should be a table." )

		-- Always copy at least foundation
		if not table.contains( pocoLibs, "Foundation" ) then
			table.insert( pocoLibs, "Foundation" )
		end

		-- Determine if the debug libraries should be copied
		local shouldCopyDebugLibs = copyDebug
		if copyDebug == nil then
			shouldCopyDebugLibs = true
		end

		if _OPTIONS["poco-nocopy-debug"] then
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
		if os.is("windows")  then
			os.mkdir( destinationDirectory )
			function copyLibs( debugCopy )
				for _,v in pairs( libsTocopy ) do

					local libname =  poco.libname..v..'.dll'

					if debugCopy then
						libname =  poco.libname..v..'d.dll'
					end

					local targetName = libname
					local sourcePath = '"' .. poco.root .. '\\bin\\' .. libname .. '"'
					local destPath = '"' .. destinationDirectory .. '\\' .. targetName .. '"'

					--print( 'copying ' .. libname ); io.stdout:flush()
					WindowsCopy( sourcePath, destPath )

					-- Copy the PDB files over as well
					if debugCopy then
						local libDebug = poco.libname..v..'d.pdb'
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

function Flatten(t)
	local tmp = {}
	for si,sv in ipairs(t) do
		if type( sv ) == "table" then
			for _,v in ipairs(sv) do
					table.insert(tmp, v)
			end
		elseif type( sv ) == "string" then
			table.insert( tmp, sv )
		end
			t[si] = nil
	end
	for _,v in ipairs(tmp) do
			table.insert(t, v)
	end
end

--[[This function returns a deep copy of a given table.
	The function below also copies the metatable to the new table if there is one,
	so the behaviour of the copied table is the same as the original. ]]
function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
--        return setmetatable(new_table, getmetatable(object))
        return setmetatable( new_table, _copy( getmetatable( object ) ) )
    end
    return _copy(object)
end
