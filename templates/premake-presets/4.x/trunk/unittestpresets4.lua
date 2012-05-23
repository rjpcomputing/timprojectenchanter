 -- ----------------------------------------------------------------------------
--	Name:		unittestpresets4.lua, a Premake4 script
--	Author:		Ben Cleveland, based on unittestpresets.lua by Ryan Pusztai
--	Date:		11/24/2010
--	Version:	1.00
--
--	Notes:		Not used.  Each individual project uses projectUnittest4.lua which is similar to this.
-- ----------------------------------------------------------------------------

-- Package options
--newoption
--{
	--trigger = "with-boost-shared",
	--description = "Link against Boost as a shared library"
--}

newoption
{
	trigger = "teamcity",
	description = "Unit test performed for Team City"
}

newoption
{
	trigger = "maxtesttime",
	description = "Maximum number of ms allowed for an individual unit test"
}

local disableAllTests = "disable-all-tests"
newoption
{
	trigger = disableAllTests,
	description = "Disable all tests"
}

-- Namespace
unittest =
{
	unitTestPackage	= false,				-- Tracks if the unit test packages have been 'dopackage()'ed.
	mockPackage		= false,				-- Tracks if the mock packages have been 'dopackage()'ed.
	unitTestEnabled	= false,				-- Tracks if any package has called unittest.Configure().
	mockEnabled		= false,				-- Tracks if any package has called unittest.Configure() with mocking support.

	unitTestPath	= "unittest++/unittestpp4.lua",
	googleMockPath	= "googlemock/googlemock4.lua",
	googleTestPath	= "googlemock/gtest/googletest4.lua",
	mockLibFound	= nil,
	projectUnderTest = nil,					-- The project under test
	projectUnderTestKind = nil,				-- The kind of the project under test

	oldDofile = dofile,			-- Holds the function pointer to the original 'dofile()'.
}

-- HELPER FUNCTIONS ----------------------------------------------------
--
function unittest.DoUnitTestPackage()
	-- Add the packages required by UnitTesting.
	if os.isdir( "unittest++" ) then
		unittest.oldDofile( unittest.unitTestPath )
	elseif os.isdir( "../unittest++" ) then
		unittest.oldDofile( "../"..unittest.unitTestPath )
	else
		error( "Unit testing library not found. This is required to be next to your premake4.lua or in a directory above the premake4.lua." )
	end
end

function unittest.DoMockPackage()
	-- Check to see if Google testing is externaled.
	unittest.mockLibFound = unittest.mockLibFound or false
	if os.isdir( "googlemock" ) then
		unittest.mockLibFound = true
	elseif os.isdir( "../googlemock" ) then
		unittest.googleMockPath = "../"..unittest.googleMockPath
		unittest.googleTestPath = "../"..unittest.googleTestPath
		unittest.mockLibFound = true
	else
		unittest.mockLibFound = false
	end

	if unittest.mockLibFound then
		unittest.oldDofile( unittest.googleMockPath )
		unittest.oldDofile( unittest.googleTestPath )
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

local function DoUnitTestSetup( inputFiles, inputExcludes )
	local unitTestDir = "unittest++"
	-- Check to see if there is a copy in a sub-directory above it.
	-- Used when building libraries.
	if os.isdir( "../"..unitTestDir ) then
		unitTestDir = "../"..unitTestDir
	end

	files { inputFiles, unitTestDir .. "/main.cpp" }
	excludes { inputExcludes }
	includedirs { unitTestDir, unitTestDir .. "/src" }
	links { "UnitTest++" }

	unittest.unitTestEnabled = true
end

local function DoMockTestSetup()
	local mockDir = "googlemock"
	-- Check to see if there is a copy in a sub-directory above it.
	-- Used when building libraries.
	if os.isdir( "../"..mockDir ) then
		mockDir = "../"..mockDir
	end

	includedirs { mockDir .. "/gtest/include", mockDir .. "/include", mockdir }
	links { "GoogleMock", "GoogleTest" }
	defines { "USE_GMOCK" }

	unittest.mockEnabled = true
end

