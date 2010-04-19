dofile( "Settings.lua" )
require( "vcs" )
local preprocess = require( "luapp" ).preprocess

local function TemplateReplace( keywords, path )
	if type( keywords ) ~= "table" then
		error( "bad argument #1 to TemplateReplace' (Expected table but recieved "..type( keywords )..")" )
	end

	local params =
	{
		lookup = _G,
	}
	-- Add the custom variables to the lookup table.
	params.lookup.Generator = "Tim the Project Enchanter"
	params.lookup.GeneratorURL = "http://timprojectenchanter.googlecode.com"
	params.lookup.GeneratorSlogan = "Putting the big nasty teeth in project generation."
	params.lookup.UserName = os.getenv( "USER" ) or os.getenv( "USERNAME" )
	params.lookup.Date = os.date()

	for keyword, value in pairs( keywords ) do
		params.lookup[keyword] = value
	end

	-- Loop through files and rename each one
	for file in lfs.dir( path ) do
		if file ~= "." and file ~= ".." and file ~= ".svn" and file ~= "svn-props.tmp" then
			local f = path..'/'..file
			print( "\t "..f )
			local attr = lfs.attributes( f )
			assert( type( attr ) == "table" )
			if attr.mode == "directory" then
				TemplateReplace( keywords, f )
			else
				-- Rename the file.
				local newName, numReplaced = f:gsub( "root", keywords.ProjectName )

				-- Find and replace all known variables in the files.
				params.input = io.input( f )

				-- Check if the file name changed and only output the file if it has,
				-- else output the preprocessed text to a string to write back later.
				if numReplaced > 0 then
					params.output = io.output( newName )
				else
					params.output = "string"
				end

				local ret, message = preprocess( params )
				if not ret then
					error( message )
				end

				if numReplaced > 0 then
					params.output:close()
					params.input:close()

					assert( os.remove( f ) )
				else
					-- Write the changes back to the file.
					local fHandle = io.output( f )
					fHandle:write( ret )
					fHandle:close()
				end
			end
		end
	end
end

local defaultDir = arg[1] or "test15"
print(vcs)
table.foreach( vcs, print )
local projectName = "MyProject"
local path = "../" .. defaultDir
local scPath = "http://rjpcomputing.homeip.net/svn/users/rpusztai/tmp/" .. defaultDir .. "/trunk"
local template = Settings.Templates.wxGUI

local sc = vcs.VersionControlSystem:new( {projectName = projectName, localPath = path, destinationPath = scPath, templatePath =  Settings.Templates.wxGUI } )

print( "-- Export "..template )
print( sc:Export() )

print( "-- Make '"..path.."' a working copy" )
print( sc:MakeWorkingCopy() )

print( "-- Fill in the template" )
TemplateReplace( { ProjectName = projectName }, path )

print( "-- Add files" )
print( sc:AddFiles() )

print( "-- Add the externals" )
print( sc:SetProperty( "svn:externals" ) )

print( "-- Commit to "..scPath )
print( sc:Commit() )

print( "-- Update "..path )
print( sc:Update() )

--[[
local params =
{
	lookup = _G,
}
-- Add the custom variables to the lookup table.
params.lookup.Generator = "Tim the Project Enchanter"
params.lookup.GeneratorURL = "http://timprojectenchanter.googlecode.com"
params.lookup.GeneratorSlogan = "Putting the big nasty teeth in project generation."
params.lookup.UserName = os.getenv( "USER" ) or os.getenv( "USERNAME" )
params.lookup.Date = os.date()
params.lookup.ProjectName = arg[1] or "Pooter"

local f = "res1.manifest"
local newName = "res1.manifest"
-- Find and replace all known variables in the files.
params.input = io.input( f )
params.output = "string" --io.output( newName )
local err, message = preprocess( params )
print( err )
print('------------------------------------------')
print( message )
--print( preprocess( params ) )
if not err then
	error( message )
end

local fHandle = io.output( newName )
fHandle:write( err )
fHandle:close()
]]
