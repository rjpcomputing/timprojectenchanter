-- ----------------------------------------------------------------------------
--	Author:		Josh Lareau <joshua.lareau@gentex.com>
--	Date:		12/21/2010
--  Version:    1.0.0
--	Title:		PocoPrebuild
-- ----------------------------------------------------------------------------

require("lfs")
require( "LuaXml" )

-- Build an error output string with line numbers
function BuildErrorWarningString( line, isError, message )
	return string.format( arg[0]..":%i: %s: %s", line, isError and "error" or "warning", message )
end

-- Get the file name (without its extension) from a full path
-- @param path The path of a file, including any seperators
--
function GetFileNameNoExtFromPath( path )

	local i = 0
	local lastSlash = 0
	local lastPeriod = 0
	local returnFilename
	while true do
		i = string.find( path, "/", i+1 )
		if i == nil then break end
		lastSlash = i
	end

	i = 0

	while true do
		i = string.find( path, "%.", i+1 )
		if i == nil then break end
		lastPeriod = i
	end

	if lastPeriod < lastSlash then
		returnFilename = path:sub( lastSlash + 1 )
	else
		returnFilename = path:sub( lastSlash + 1, lastPeriod - 1 )
	end

	return returnFilename
end

-- Get just the dir name from a file path
-- @param file The file you want to extract the dir from
function GetDirNameFromFile( file )

	local i = 0
	local lastSlash = 0
	local dirName

	while true do
		i = string.find( file, "/", i+1 )
		if i == nil then break end
		lastSlash = i
	end

	dirName = file:sub( 0, lastSlash - 1  )

	return dirName

end

function Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

-- Make sure all the args are passed in
if not ( #arg >= 4 ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, "There must be at least 4 arguments supplied" ) ); io.stdout:flush()
	return
end

-- Command Line args

-- Required
local GENERATE_MODE = arg[1] or ""
local INPUT_FILE = arg[2] or ""
local POCO_PATH = arg[3] or ""
local PREMAKE_TARGET = arg[4] or ""

-- optional (warnings)
local REMOTEGEN_XML = arg[5] or ""
local REMOTEGEN_HEADER_OUTPUT = arg[6] or ""
local REMOTEGEN_SOURCE_OUTPUT = arg[7] or ""

-- Optional (no warnings)
local SERVICE_LOCATION = arg[8] or ""
local WSDL_OUTPUT = arg[9] or ""
local LIBRARY_EXPORT = arg[10] or ""
local OSP_ENABLE = arg[11] or "false"
local OSP_BUNDLE_ACTIVATOR = arg[12] or "false"

-- Errors
if not ( "client" == GENERATE_MODE or "server" == GENERATE_MODE or "interface" == GENERATE_MODE or "both" == GENERATE_MODE or
		 "Client" == GENERATE_MODE or "Server" == GENERATE_MODE or "Interface" == GENERATE_MODE or "Both" == GENERATE_MODE ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The mode argument must be "client", "server", "interface", or "both"]]  ) ); io.stdout:flush()
	return
end

if "" == INPUT_FILE then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The input file path is empty]]  ) ); io.stdout:flush()
	return
end

if "" == POCO_PATH then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The path to the poco installation is empty]]  ) ); io.stdout:flush()
	return
end

if "" == PREMAKE_TARGET then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The premake target is empty]]  ) ); io.stdout:flush()
	return
end

-- Warnings
if "" == REMOTEGEN_XML then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, false, [[The RemoteGen.XML output path is empty. Will default to "./RemoteGen.XML"]]  ) ); io.stdout:flush()
	REMOTEGEN_XML = "./RemoteGen.xml"
end

if "" == REMOTEGEN_HEADER_OUTPUT then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, false, [[The RemoteGen header output path is empty. Will default to "./Generated Files/Header Files"]]  ) ); io.stdout:flush()
	REMOTEGEN_HEADER_OUTPUT = "Generated Files/Header Files/"
end

if "" == REMOTEGEN_SOURCE_OUTPUT then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, false, [[The RemoteGen source output path is empty. Will default to "./Generated Files/Source Files"]]  ) ); io.stdout:flush()
	REMOTEGEN_SOURCE_OUTPUT = "Generated Files/Source Files/"
end

-- Make sure input file exists
local inputFileModTime = lfs.attributes( INPUT_FILE, "modification" )
if inputFileModTime == nil then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The supplied input file ]]..INPUT_FILE..[[, does not exist]] ) ); io.stdout:flush()
	return
end

-- Determine if we need to regenerate
local outputFileModTime = lfs.attributes( REMOTEGEN_XML, "modification" )
if outputFileModTime ~= nil and ( inputFileModTime < outputFileModTime ) then
	print( REMOTEGEN_XML.." is up-to-date, not regenerating" ); io.stdout:flush()
	return
end

-- Create the RemoteGen.xml
print( "Generating RemoteGen config file: \""..REMOTEGEN_XML.."\"..." ); io.stdout:flush()

-- Include files
local requiredIncludes = POCO_PATH.."/Remoting/include/poco/Remoting/RemoteObject.h,"..POCO_PATH.."/Remoting/include/poco/Remoting/Proxy.h,"..POCO_PATH.."/Remoting/include/poco/Remoting/Skeleton.h,"
local files_include = requiredIncludes..INPUT_FILE
--local files_exclude = ""

