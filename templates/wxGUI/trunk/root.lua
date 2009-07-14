-- GENERAL SETUP -------------------------------------------------------------
--
package.name								= project.name

-- UNIT TESTING SETTING --------------------------------------------------------
--
package.kind								= "winexe"
package.testdirs							= { "tests" }
package.testexcludes						= { package.name..".cpp" }

package.files								= {
												matchfiles( "*.cpp", "*.h", "*.fbp" )
											  }

package.includepaths						= {
												"lua",
												"gtx",
												"devicecomm",
												"loki",
												"boost_utils",
												"wxtools"
											  }

package.links								= {
												"DeviceComm",
												"LuaLib",
												"gtxComm",
												"gtxAdvanced",
												"gtxCore",
												"Loki"
											  }

-- PACKAGE SETUP --------------------------------------------------------------
--
--boost.Configure( package, { "system", "regex", "thread", "wserialization", "serialization", "filesystem" } )
Configure( package )
wx.Configure( package )
