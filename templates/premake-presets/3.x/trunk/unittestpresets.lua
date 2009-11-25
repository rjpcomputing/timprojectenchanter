-- ----------------------------------------------------------------------------
--	Author:		Ryan Pusztai <rjpcomputing@gmail.com>
--	Date:		05/06/2009
--	Version:	1.00
--
--	Copyright (C) 2008-2009 Ryan Pusztai
-- ----------------------------------------------------------------------------

-- Package options
--addoption( "with-boost-shared", "Link against Boost as a shared library" )

-- Namespace
unittest =
{
	m_testPackages = {}
}

-- HELPER FUNCTIONS -----------------------------------------------------------
--

---	Call this To configure your package to be .
--	@param pkg Premake 'package' passed in that gets all the settings manipulated.
function unittest.Configure( pkg )
	local pkgName = pkg.name

	-- Add the options help.
	addoption( pkgName:lower() .."-tests", "Enable "..pkgName.." tests to run." )

	-- Add the package to the packages to test.
	if options[pkgName:lower().."-tests"] then
		table.insert( unittest.m_testPackages, pkgName )
		-- Convert an "executable" type to a static library so it can be linked
		-- to by the test runner.
		if pkg.kind == "exe" or pkg.kind == "winexe" or pkg.kind == "dll" then
			pkg.kind = "lib"
		end
	end
end
