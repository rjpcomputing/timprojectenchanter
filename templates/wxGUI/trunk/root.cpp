// wxWidgets
$(#)include <wx/image.h>
$(#)include <wx/sysopt.h>
$(#)include <wx/xrc/xmlres.h>

$(#)include "$(ProjectName).h"
$(#)include "$(ProjectName)Frame.h"
$(#)include "res/$(ProjectName)16x16.xpm"
$(#)include "res/$(ProjectName)32x32.xpm"

IMPLEMENT_APP( $(ProjectName)App )

$(ProjectName)App::$(ProjectName)App()
{
}

$(ProjectName)App::~$(ProjectName)App()
{
}

bool $(ProjectName)App::OnInit()
{
	// Call default behaviour
    if ( !wxApp::OnInit() )
	{
		return false;
	}
	
	// Init resources and add the PNG handler
	wxSystemOptions::SetOption( _T( "msw.remap" ), 0 );
	wxXmlResource::Get()->InitAllHandlers();
	wxImage::AddHandler( new wxPNGHandler );
	wxImage::AddHandler( new wxCURHandler );
	wxImage::AddHandler( new wxICOHandler );
	wxImage::AddHandler( new wxXPMHandler );
	wxImage::AddHandler( new wxGIFHandler );

	$(ProjectName)Frame* frame = new $(ProjectName)Frame( NULL );

	// Setup icons
	wxIconBundle bundle;
	wxIcon ico16( $(ProjectName)16x16_xpm );
	bundle.AddIcon( ico16 );

	wxIcon ico32( $(ProjectName)32x32_xpm );
	bundle.AddIcon( ico32 );

	frame->SetIcons( bundle );
	frame->Show( true );
	SetTopWindow( frame );

	return true;
}

int $(ProjectName)App::OnExit()
{
	return wxApp::OnExit();
}
