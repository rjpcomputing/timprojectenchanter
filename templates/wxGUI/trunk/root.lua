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
package.name								= project.name

-- UNIT TESTING SETTING --------------------------------------------------------
--
package.kind								= "winexe"

package.files								= {
												matchfiles( "*.cpp", "*.h", "*.lua", "*.fbp" )
											  }

package.includepaths						= {

											  }

package.links								= {

											  }

-- PACKAGE SETUP --------------------------------------------------------------
--
--boost.Configure( package, { "system", "regex", "thread", "wserialization", "serialization", "filesystem" } )
Configure( package )
wx.Configure( package )
