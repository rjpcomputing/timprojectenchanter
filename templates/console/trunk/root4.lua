-- ----------------------------------------------------------------------------
--	Premake script for $(ProjectName).
--	Author:		$(UserName)
--	Date:		$(Date)
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- PROJECT SETUP -------------------------------------------------------------
--
project	"$(ProjectName)"

kind	"ConsoleApp"
files	{ "*.cpp", "*.h", "*.lua" }

$(Links)

$(IncludeDirs)

-- Configuration SETUP --------------------------------------------------------------
--
$(Configurations)
