-- GENERAL SETUP -------------------------------------------------------------
--
project	"$(ProjectName)"

-- UNIT TESTING SETTING --------------------------------------------------------
--
kind	"ConsoleApp"
files	{ "*.cpp", "*.h", "*.lua", "*.fbp" }

-- PROJECT SETUP --------------------------------------------------------------
--
--boost.Configure( { "system", "regex", "thread", "wserialization", "serialization", "filesystem" } )
Configure()
