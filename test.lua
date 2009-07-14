dofile( "Settings.lua" )
require( "SourceControl" )
local preprocess = require( "luapp" ).preprocess

function TemplateReplace( keywords, path )
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
				params.output = io.output( newName )
				local err, message = preprocess( params )
				if not err then
					error( message )
				end

				if numReplaced > 0 then
					os.remove( f )
				end
			end
		end
	end
end

path = "../"..arg[1] or "../test7"
--path = "/home/rpusztai/devel/lua/timprojectenchanter/test1"
scPath = "http://rjpcomputing.homeip.net/svn/users/rpusztai/tmp/"..(arg[1] or "test7").."/trunk"

print( "-- Export "..Settings.Templates.wxGUI )
print( SourceControl.Export( Settings.Templates.wxGUI, path ) )

print( "-- Make '"..path.."' a working copy" )
print( SourceControl.MakeWorkingCopy( scPath, path ) )
--[[
print( "-- Fill in the template" )
TemplateReplace( { ProjectName = "MyProject" }, path )

print( "-- Add files" )
print( SourceControl.AddFiles( path ) )
]]
print( "-- Add the externals" )
print( SourceControl.SetProperty( "svn:externals", path ) )
--[[
print( "-- Commit to "..scPath )
print( SourceControl.Commit( path, scPath ) )
]]

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
