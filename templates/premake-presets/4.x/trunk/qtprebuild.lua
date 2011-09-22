require("lfs")

local qtDirectory = ""
qtDirectory = arg[3] or qtDirectory

function BuildErrorWarningString( line, isError, message, code )
	if windows then
		return string.format( "build\\qtprebuild.lua(%i): %s %i: %s", line, isError and "error" or "warning", code, message )
	else
		return string.format( "build\\qtprebuild.lua:%i: %s: %s", line, isError and "error" or "warning", message )
	end
end

--Make sure there are at least 2 arguments
if not ( #arg >= 2 ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, "There must be at least 2 arguments supplied", 2 ) ); io.stdout:flush()
	return
end

--Checks that the first argument is either "-moc", "-uic", or "-rcc"
if not ( arg[1] == "-moc" or arg[1] == "-uic" or arg[1] == "-rcc" ) then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The first argument must be "-moc", "-uic", or "-rcc"]], 3 ) ); io.stdout:flush()
	return
end

--Make sure input file exists
inputFileModTime = lfs.attributes( arg[2], "modification" )
if inputFileModTime == nil then
	print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[The supplied input file ]]..arg[2]..[[, does not exist]], 4 ) ); io.stdout:flush()
	return
end

qtMocOutputDirectory		= "qt_moc"
qtQRCOutputDirectory		= "qt_qrc"
qtUIOutputDirectory			= "qt_ui"

qtMocPrefix					= "moc_"
qtQRCPrefix					= "qrc_"
qtUIPrefix					= "ui_"

windows = package.config:sub( 1, 1 ) == "\\"
del = "\\"
if not windows then
	del = "/"
end

--Set up the qt tools executable path
if windows then
	qtMocExe = qtDirectory..del.."bin"..del..[[moc.exe]]
	qtUICExe = qtDirectory..del.."bin"..del..[[uic.exe]]
	qtQRCExe = qtDirectory..del.."bin"..del..[[rcc.exe]]
else
	qtMocExe = "moc"
	qtUICExe = "uic"
	qtQRCExe = "rcc"
end

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

if arg[1] == "-moc" then
	lfs.mkdir( qtMocOutputDirectory )
	outputFileName = qtMocOutputDirectory..del..qtMocPrefix..GetFileNameNoExtFromPath( arg[2] )..".cpp"

	outputFileModTime = lfs.attributes( outputFileName, "modification" )
	if outputFileModTime ~= nil and ( inputFileModTime < outputFileModTime ) then
		print( outputFileName.." is up-to-date, not regenerating" ); io.stdout:flush()
		return
	end

	local fullMOCPath = qtMocExe.." \""..arg[2].."\" -o \""..outputFileName.."\""
	if windows then
		fullMOCPath = '""'..qtMocExe..'" "'..arg[2]..'" -o "'..outputFileName..'""'
	end

	if( 0 ~= os.execute( fullMOCPath ) ) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[MOC Failed to generate ]]..outputFileName, 5 ) ); io.stdout:flush()
	else
		print( "MOC Created "..outputFileName ); io.stdout:flush()
	end
elseif arg[1] == "-rcc" then
	lfs.mkdir( qtQRCOutputDirectory )
	outputFileName = qtQRCOutputDirectory..del..qtQRCPrefix..GetFileNameNoExtFromPath( arg[2] )..".cpp"

	outputFileModTime = lfs.attributes( outputFileName, "modification" )
	if outputFileModTime ~= nil and ( inputFileModTime < outputFileModTime ) then
		print( outputFileName.." is up-to-date, not regenerating" ); io.stdout:flush()
		return
	end

	local fullRCCPath = qtQRCExe.." -name \""..GetFileNameNoExtFromPath( arg[2] ).."\" \""..arg[2].."\" -o \""..outputFileName.."\""
	if windows then
		fullRCCPath = '""'..qtQRCExe..'" -name "'..GetFileNameNoExtFromPath( arg[2] )..'" "'..arg[2]..'" -o "'..outputFileName..'""'
	end

	if( 0 ~= os.execute( fullRCCPath ) ) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[RCC Failed to generate ]]..outputFileName, 6 ) ); io.stdout:flush()
	else
		print( "RCC Created "..outputFileName ); io.stdout:flush()
	end
elseif arg[1] == "-uic" then
	lfs.mkdir( qtUIOutputDirectory )
	outputFileName = qtUIOutputDirectory..del..qtUIPrefix..GetFileNameNoExtFromPath( arg[2] )..".h"

	outputFileModTime = lfs.attributes( outputFileName, "modification" )
	if outputFileModTime ~= nil and ( inputFileModTime < outputFileModTime ) then
		print( outputFileName.." is up-to-date, not regenerating" ); io.stdout:flush()
		return
	end

	local fullUICPath = qtUICExe.." \""..arg[2].."\" -o \""..outputFileName.."\""
	if windows then
		fullUICPath = '""'..qtUICExe..'" "'..arg[2]..'" -o "'..outputFileName..'""'
	end

	if( 0 ~= os.execute( fullUICPath ) ) then
		print( BuildErrorWarningString( debug.getinfo(1).currentline, true, [[UIC Failed to generate ]]..outputFileName, 7 ) ); io.stdout:flush()
	else
		print( "UIC Created "..outputFileName ); io.stdout:flush()
	end
end