-- Output
local output_mode = GENERATE_MODE
local output_include = REMOTEGEN_HEADER_OUTPUT
local output_src = REMOTEGEN_SOURCE_OUTPUT
local output_schema = WSDL_OUTPUT --Determines where the WSDL file is placed
--local output_namespace = ""
local output_copyright = "$Id: pocoprebuild.lua 12529 2010-12-21 21:52:08Z jlareau $" --SVN keyword property
--local output_includeRoot = ""
--local output_flatIncludes = ""
local output_library = LIBRARY_EXPORT
--local output_alwaysInclude = ""

-- OSP
local output_bundle = GetDirNameFromFile( REMOTEGEN_XML ) --If code generation for the Open Service Platform has been enabled this element specifies the directory where files that go into the client bundle are generated.
local output_osp_bundleActivator = GetFileNameNoExtFromPath( INPUT_FILE ).."BundleActivator" --Specify whether a bundle activator for use with the Open Service Platform should be generated.

-- Compiler
local compiler_type = ""
local compiler_options = ""
--local compiler_path = ""

if string.find( PREMAKE_TARGET or "", "vs*" ) then

	compiler_type = "cl"
	compiler_options = "/I "..'"'..POCO_PATH.."/Foundation/include"..'"'..",/I "..'"'..POCO_PATH.."/Remoting/include"..'"'..",/nologo,/C,/P,/TP"

elseif PREMAKE_TARGET == "gnu" or string.find( PREMAKE_TARGET or "", ".*-gcc" ) then

	local headerIncludePath = GetDirNameFromFile( INPUT_FILE )
	compiler_type = "g++"
	compiler_options = "-I"..POCO_PATH.."/Foundation/include"..",-I"..POCO_PATH.."/Remoting/include"..",-I"..headerIncludePath..",-E,-C,-o%.i"

else

	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[This Premake Target is not supported: ]]..PREMAKE_TARGET ) ); io.stdout:flush()
	return

end

-- Root XML
local appConfig = xml.new("AppConfig")
local remoteGen = appConfig:append("RemoteGen");

-- Files XML
local files = xml.new("files")
files:append("include")[1] = files_include
--files:append("exclude")[1] = files_exclude

-- Output XML
local output = xml.new("output")
output:append("mode")[1] = output_mode
output:append("include")[1] = output_include
output:append("src")[1] = output_src
output:append("schema")[1] = output_schema
--output:append("namespace")[1] = output_namespace
output:append("copyright")[1] = output_copyright
--output:append("includeRoot")[1] = output_includeRoot
--output:append("flatIncludes")[1] = output_flatIncludes
output:append("library")[1] = output_library
--output:append("alwaysInclude")[1] = output_alwaysInclude

-- OSP output
if "true" == OSP_ENABLE then
	output:append("bundle")[1] = output_bundle

	local OSP = output:append("osp")
	OSP:append("enable")[1] = OSP_ENABLE

	if "true" == OSP_BUNDLE_ACTIVATOR then
		OSP:append("bundleActivator")[1] = output_osp_bundleActivator
	end
end

-- Compiler XML
local compiler = xml.new("compiler")
compiler:append("exec")[1] = compiler_type
compiler:append("options")[1] = compiler_options
--compiler:append("path")[1] = compiler_path

-- Full XML
remoteGen[1] = files
remoteGen[2] = output
remoteGen[3] = compiler

-- If the user passed in a service name, then add the SOAP WSDL generation
if "" ~= SERVICE_LOCATION then
	local WSDL_serviceName = GetFileNameNoExtFromPath( INPUT_FILE )
	local WSDL = xml.new("schema")
	local service = WSDL:append( WSDL_serviceName )
	service:append("serviceLocation")[1] = SERVICE_LOCATION
	remoteGen[4] = WSDL
end

--print(appConfig)

-- Split dir name into components and create each dir if it doesn't exist
local splitDir = Split( GetDirNameFromFile( REMOTEGEN_XML ), "/" )
local builtPath = ""
for _,dirEntry in pairs( splitDir ) do

	if "" ~= builtPath then
		builtPath = builtPath.."/"..dirEntry
	else
		builtPath = dirEntry
	end

	mkdirError,mkdirReason = lfs.mkdir( builtPath )

	--print( mkdirError );io.stdout:flush()
	--print( mkdirReason );io.stdout:flush()
end

-- Save the XML file to disk
xml.save( appConfig, REMOTEGEN_XML )

-- Run the remote generator
local remoteGenCommand = POCO_PATH.."/bin/RemoteGen.exe /mode:"..GENERATE_MODE.." "..'"'..REMOTEGEN_XML..'"'

print( "Invoking RemoteGen tool: \""..remoteGenCommand.."\"..." ); io.stdout:flush()

if( 0 ~= os.execute( remoteGenCommand ) ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[RemoteGen Failed!]] ) ); io.stdout:flush()
	return
else
	print( "RemoteGen Completed." ); io.stdout:flush()
end
