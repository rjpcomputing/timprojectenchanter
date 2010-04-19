#!/usr/bin/env lua
-- ----------------------------------------------------------------------------
-- Name:		Tim.lua
-- Purpose:		Helps start a project easily, using Subversion to store the
-- 				template project files.
-- Author:		R. Pusztai
-- Modified by:
-- Created:		03/28/2009
-- License:		Copyright (C) 2009 RJP Computing. All rights reserved.
--
--	Permission is hereby granted, free of charge, to any person obtaining a copy
--	of this software and associated documentation files (the "Software"), to deal
--	in the Software without restriction, including without limitation the rights
--	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--	copies of the Software, and to permit persons to whom the Software is
--	furnished to do so, subject to the following conditions:
--
--	The above copyright notice and this permission notice shall be included in
--	all copies or substantial portions of the Software.
--
--	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
--	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--	THE SOFTWARE.
-- ----------------------------------------------------------------------------
dofile( "Settings.lua" )
require( "wx" )
require( "lfs" )
--require( "luapp" )
require( "Resources" )
require( "vcs" )
local preprocess = require( "luapp" ).preprocess

-- ----------------------------------------------------------------------------
-- CONSTANTS
-- ----------------------------------------------------------------------------
local APP_NAME			= "Tim the Project Enchanter"
local APP_VERSION		= "1.01"
local ID_IDCOUNTER		= nil

-- ----------------------------------------------------------------------------
-- HELPER FUNCTIONS
-- ----------------------------------------------------------------------------

-- Equivalent to C's "cond ? a : b", all terms will be evaluated
local function iff( cond, a, b )
	if cond then
		return a
	else
		return b
	end
end

-- Generate a unique new wxWindowID
local function NewID()
    ID_IDCOUNTER = ( ID_IDCOUNTER or wx.wxID_HIGHEST ) + 1
    return ID_IDCOUNTER
end

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

-- ----------------------------------------------------------------------------
-- Class Declaration
-- ----------------------------------------------------------------------------
local TimGUI =
{
	-- GUI control variables
	--
	frame								= nil,		-- The wxFrame of the program
	panel								= nil,		-- The main wxPanel child of the wxFrame
	sourceControlLocationTextCtrl		= nil,
	sourceControlOpenButton				= nil,
	projectNameTextCtrl					= nil,
	projectDestinationDirPicker			= nil,
	createProjectButton					= nil,
	projectTypeChoice					= nil,
	logTextCtrl							= nil,

	-- Initialize the wxConfig for loading/saving the preferences
	--
	config 								= nil,

	-- CONTROL ID'S
	--
	-- File menu.
	ID_FILE_OPEN						= wx.wxID_OPEN,
	ID_FILE_EXIT						= wx.wxID_EXIT,
	-- Help menu
	ID_HELP_ABOUT						= wx.wxID_ABOUT,
	-- Controls
	ID_SOURCE_CONTROL_LOCATION_TEXTCTRL	= NewID(),
	ID_SOURCE_CONTROL_OPEN_BUTTON		= NewID(),
	ID_PROJECT_NAME_TEXTCTRL			= NewID(),
	ID_PROJECT_DESTINATION_DIR_PICKER	= NewID(),
	ID_CREATE_PROJECT_BUTTON			= NewID(),
	ID_PROJECT_TYPE_CHOICE				= NewID(),
	ID_LOG_TEXTCTRL						= NewID(),
}

local AppData =
{
	lastSourceControlPath				= nil,
	lastLocalPath						= nil,
}

-- ----------------------------------------------------------------------------
-- GUI RELATED FUNCTIONS
-- ----------------------------------------------------------------------------

-- Overwrite the print function so that the messages apear in the log field
function print( ... )
	-- Build the text to log
	local msg = ""
	for _, value in ipairs( { ... } ) do
		msg = msg..tostring( value ).."\t"
	end
	msg = msg.."\n"
	TimGUI.logTextCtrl:AppendText( msg )
end

function error( msg )
	-- Build the text to log
	--[[local msg = ""
	for _, value in ipairs( { ... } ) do
		msg = msg..tostring( value ).."\t"
	end
	msg = msg.."\n"
	]]
	wx.wxLogError( msg )
end

-- wxConfig load/save preferences functions
function TimGUI.ConfigRestoreFramePosition( window, windowName )
    local path = TimGUI.config:GetPath()
    TimGUI.config:SetPath( "/"..windowName )

    local _, s = TimGUI.config:Read( "s", -1 )
    local _, x = TimGUI.config:Read( "x", 0 )
    local _, y = TimGUI.config:Read( "y", 0 )
    local _, w = TimGUI.config:Read( "w", 0 )
    local _, h = TimGUI.config:Read( "h", 0 )

	-- Always restore the position.
	local clientX, clientY, clientWidth, clientHeight
	clientX, clientY, clientWidth, clientHeight = wx.wxClientDisplayRect()

	if x < clientX then x = clientX end
	if y < clientY then y = clientY end

	if w > clientWidth  then w = clientWidth end
	if h > clientHeight then h = clientHeight end

	window:SetSize( x, y, w, h )

	-- Now check to see if it should be minimized or maximized.
    if 1 == s then
        window:Maximize( true )
    elseif 2 == s then
        window:Iconize( true )
    end

    TimGUI.config:SetPath( path )
