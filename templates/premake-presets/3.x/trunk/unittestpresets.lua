 -- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		12/22/2009
--	Version:	2.00
--
--	Copyright (C) 2008-2010 Ryan Pusztai
-- ----------------------------------------------------------------------------

-- Package options
--addoption( "with-boost-shared", "Link against Boost as a shared library" )

-- Namespace
unittest =
{
	unitTestPackage	= false,				-- Tracks if the unit test packages have been 'dopackage()'ed.
	mockPackage		= false,				-- Tracks if the mock packages have been 'dopackage()'ed.
	unitTestEnabled	= false,				-- Tracks if any package has called unittest.Configure().
	mockEnabled		= false,				-- Tracks if any package has called unittest.Configure() with mocking support.

	unitTestPath	= "unittest++/unittestpp.lua",
	googleMockPath	= "googlemock/googlemock.lua",
	googleTestPath	= "googlemock/gtest/googletest.lua",
	mockLibFound	= nil,

	oldDopackage	= dopackage,			-- Holds the function pointer to the original 'dopackage()'.
}

-- HELPER FUNCTIONS ----------------------------------------------------
--
function unittest.DoUnitTestPackage()
	-- Add the packages required by UnitTesting.
	if os.direxists( "unittest++" ) then
		unittest.oldDopackage( unittest.unitTestPath )
	elseif os.direxists( "../unittest++" ) then
		unittest.oldDopackage( "../"..unittest.unitTestPath )
	else
		error( "Unit testing library not found. This is required to be next to your premake.lua or in a directory above the premake.lua." )
	end
end

function unittest.DoMockPackage()
	-- Check to see if Google testing is externaled.
	unittest.mockLibFound = unittest.mockLibFound or false
	if os.direxists( "googlemock" ) then
		unittest.mockLibFound = true
	elseif os.direxists( "../googlemock" ) then
		unittest.googleMockPath = "../"..unittest.googleMockPath
		unittest.googleTestPath = "../"..unittest.googleTestPath
		unittest.mockLibFound = true
	else
		unittest.mockLibFound = false
	end

	if unittest.mockLibFound then
		unittest.oldDopackage( unittest.googleMockPath )
		unittest.oldDopackage( unittest.googleTestPath )
	end
end

--[[This function returns a deep copy of a given table.
	The function below also copies the metatable to the new table if there is one,
	so the behaviour of the copied table is the same as the original. ]]
local function deepcopy(object)
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

local function DoUnitTestSetup( newPkg, files, excludes )
	local unitTestDir = "unittest++"
	-- Check to see if there is a copy in a sub-directory above it.
	-- Used when building libraries.
	if os.direxists( "../"..unitTestDir ) then
		unitTestDir = "../"..unitTestDir
	end

	table.insert( newPkg.files, { files, unitTestDir .. "/main.cpp" } )
	table.insert( newPkg.excludes, excludes )
	table.insert( newPkg.includepaths, { unitTestDir, unitTestDir .. "/src" } )
	table.insert( newPkg.links, { "UnitTest++" } )

	unittest.unitTestEnabled = true
end

local function DoMockTestSetup( newPkg )
	local mockDir = "googlemock"
	-- Check to see if there is a copy in a sub-directory above it.
	-- Used when building libraries.
	if os.direxists( "../"..mockDir ) then
		mockDir = "../"..mockDir
	end

	table.insert( newPkg.includepaths, { mockDir .. "/gtest/include", mockDir .. "/include", mockdir } )
	table.insert( newPkg.links, { "GoogleMock", "GoogleTest" } )
	table.insert( newPkg.defines, { "USE_GMOCK" } )

	unittest.mockEnabled = true
end

---	Call this To configure your package to be .
--	@param pkg Premake 'package' passed in that gets all the settings manipulated.
function unittest.Configure( pkg, files, excludes, mock )
	assert( type( pkg ) == "table", "unittest.Configure( Param1:pkg ) type missmatch, should be a table." )
	files = files or {}
	assert( type( files ) == "table", "unittest.Configure( Param2:files ) type missmatch, should be a table." )
	excludes = excludes or {}
	assert( type( excludes ) == "table", "unittest.Configure( Param3:excludes ) type missmatch, should be a table." )

	--mock = mock or false

	local pkgName = pkg.name

	-- Add the options help.
	local disableAllTests = "disable-all-tests"
	addoption( disableAllTests, "Disable all tests" )

	local disableTest = "disable-" .. pkgName:lower().."-tests"
	addoption( disableTest, "Disable " ..pkgName.. " tests to run." )
	
	local onlyTest = pkgName:lower().."-only-tests"
	addoption( onlyTest, "Only create the test project for " ..pkgName )

	-- Add the package to the project if being tested.
	if ( not options[disableTest] ) and ( not options[disableAllTests] ) then
	
		local newPkg = deepcopy( pkg )		-- Make a deep copy of the package.
		table.insert( _PACKAGES, newPkg )	-- Add it to the available _PACKAGES table.
		
		if ( options[onlyTest] ) then
			-- remove original project
			table.remove( _PACKAGES, #_PACKAGES - 1 )
		end
		
		-- Set all the new package details.
		newPkg.name = pkgName.."-tests"
		newPkg.target = pkg.target.."-tests"
		newPkg.config["Debug"].target = pkg.config["Debug"].target.."-tests"
		newPkg.kind = "exe"
		newPkg.buildflags["no-main"] = nil
		newPkg.bindir = pkg.bindir or project.bindir
		newPkg.objdir = pkg.objdir.."/tests"
		newPkg.targetextension = nil		-- Fix extension if tested package set it to something weird
		if pkg.guid then					-- Update the GUID so there is not a duplicate in the VC solution.
			newPkg.guid = pkg.guid:gsub( "(%w+)-(%w+)-(%w+)-(%w+)-(%w+)", "%1-%4-%2-%3-%5" )
		end

		local pathSeparator = "/"
		if ( target and target:find("vs2") ) then --Visual studio target
			pathSeparator = "\\"
			--table.insert( newPkg.links, { pkg.name } )
		end

		table.insert( newPkg.config["Debug"].postbuildcommands, { newPkg.bindir .. pathSeparator .. newPkg.config["Debug"].target } )
		table.insert( newPkg.config["Release"].postbuildcommands, { newPkg.bindir .. pathSeparator .. newPkg.target } )

		-- Do unit test packages so it does not have to be called elsewhere
		DoUnitTestSetup( newPkg, files, excludes )

		-- Do mock test packages so it does not have to be called elsewhere
		if mock then
			DoMockTestSetup( newPkg )
		end
	end
end

-- ENTRY POINT ---------------------------------------------------------
--
local function main()
	-- Check to make sure that the user is not running the '--help' or '--clean' commandline argument.
	if target ~= nil then
		if not options["disable-all-tests"] then
			-- Overwride the dopackage() so that we can control when the testing packages get added.
			function dopackage( pkgName )
				-- do the old package like ussual.
				unittest.oldDopackage( pkgName )

				if unittest.unitTestEnabled then
					if not unittest.unitTestPackage then
						unittest.DoUnitTestPackage()
						unittest.unitTestPackage = true
					end
				end

				if unittest.mockEnabled then
					if not unittest.mockPackage then
						unittest.DoMockPackage()
						unittest.mockPackage = true
					end
				end
			end
		end
	end
end

main()
