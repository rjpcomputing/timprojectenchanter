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
files	{ "*.cpp", "*.h", "*.lua" }

$(Links)

$(IncludeDirs)

MakeVersion( "$(ProjectName)Version.h" )

-- Configuration SETUP --------------------------------------------------------------
--
$(Configurations)
local mocFiles				= { "$(ProjectName)Frame.h" }
local qrcFiles				= { os.matchfiles( "*.qrc" ) }
local uiFiles				= { os.matchfiles( "*.ui" ) }
local libsToLink			= { "Core", "Gui" }
qt.Configure( mocFiles, qrcFiles, uiFiles, libsToLink )