end

function TimGUI.ConfigSaveFramePosition( window, windowName )
    local path = TimGUI.config:GetPath()
    TimGUI.config:SetPath( "/"..windowName )

    local s    = 0
    local w, h = window:GetSizeWH()
    local x, y = window:GetPositionXY()

    if window:IsMaximized() then
        s = 1
    elseif window:IsIconized() then
        s = 2
    end

    TimGUI.config:Write( "s", s )

    if s == 0 then
        TimGUI.config:Write( "x", x )
        TimGUI.config:Write( "y", y )
        TimGUI.config:Write( "w", w )
        TimGUI.config:Write( "h", h )
    end

    TimGUI.config:SetPath( path )
end

function TimGUI.ConfigRestorePaths()
    local path = TimGUI.config:GetPath()
    TimGUI.config:SetPath( "/Paths" )

    local _, scPath = TimGUI.config:Read( "SourceControlPath", "" )
    local _, localPath = TimGUI.config:Read( "LocalPath", "" )

	-- Set these to AppData.
	AppData.lastSourceControlPath = scPath
	AppData.lastLocalPath = localPath

    TimGUI.config:SetPath( path )
end

function TimGUI.ConfigSavePaths()
    local path = TimGUI.config:GetPath()
    TimGUI.config:SetPath( "/Paths" )

	TimGUI.config:Write( "SourceControlPath", TimGUI.sourceControlLocationTextCtrl:GetValue() )
	TimGUI.config:Write( "LocalPath", TimGUI.projectDestinationDirPicker:GetPath() )

    TimGUI.config:SetPath( path )
end

-- ----------------------------------------------------------------------------
-- EVENT HANDLERS
-- ----------------------------------------------------------------------------

-- Frame close event
function TimGUI.OnClose( event )
	TimGUI.ConfigSavePaths()

	TimGUI.ConfigSaveFramePosition( TimGUI.frame, "MainFrame" )
	TimGUI.config:delete() -- always delete the config
	event:Skip()
end

-- Frame close event
function TimGUI.OnExit( event )
	TimGUI.frame:Close( true )
end

-- About dialog event handler
function TimGUI.OnAbout( event )
	local info = wx.wxAboutDialogInfo()
    info:SetName( APP_NAME )
    info:SetVersion( APP_VERSION )
	info:SetIcon( Resources.GetLargeAppIcon() )
	info:SetWebSite( "http://timprojectenchanter.googlecode.com" )
    info:SetDescription( "Universal project wizard that uses a simple template engine to aid in new project creation." )
    info:SetCopyright( "Copyright (c) RJP Computing 2010" )

    wx.wxAboutBox(info)
end

function TimGUI.OnCreateProjectClicked( event )
	-- Clear the log message
	TimGUI.logTextCtrl:Clear()

	local projName  = TimGUI.projectNameTextCtrl:GetValue()
	local path = TimGUI.projectDestinationDirPicker:GetPath()
	local scPath = TimGUI.sourceControlLocationTextCtrl:GetValue()
	local template = Settings.Templates[TimGUI.projectTypeChoice:GetStringSelection()]

	-- Debugging info
	--[[
	print( 'ProjectName:', projName )
	print( 'Local Path:', path )
	print( 'Source Control Path:', scPath )
	print( 'Template Location:', template )
	]]

	local sc = vcs.VersionControlSystem:new( { projectName = projName, localPath = path, destinationPath = scPath, templatePath = template } )
	-- Create a new project from the template
	--
	print( "-- Export "..template )
	print( sc:Export() )

	print( "-- Make '"..path.."' a working copy" )
	print( sc:MakeWorkingCopy() )

	print( "-- Fill in the template" )
	TemplateReplace( { ProjectName = TimGUI.projectNameTextCtrl:GetValue() }, path .. "/" .. projName )

	print( "-- Add files" )
	print( sc:AddFiles() )

	print( "-- Add the externals" )
	print( sc:SetProperty( "svn:externals" ) )

	print( "-- Commit to "..scPath )
	print( sc:Commit() )

	print( "-- Update "..path.." to complete and get the latest changes" )
	print( sc:Update() )
end

function TimGUI.OnSourceControlOpenClicked( event )
	wx.wxLaunchDefaultBrowser( TimGUI.sourceControlLocationTextCtrl:GetValue() )
end

