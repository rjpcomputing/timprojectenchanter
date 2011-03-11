module( "vcs", package.seeall )

-- MODULES --------------------------------------------------------------------
--
local lfs = require( "lfs" )
require( "shell" )
require( "SubLua" )

-- CONFIGURATION --------------------------------------------------------------
--
_VERSION = "0.8"

-- HELPER FUNCTIONS -----------------------------------------------------------
--
local function exists( filename )
	local file = io.open( filename )
	if file then
		io.close( file )
		return true
	else
		return false
	end
end

local function mkpath( path )
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

-- VersionControlSystem CLASS --------------------------------------------------------
--
local svnTim = SubLua.new()

vcs.VersionControlSystem =
{
	projectName		= nil,
	localPath		= nil,
	destinationPath	= nil,
	templatePath	= nil,
}
local VersionControlSystem = vcs.VersionControlSystem
---	VersionControlSystem Constructor.
--	@param o Initial values packaged as a table.
--		Available strings to set:
--			projectName,
--			localPath,
--			destinationPath,
--			templatePath
--	@return The newly created System class.
--	@usage SouceControl:new( {projectName = "MyProject", localPath = "Projects", destinationPath = "http://svn.myweb.com/projects/MyProjects/trunk", templatePath = "http://svn.cooltemplates.com/templates/console/trunk"} )
function VersionControlSystem:new( o )
	o = o or {}	-- Create table if the user does not provide one
	setmetatable( o, self )
	self.__index = self
	return o
end

---	Set the project name. The project name is ussually used to
--	make the directory under the local path destination path.
--	@param name {string} String containing the path to where
--		locally the version control system will work.
function VersionControlSystem:SetProjectName( name )
	self.projectName = name
end

---	Gets the project name. The project name is ussually used to
--	make the directory under the local path destination path.
--	@return {string} The project name.
function VersionControlSystem:GetProjectName()
	return self.projectName
end

---	Set the local destination path.
--	@param path {string} String containing the path to where
--		locally the version control system will work.
function VersionControlSystem:SetLocalPath( path )
	self.localPath = path .. "/" .. self.projectName
end

---	Gets the local destination path.
--	@return {string} The local destination path.
function VersionControlSystem:GetLocalPath()
	return self.localPath .. "/" .. self.projectName
end

---	Set the version control destination path.
--	@param path {string} String containing the path to where
--		the new version controlled files will be kept.
function VersionControlSystem:SetDestinationPath( path )
	self.destinationPath = path
end

---	Gets the version control destination path.
--	@return {string} The version control destination path.
function VersionControlSystem:GetDestinationPath()
	return self.destinationPath
end

---	Set the template/remote version control source path.
--	@param path {string} String containing the path to where
--		the remove vesion controled source is located.
function VersionControlSystem:SetTemplatePath( path )
	self.templatePath = path
end

---	Gets the template location.
--	@return {string} The template location.
function VersionControlSystem:GetTemplatePath()
	return self.templatePath
end

--- Get the code fresh from the repository and save it to path.
--	@param templatePath Source control template path.
--	@param localPath Local path to get the source to.
function VersionControlSystem:Export( templatePath, localPath )
	templatePath	= templatePath or self:GetTemplatePath()
	localPath		= localPath or self:GetLocalPath()

	-- Get all the files out of the template.
	--[[   -- old method using a shell call
	local options = { "export", "--force", "--ignore-externals", templatePath, localPath }
	local status, retVal = shell[Settings.sourceControlExecutable]( options )
	]]

	svnTim:Export( templatePath, localPath, { force=true, ignore_externals=true } )

	-- Get the root directories externals.
	--[[   -- old method using a shell call
	options = { "propget", "svn:externals", templatePath }
	local status, externals = shell[Settings.sourceControlExecutable]( options )
	]]

	print( "--Getting externals:" )
	externals = svnTim:PropGet( "svn:externals", templatePath )

	-- Write a tmp file containing the externals.
	local fHandle = io.output( localPath .. "/svn-props.tmp" )
	for i, value in pairs( externals ) do
		print( " ", i, value )
		fHandle:write( value )
	end
	fHandle:close()

	--return retVal
end

