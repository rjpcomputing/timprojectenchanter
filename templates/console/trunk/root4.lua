-- ----------------------------------------------------------------------------
--	Premake script for $(ProjectName).
--	Author:		$(UserName)
--	Date:		$(Date)
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- GENERAL SETUP -------------------------------------------------------------
--
project	"$(ProjectName)"
kind	"ConsoleApp"
files	{ "*.cpp", "*.h", "*.lua", "*.fbp" }

$(Links)

$(IncludeDirs)

-- PROJECT SETUP --------------------------------------------------------------
--
$(Logging)
$(Boost)
--boost.Configure( { "system", "regex", "thread", "wserialization", "serialization", "filesystem" } )
Configure()


-- UNIT TESTING SETTING --------------------------------------------------------
--
