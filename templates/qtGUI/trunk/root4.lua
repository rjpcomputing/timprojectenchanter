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

-- UNIT TESTING SETTING --------------------------------------------------------
--
kind	"WindowedApp"
files	{ "*.cpp", "*.h", "*.lua" }

MakeVersion( "$(ProjectName)Version.h" )

-- PROJECT SETUP --------------------------------------------------------------
--
--boost.Configure( { "system", "regex", "thread", "wserialization", "serialization", "filesystem" } )
Configure()
local mocFiles				= { "$(ProjectName)Frame.h" }
local qrcFiles				= { os.matchfiles( "*.qrc" ) }
local uiFiles				= { os.matchfiles( "*.ui" ) }
local libsToLink			= { "Core", "Gui" }
qt.Configure( mocFiles, qrcFiles, uiFiles, libsToLink )
