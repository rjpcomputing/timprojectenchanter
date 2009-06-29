local lfs		= require( "lfs" )
require( "shell" )
--[[local assert	= assert
local io		= io
local os		= os
local string	= string
local table		= table
local type		= type
--local print		= print
local error		=	error
local Settings	= Settings
]]
module( "SourceControl", package.seeall )
_VERSION = "0.7"

function exists( filename )
	local file = io.open( filename )
	if file then
		io.close( file )
		return true
	else
		return false
	end
end

function mkpath( path )
	assert( type( path ) == "string", "Param1: type incorrect. Expected a string found "..type( path ) )

	local t = {}
	local drive = ""
	-- Convert path to posix because it works.
	path, num = path:gsub( "\\", "/" )
	if num > 0 then
		drive = string.gmatch( path, "(%w+)" )()..":"
	end

	local steps = drive
	for pathChunk in string.gmatch( path, "(%a+)/") do
		steps = steps..'/'..pathChunk
		table.insert( t, steps )
	end

	table.foreachi( t, print )
	-- Create the directory structure
	--assert( lfs.mkdir( path ) )
end

local function RunProcess( command )
	--print( command )
	local processHandle, err = io.popen( command )
	local retVal = ""

	if processHandle then
		retVal = processHandle:read( "*a" )
		--[[for line in processHandle:lines() do
			retVal = retVal..line.."\n"
			--print( line )
	    end]]

	    processHandle:close()
	else
		error( err )
	end

	return retVal
end

--- Get the code fresh from the repository and save it to path.
--	@param scTemplatePath Source control template path.
--	@param path Local path to get the source to.
function Export( scTemplatePath, path )
	-- Get all the files out of the template.
	local options = { "export", "--force", "--ignore-externals", scTemplatePath, path }
	local status, retVal = shell[Settings.sourceControlExecutable]( options )
	--local cmdToRun = Settings.sourceControlExecutable.." export --force --ignore-externals "..scTemplatePath.." "..path
	--local retVal = RunProcess( cmdToRun )

	-- Get the root directories externals.
	options = { "propget", "svn:externals", scTemplatePath }
	local status, externals = shell[Settings.sourceControlExecutable]( options )
	--cmdToRun = Settings.sourceControlExecutable.." propget svn:externals "..scTemplatePath
	--local externals = RunProcess( cmdToRun )
	-- Write a tmp file containing the externals.
	if #externals > 0 then
		local fHandle = io.output( path.."/svn-props.tmp" )
		fHandle:write( externals )
		fHandle:close()
	end

	return retVal
end

---	Makes a home location for the project in the repository. It also checks the empty home out to the local
--	working copy.
--	@param scPath The path to create in the repository for the project.
--	@param path The local path to make a working copy.
function MakeWorkingCopy( scPath, path )
	local logMsg = ""
	-- Create repository location
	local comment = "Created directories automatically."
	local options = { "mkdir", "--parents", "--non-interactive", scPath, "-m", comment }
	local status, logMsg = shell[Settings.sourceControlExecutable]( options )
	--local cmdToRun = Settings.sourceControlExecutable.." mkdir --parents --non-interactive --username="..Settings.sourceControlUsername.." --password="..Settings.sourceControlPassword.." "..scPath..' -m "'..comment..'"'
	--local cmdToRun = Settings.sourceControlExecutable.." mkdir --parents --non-interactive "..scPath..' -m "'..comment..'"'
	--local logMsg = RunProcess( cmdToRun )
	--print( "-->", logMsg )
	if logMsg:match( "failed" ) then error( logMsg ) end
	-- Checkout to the local path.
	options = { "checkout", "--force", "--non-interactive", scPath, path }
	local status, retVal = shell[Settings.sourceControlExecutable]( options )
	--cmdToRun = Settings.sourceControlExecutable.." checkout --force --non-interactive --username="..Settings.sourceControlUsername.." --password="..Settings.sourceControlPassword.." "..scPath.." "..path
	--cmdToRun = Settings.sourceControlExecutable.." checkout --force --non-interactive "..scPath.." "..path
	--logMsg = logMsg.."\n"..RunProcess( cmdToRun )
	logMsg = logMsg.."\n"..retVal
	if logMsg:match( "authorization failed" ) then	error( logMsg ) end
	
	return logMsg
end

function Commit( path, scPath )
	-- Commit the changes to create the fresh project.
	local comment = "Initial import created by Tim the Project Enchanter."
	local options = { "commit", "--non-interactive", path, "-m", comment }
	--local cmdToRun = Settings.sourceControlExecutable.." commit --non-interactive --username="..Settings.sourceControlUsername.." --password="..Settings.sourceControlPassword.." "..path..' -m "'..comment..'"'
	--local cmdToRun = Settings.sourceControlExecutable.." commit --non-interactive "..path..' -m "'..comment..'"'
	local logMsg = RunProcess( cmdToRun )
	local status, logMsg = shell[Settings.sourceControlExecutable]( options )
	
	return logMsg
end

function AddFiles( path )
	local logMsg = ""
	
	for file in lfs.dir( path ) do
		if file ~= "." and file ~= ".." and file ~= ".svn" and file ~= "svn-props.tmp" then
			local f = path..'/'..file
			--print( "\t "..f )
			local attr = lfs.attributes( f )
			assert( type( attr ) == "table" )
			if attr.mode == "directory" then
				AddFiles( f )
			else
				-- Add the file
				local options = { "add", "--parents", "--non-interactive", f }
				local status, msg = shell[Settings.sourceControlExecutable]( options )
				logMsg = logMsg..msg
				--local cmdToRun = Settings.sourceControlExecutable.." add --parents --non-interactive --username="..Settings.sourceControlUsername.." --password="..Settings.sourceControlPassword.." "..f
				--local cmdToRun = Settings.sourceControlExecutable.." add --parents --non-interactive "..f
				--logMsg = logMsg..RunProcess( cmdToRun )
			end
		end
	end

	return logMsg
end

function SetProperty( property, path )
	-- Get the root directories externals.
	local propFile = path.."/svn-props.tmp"
	if exists( propFile ) then
		local options = { "propset", property, "--file", propFile, path }
		local staus, retVal = shell[Settings.sourceControlExecutable]( options )
		--local cmdToRun = Settings.sourceControlExecutable.." propset "..property.." --file "..propFile.." "..path
		--local retval = RunProcess( cmdToRun )
		os.remove( propFile )
	end

	return retVal
end