---	Call this To configure your package to be .
--	@param pkg Premake 'package' passed in that gets all the settings manipulated.
function unittest.Configure( setupFunction, inputFiles, inputExcludes, mock, withLog4CPlus )
	inputFiles = inputFiles or {}
	assert( type( inputFiles ) == "table", "unittest.Configure( Param2:inputFiles ) type missmatch, should be a table." )
	inputExcludes = inputExcludes or {}
	assert( type( inputExcludes ) == "table", "unittest.Configure( Param3:inputExcludes ) type missmatch, should be a table." )

	--mock = mock or false

	unittest.projectUnderTest = project()
	unittest.projectUnderTestKind = presets.GetCustomValue( "kind" )
	local pkgName = unittest.projectUnderTest.name
	local testName = pkgName .. "-tests"

	-- Add the options help.
	local disableTest = "disable-" .. pkgName:lower().."-tests"
	newoption
	{
		trigger = disableTest,
		description = "Disable " ..pkgName.. " tests to run."
	}

	local onlyTest = pkgName:lower().."-only-tests"
	newoption
	{
		trigger = onlyTest,
		description = "Only create the test project for " .. pkgName
	}

	-- Create the return variable
	local createdTestProject = false

	-- Add the package to the project if being tested.
	if ( not _OPTIONS[disableTest] ) and ( not _OPTIONS[disableAllTests] ) then

		if ( _OPTIONS[onlyTest] ) then
			-- remove original project
			local origProject = solution().projects[pkgName]
			for k, v in ipairs( solution().projects ) do
				if origProject == v then
					table.remove( solution().projects, k )
					break
				end
			end
			solution().projects[pkgName] = nil
		end

		project( testName )

		-- configure just like the original
		setupFunction()

		-- Set all the new package details.
		kind( "ConsoleApp" )
		if ( objdir() ) then
			objdir( objdir().."/tests" )
		else
			objdir( "obj/tests" )
		end

		if project().uuid then					-- Update the GUID so there is not a duplicate in the VC solution.
			uuid( project().uuid:gsub( "(%w+)-(%w+)-(%w+)-(%w+)-(%w+)", "%1-%4-%2-%3-%5" ) )
		end

		local pathSeparator = "/"
		if ( _ACTION and _ACTION:find("vs2") ) then --Visual studio target
			pathSeparator = "\\"
			--table.insert( newPkg.links, { pkg.name } )
		end

		local teamCitySuffix = ""
		if _OPTIONS["teamcity"] then
			teamCitySuffix = " --teamCityOutput"
		end

		local maxTestTimeSuffix = ""
		if _OPTIONS["maxtesttime"] then
			maxTestTimeSuffix = " --time=" .. _OPTIONS["maxtesttime"]
		end

		if withLog4CPlus then
			defines "UNITTEST_WITH_LOG4CPLUS"
		end

		-- Do unit test packages so it does not have to be called elsewhere
		DoUnitTestSetup( inputFiles, inputExcludes )

		-- Do mock test packages so it does not have to be called elsewhere
		if mock then
			DoMockTestSetup()
		end

		configuration( { "Debug", "x32 or native" } )
			local projectTargetDir = SolutionTargetDir( false ) or solution().basedir .. "/bin"
			targetsuffix("")
			targetdir( projectTargetDir )
			targetname( pkgName .. "d-tests" )
			postbuildcommands { '"' .. projectTargetDir .. pathSeparator .. targetname() .. '"' .. teamCitySuffix .. maxTestTimeSuffix}

		configuration( { "Release", "x32 or native" } )
			local projectTargetDir = SolutionTargetDir( false ) or solution().basedir .. "/bin"
			targetname( pkgName .. "-tests" )
			targetdir( projectTargetDir )
			postbuildcommands { '"' .. projectTargetDir .. pathSeparator .. targetname() .. '"' .. teamCitySuffix .. maxTestTimeSuffix }

		configuration( { "Debug", "x64" } )
			local projectTargetDir = SolutionTargetDir( false ) or solution().basedir .. "/bin64"
			targetsuffix("")
			targetdir( projectTargetDir )
			targetname( pkgName .. "d64-tests" )
			postbuildcommands { '"' .. projectTargetDir .. pathSeparator .. targetname() .. '"' .. teamCitySuffix .. maxTestTimeSuffix}

		configuration( { "Release", "x64" } )
			local projectTargetDir = SolutionTargetDir( false ) or solution().basedir .. "/bin64"
			targetname( pkgName .. "64-tests" )
			targetdir( projectTargetDir )
			postbuildcommands { '"' .. projectTargetDir .. pathSeparator .. targetname() .. '"' .. teamCitySuffix .. maxTestTimeSuffix }

		configuration( {} )

		createdTestProject = true
	end

	unittest.projectUnderTest = nil
	unittest.projectUnderTestKind = nil

	return createdTestProject
end

-- ENTRY POINT ---------------------------------------------------------
--
local function main()
	-- Check to make sure that the user is not running the '--help' or '--clean' commandline argument.
	if _ACTION  ~= nil then
		if not _OPTIONS["disable-all-tests"] then
			-- Overwride the dofile() so that we can control when the testing projects get added.
			function dofile( projectName )
				-- do the old project like ussual.
				unittest.oldDofile( projectName )

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
