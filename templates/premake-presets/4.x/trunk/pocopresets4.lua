-- ----------------------------------------------------------------------------
--	Author:		JR Lewis      <jason.lewis@gentex.com>
--	Date:		09/14/2011
--	Version:	1.0.0
--	Title:		Poco premake4 presets (In Development!)
-- ----------------------------------------------------------------------------

newoption
{
    trigger = "poco-shared",
    description = "Link against Poco as a shared library."
}

newoption
{
    trigger = "no-poco-tests",
    description = "No poco unit tests will be run post-build."
}

newoption
{
    trigger = "disable-all-tests",
    description = "Disable the unit tests from running."
}

language "c++"


if _ACTION == "vs2008" then
    error( "Visual Studio 2008 (9.0) is not supported!" )
end

if _OPTIONS[ "poco-shared" ] then
    kind "SharedLib"
    targetdir ( solution().basedir .. "/bin" )
    if os.get() == "windows" then
        buildoptions { "/MDd" }
    end
else
    kind "StaticLib"
    targetdir ( solution().basedir .. "/lib" )
    defines { "POCO_STATIC", "PCRE_STATIC" }
end

if os.get() == "windows" then
    defines { "_WINDOWS", "_WIN32", "WIN32", "_CRT_SECURE_NO_DEPRECATE" }
end

if os.get() == "linux" then
    defines { "LINUX", "_LINUX", "_REENTRANT", "_THREAD_SAFE" }
    libdirs { "/usr/lib/i386-linux-gnu/" }
end


includedirs { "include" , "../Foundation/include" }
files { "include/**.h" }

configuration { "Debug" }
    targetsuffix "d"
    defines { "_DEBUG" }

configuration { "Release" }

configuration( "vs2008 or vs2010" )
    flags( "NoMinimalRebuild" )
    buildoptions( "/MP" )


-- Namespace
poco = {}
poco.version = "2009.2.4" -- default poco version

-- Insure that all environmental variables are defined.
local open_ssl_path = os.getenv("SSL_INCLUDE")
if "" == open_ssl_path then
    print("Poco requires that environment variable OPENSSL_DIR be defined and ")
    print("point at the OpenSSL include directory.")
end