---	Makes a home location for the project in the repository. It also checks the empty home out to the local
--	working copy.
--	@param scPath The path to create in the repository for the project.
--	@param localPath The local path to make a working copy.
--  @param index The index of the type of project to build (console, qt, wx)
function VersionControlSystem:MakeWorkingCopy( scPath, localPath, index )
	scPath			= scPath or self:GetDestinationPath()
	localPath		= localPath or self:GetLocalPath()
	local logMsg	= ""

	-- Create repository location
	local comment = "Created directories automatically."
	--[[   -- old method using a shell call
	local options = { "mkdir", "--parents", "--non-interactive", scPath, "-m", comment }
	local status, logMsg = shell[Settings.sourceControlExecutable]( options )
	]]

	-- Issue #11:  make a trunk directory for the project.  Make the first directory without the /trunk suffix.
	if string.sub( scPath, -5, -1 ) == "trunk" then
		svnTim:MkDir( string.sub( scPath, 1, -7 ), comment )
	end
	svnTim:MkDir( scPath, comment )
	--need the /res folder for wx and qt projects ( console projects have index 0 )
	if index > 0 then
		svnTim:MkDir( scPath.."/res", comment )
	end

	--[[   -- old method using a shell call
	if logMsg:match( "failed" ) then error( logMsg ) end
	--Checkout to the local path.
	options = { "checkout", "--force", "--non-interactive", scPath, localPath }
	local status, retVal = shell[Settings.sourceControlExecutable]( options )

	logMsg = logMsg.."\n"..retVal
	if logMsg:match( "authorization failed" ) then	error( logMsg ) end
	]]

	svnTim:Checkout( scPath, localPath, { force=true } )

	return logMsg
end

function VersionControlSystem:Commit( localPath, scPath )
	localPath	= localPath or self:GetLocalPath()
	scPath		= scPath or self:GetDestinationPath()

	-- Commit the changes to create the fresh project.
	local comment = "Initial import created by Tim the Project Enchanter."
	--[[   -- old method using a shell call
	local options = { "commit", "--non-interactive", localPath, "-m", comment }
	local status, logMsg = shell[Settings.sourceControlExecutable]( options )
	]]
	svnTim:Commit( localPath, comment )

	--return logMsg
end

function VersionControlSystem:Update( localPath )
	localPath = localPath or self:GetLocalPath()

	-- Update the WC.
	--[[   -- old method using a shell call
	local options = { "update", "--non-interactive", localPath }
	local status, logMsg = shell[Settings.sourceControlExecutable]( options )
	]]
	svnTim:Update( localPath )

	--return logMsg
end

function VersionControlSystem:AddFiles( localPath )
	localPath		= localPath or self:GetLocalPath()
	local logMsg	= ""

	for file in lfs.dir( localPath ) do
		if file ~= "." and file ~= ".." and file ~= ".svn" and file ~= "svn-props.tmp" then
			local f = localPath..'/'..file
			print( "\t"..f )
			local attr = lfs.attributes( f )
			assert( type( attr ) == "table" )
			if attr.mode == "directory" then
				VersionControlSystem:AddFiles( f )
			else
				-- Add the file
				--[[   -- old method using a shell call
				local options = { "add", "--parents", "--non-interactive", f }
				local status, msg = shell[Settings.sourceControlExecutable]( options )
				logMsg = logMsg..msg
				]]
				svnTim:Add( f,  { add_parents } )
			end
		end
	end

	return logMsg
end

function VersionControlSystem:SetProperty( property, localPath )
	localPath		= localPath or self:GetLocalPath()
	local status	= nil
	local retVal	= property.." not found."

	-- Get the root directories externals.
	local propFile = localPath.."/svn-props.tmp"
	if exists( propFile ) then
		--[[   -- old method using a shell call
		local options = { "propset", property, "--file", propFile, localPath }
		status, retVal = shell[Settings.sourceControlExecutable]( options )
		]]

		local fHandle = io.input( localPath .. "/svn-props.tmp" )
		propValue = fHandle:read( "*all" )
		fHandle:close()

		print( "   Property:", property )
		print( "   Property Value:", propValue )
		print( "   Path:", localPath )
		svnTim:PropSet( property, propValue, localPath, { recurse=false } )
		os.remove( propFile )
	end

	return retVal
end

return _M