-- ----------------------------------------------------------------------------
-- APPLICATION ENTRY POINT
--
-- Create a function to encapulate the code, not necessary, but it makes it
-- easier to debug in some cases.
-- ----------------------------------------------------------------------------
local function main()
	TimGUI.config = wx.wxFileConfig( APP_NAME:gsub( " ", "" ), "APP")
	if TimGUI.config then
		TimGUI.config:SetRecordDefaults()
	end
	TimGUI.ConfigRestorePaths()

    -- create the wxFrame window
    TimGUI.frame = wx.wxFrame( wx.NULL,		-- no parent for toplevel windows
						wx.wxID_ANY,				-- don't need a wxWindow ID
                        APP_NAME,					-- caption on the frame
                        wx.wxDefaultPosition,		-- let system place the frame
                        wx.wxDefaultSize,			-- set the size of the frame
                        wx.wxDEFAULT_FRAME_STYLE )	-- use default frame styles

	-- Set the applications icon
    TimGUI.frame:SetIcon( Resources.GetAppIcon() )

    -- create a single child window, wxWidgets will set the size to fill frame
    TimGUI.panel = wx.wxPanel( TimGUI.frame, wx.wxID_ANY )

    -- create a file menu
    local fileMenu = wx.wxMenu()
    --fileMenu:Append( TimGUI.ID_FILE_OPEN, "&Open\tCtrl+O", "Open makefile for viewing only" )
	--fileMenu:AppendSeparator()
    fileMenu:Append( TimGUI.ID_FILE_EXIT, "E&xit\tAlt+F4", "Quit the program" )

    -- create a help menu
    local helpMenu = wx.wxMenu()
    helpMenu:Append( TimGUI.ID_HELP_ABOUT, "&About\tF1", "About the "..APP_NAME.." Application")

    -- create a menu bar and append the file and help menus
    local menuBar = wx.wxMenuBar()
    menuBar:Append( fileMenu, "&File" )
    menuBar:Append( helpMenu, "&Help" )

    -- attach the menu bar into the frame
    TimGUI.frame:SetMenuBar( menuBar )

    -- create a simple status bar
    TimGUI.frame:CreateStatusBar( 1, wx.wxST_SIZEGRIP )
    TimGUI.frame:SetStatusText( "Welcome to "..APP_NAME.."." )

	-- Layout all the buttons using wxSizers
	--
	local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )
	-- Project name
	local projectNameSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )
	projectNameSizer:Add( 18, 0, 0, 0, 5 ) -- Add spacer
	local projectNameStaticText = wx.wxStaticText( TimGUI.panel, wx.wxID_ANY, "Project Name" )
	projectNameSizer:Add( projectNameStaticText, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxTOP + wx.wxBOTTOM + wx.wxLEFT, 5 )
	TimGUI.projectNameTextCtrl = wx.wxTextCtrl( TimGUI.panel, TimGUI.ID_PROJECT_NAME_TEXTCTRL )
	projectNameSizer:Add( TimGUI.projectNameTextCtrl, 1,  wx.wxALL + wx.wxEXPAND, 5 )
	mainSizer:Add( projectNameSizer, 0, wx.wxEXPAND, 5 )
	-- Destinations
	--
	local destinationSbSizer = wx.wxStaticBoxSizer( wx.wxStaticBox( TimGUI.panel, wx.wxID_ANY, "Destinations" ), wx.wxVERTICAL )
	local fgSizer1 = wx.wxFlexGridSizer( 2, 2, 0, 0 )
	fgSizer1:AddGrowableCol( 1 )
	fgSizer1:SetFlexibleDirection( wx.wxBOTH )
	fgSizer1:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
	-- SourceControl
	local sourceControlLocationStaticText = wx.wxStaticText( TimGUI.panel, wx.wxID_ANY, "Source Control" )
	fgSizer1:Add( sourceControlLocationStaticText, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALIGN_RIGHT + wx.wxTOP + wx.wxBOTTOM + wx.wxLEFT, 5 )
	-- Figure out what path to display
	local scLocation = AppData.lastSourceControlPath
	if scLocation:len() == 0 then
		scLocation = Settings.sourceControlProjectRoot or wx.wxEmptyString
	end
	TimGUI.sourceControlLocationTextCtrl = wx.wxTextCtrl( TimGUI.panel, TimGUI.ID_SOURCE_CONTROL_LOCATION_TEXTCTRL, scLocation )
	TimGUI.sourceControlOpenButton = wx.wxButton( TimGUI.panel, TimGUI.ID_SOURCE_CONTROL_OPEN_BUTTON,
		"...", wx.wxDefaultPosition, wx.wxSize( 24, 28 ) )
	local sizer2 = wx.wxBoxSizer( wx.wxHORIZONTAL )
	sizer2:Add( TimGUI.sourceControlLocationTextCtrl, 1, wx.wxALL, 5 )
	sizer2:Add( TimGUI.sourceControlOpenButton, 0, wx.wxTOP + wx.wxBOTTOM + wx.wxRIGHT, 5 )
	fgSizer1:Add( sizer2, 0, wx.wxEXPAND, 5 )
	-- Local Path
	local projectOutputStaticText = wx.wxStaticText( TimGUI.panel, wx.wxID_ANY, "Local Path" )
	fgSizer1:Add( projectOutputStaticText, 0, wx.wxALIGN_CENTER_VERTICAL + wx.wxALIGN_RIGHT + wx.wxTOP + wx.wxBOTTOM + wx.wxLEFT, 5 )
	TimGUI.projectDestinationDirPicker = wx.wxDirPickerCtrl( TimGUI.panel, TimGUI.ID_PROJECT_DESTINATION_DIR_PICKER, "", "Select a folder", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxDIRP_DEFAULT_STYLE )
	-- Set the last path
	TimGUI.projectDestinationDirPicker:SetPath( AppData.lastLocalPath )
	fgSizer1:Add( TimGUI.projectDestinationDirPicker, 0, wx.wxALL + wx.wxEXPAND, 5 )
	destinationSbSizer:Add( fgSizer1, 0, wx.wxEXPAND, 5 )
	mainSizer:Add( destinationSbSizer, 0, wx.wxEXPAND + wx.wxBOTTOM + wx.wxRIGHT + wx.wxLEFT, 5 )
	-- Line
	--local staticLine = wx.wxStaticLine( TimGUI.panel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_HORIZONTAL )
	--mainSizer:Add( staticLine, 0, wx.wxEXPAND + wx.wxALL, 5 )
	-- Project control.
	--
	projectControlSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )
	-- Get the available choices.
	local templates = {}
	for name, _ in pairs( Settings.Templates ) do
		table.insert( templates, name )
	end
	-- Project type
	TimGUI.projectTypeChoice = wx.wxChoice( TimGUI.panel, TimGUI.ID_PROJECT_TYPE_CHOICE, wx.wxDefaultPosition, wx.wxDefaultSize, templates, 0 )
	TimGUI.projectTypeChoice:SetSelection( 0 )
	projectControlSizer:Add( TimGUI.projectTypeChoice, 1, wx.wxALL, 5 )
	-- Create Project
	TimGUI.createProjectButton = wx.wxButton( TimGUI.panel, TimGUI.ID_CREATE_PROJECT_BUTTON, "Create Project" )
	projectControlSizer:Add( TimGUI.createProjectButton, 0, wx.wxALL, 5 )
	mainSizer:Add( projectControlSizer, 0, wx.wxEXPAND, 5 )
	-- Log
	local sbSizer = wx.wxStaticBoxSizer( wx.wxStaticBox( TimGUI.panel, wx.wxID_ANY, "Log" ), wx.wxVERTICAL )
	TimGUI.logTextCtrl = wx.wxTextCtrl( TimGUI.panel, TimGUI.ID_LOG_TEXTCTRL,
		"", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_MULTILINE + wx.wxTE_DONTWRAP )
	sbSizer:Add( TimGUI.logTextCtrl, 1, wx.wxALL + wx.wxEXPAND, 5 )
	mainSizer:Add( sbSizer, 1, wx.wxALL + wx.wxEXPAND, 5 )

	--
	TimGUI.panel:SetSizer( mainSizer )
	mainSizer:SetSizeHints( TimGUI.frame )

	-- Connect to the window event here.
	--
	TimGUI.frame:Connect( wx.wxEVT_CLOSE_WINDOW, TimGUI.OnClose )

	-- Connect menu handlers here.
	--
    -- connect the selection event of the exit menu item
	TimGUI.frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
		TimGUI.OnExit )

    -- connect the selection event of the about menu item
	TimGUI.frame:Connect( wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        TimGUI.OnAbout )

	-- Connect control event handlers here.
	--
	-- Connect the 'Source Cooontrol Open' button event
	TimGUI.frame:Connect( TimGUI.ID_SOURCE_CONTROL_OPEN_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
       TimGUI.OnSourceControlOpenClicked )

	-- Connect the 'Create Project' button event
	TimGUI.frame:Connect( TimGUI.ID_CREATE_PROJECT_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        TimGUI.OnCreateProjectClicked )

	-- Setup default behavior.
	--
	TimGUI.projectNameTextCtrl:SetFocus()
	--TimGUI.executeButton:SetDefault()

	-- Restore the saved settings
	TimGUI.ConfigRestoreFramePosition( TimGUI.frame, "MainFrame" )

	-- show the frame window
    TimGUI.frame:Show( true )

    -- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
	-- otherwise the wxLua program will exit immediately.
	wx.wxGetApp():MainLoop()
end

main()
