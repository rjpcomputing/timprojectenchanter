#!/usr/bin/env lua

require( "lfs" )

function Subwcrev( nameOfFile, workingDirectory )
	workingDirectory = workingDirectory or "./"
	local svnwcrev
	if windows then
		svnwcrev = "C:/Program Files/TortoiseSVN/bin/SubWCRev.exe"
		if not os.fileexists( svnwcrev )  then
			-- TortoiseSVN is not installed in the default location, so now it is required
			-- to be their PATH.
			svnwcrev = "SubWCRev.exe"
		end
	else
		svnwcrev = "svnwcrev"
	end

	local nameOfTemplate = nameOfFile .. '.template'
	local cmd = '"' .. svnwcrev .. '" ' .. workingDirectory .. ' ' .. nameOfTemplate .. ' ' .. nameOfFile
	assert( 0 == os.execute( cmd ) )
end

if #arg < 2 then
	print( "usage:  " .. arg[0] .. "'url of documentation to checkout' 'working directory'" )
	os.exit(1)
else
	assert( lfs.chdir( arg[2] ), "Failed to change directory to source folder" )
	assert( 0 == os.execute( "rm -rf docs" ), "Failed to delete docs folder" )
	assert( 0 == os.execute( "svn co " .. arg[1] .. " docs" ), "Failed to check out docs" )
	if arg[3] then
		Subwcrev( "Doxyfile" )
	end
	assert( 0 == os.execute( "doxygen" ), "Failed to run doxygen" )

	local autoprops =		"--config-option config:auto-props:*.gif=svn:mime-type=image/gif "
	autoprops = autoprops .. 	"--config-option config:auto-props:*.png=svn:mime-type=image/png " 
	autoprops = autoprops .. 	"--config-option config:auto-props:*.jpg=svn:mime-type=image/jpeg "
	autoprops = autoprops .. 	"--config-option config:auto-props:*.html=svn:mime-type=text/html "
	autoprops = autoprops .. 	"--config-option config:auto-props:*.css=svn:mime-type=text/css "

	assert( 0 == os.execute( "svn add --auto-props " .. autoprops ..  "--force docs/html/*" ), "Failed to add new docs" )
	assert( 0 == os.execute( "svn ci --no-auth-cache --username autobuild --password lucid321 -m docupdate --non-interactive docs" ), "Failed to commit docs" )
end

