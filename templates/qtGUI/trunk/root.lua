-- ----------------------------------------------------------------------------
--	Premake script for $(ProjectName).
--	Author:		$(UserName)
--	Date:		$(Date)
--	Version:	1.00
--
--	Notes:
-- ----------------------------------------------------------------------------

-- GENERAL SETUP --------------------------------------------------------------
--
package.name								= project.name

-- COMPILER SETTING -----------------------------------------------------------
--
package.kind								= "winexe"

package.files								= {
												matchfiles( "*.cpp", "*.h", "*.lua" )
											  }

package.includepaths						= {

											  }

package.links								= {

											  }

MakeVersion( "$(ProjectName)Version.h" )

-- PACKAGE SETUP --------------------------------------------------------------
--
--boost.Configure( package, { "system", "regex", "thread", "wserialization", "serialization", "filesystem" } )
Configure( package )
local mocFiles				= { "$(ProjectName)Frame.h" }
local qrcFiles				= { matchfiles( "*.qrc" ) }
local uiFiles				= { matchfiles( "*.ui" ) }
local libsToLink			= { "Core", "Gui" }
qt.Configure( package, mocFiles, qrcFiles, uiFiles, libsToLink )
