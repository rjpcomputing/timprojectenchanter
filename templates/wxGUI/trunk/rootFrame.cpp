// wxWidgets
$(#)include <wx/aboutdlg.h>

$(#)include "$(ProjectName)Frame.h"

$(ProjectName)Frame::$(ProjectName)Frame( wxWindow* parent )
:
$(ProjectName)FrameBase( parent )
{

}

void $(ProjectName)Frame::OnExit( wxCommandEvent& /*event*/ )
{
	Close();
}

void $(ProjectName)Frame::OnAbout( wxCommandEvent& /*event*/ )
{
	wxAboutDialogInfo info;
    info.SetName( wxT("$(ProjectName)") );
    info.SetVersion( wxT("0.01") );
	info.SetIcon( this->GetIcon() );
	//info.SetWebSite( wxT("http://some.website.com") );
    //info.SetDescription( wxT("Short program description.") );
    //info.SetCopyright( wxT("Copyright (c) Company 2009") );

    wxAboutBox( info );
}
