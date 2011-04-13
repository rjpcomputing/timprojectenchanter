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

kind	"WindowedApp"
files	{ "*.cpp", "*.h", "*.lua", "*.fbp" }

$(Links)

$(IncludeDirs)

-- Configuration SETUP --------------------------------------------------------------
--
$(Configurations)
wx.Configure()
