///////////////////////////////////////////////////////////////////////////
// C++ code generated with wxFormBuilder (version Mar  6 2009)
// http://www.wxformbuilder.org/
//
// PLEASE DO "NOT" EDIT THIS FILE!
///////////////////////////////////////////////////////////////////////////

$("#")ifndef __$(ProjectName)_GUI__
$("#")define __$(ProjectName)_GUI__

$("#")include <wx/string.h>
$("#")include <wx/bitmap.h>
$("#")include <wx/image.h>
$("#")include <wx/icon.h>
$("#")include <wx/menu.h>
$("#")include <wx/gdicmn.h>
$("#")include <wx/font.h>
$("#")include <wx/colour.h>
$("#")include <wx/settings.h>
$("#")include <wx/sizer.h>
$("#")include <wx/panel.h>
$("#")include <wx/frame.h>

///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
/// Class $(ProjectName)FrameBase
///////////////////////////////////////////////////////////////////////////////
class $(ProjectName)FrameBase : public wxFrame 
{
	private:
	
	protected:
		wxMenuBar* m_mainMenubar;
		wxMenu* m_fileMenu;
		wxMenu* m_helpMenu;
		wxPanel* m_mainPanelBase;
		
		// Virtual event handlers, overide them in your derived class
		virtual void OnExit( wxCommandEvent& event ) { event.Skip(); }
		virtual void OnAbout( wxCommandEvent& event ) { event.Skip(); }
		
	
	public:
		
		$(ProjectName)FrameBase( wxWindow* parent, wxWindowID id = wxID_ANY, const wxString& title = wxT("$(ProjectName)"), const wxPoint& pos = wxDefaultPosition, const wxSize& size = wxSize( 500,300 ), long style = wxDEFAULT_FRAME_STYLE|wxTAB_TRAVERSAL );
		~$(ProjectName)FrameBase();
	
};

$("#")endif //__$(ProjectName)_GUI__
