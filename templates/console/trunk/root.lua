-- GENERAL SETUP -------------------------------------------------------------
--
package.name								= project.name

-- UNIT TESTING SETTING --------------------------------------------------------
--
package.kind								= "exe"

package.files								= {
												matchfiles( "*.cpp", "*.h", "*.fbp" )
											  }

package.includepaths						= {

											  }

package.links								= {

											  }

-- PACKAGE SETUP --------------------------------------------------------------
--
--boost.Configure( package, { "system", "regex", "thread", "wserialization", "serialization", "filesystem" } )
Configure( package )
