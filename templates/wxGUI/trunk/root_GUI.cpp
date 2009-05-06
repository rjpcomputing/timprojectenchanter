///////////////////////////////////////////////////////////////////////////
// C++ code generated with wxFormBuilder (version Mar  6 2009)
// http://www.wxformbuilder.org/
//
// PLEASE DO "NOT" EDIT THIS FILE!
///////////////////////////////////////////////////////////////////////////

$(#)include "$(ProjectName)_GUI.h"

///////////////////////////////////////////////////////////////////////////

$(ProjectName)FrameBase::$(ProjectName)FrameBase( wxWindow* parent, wxWindowID id, const wxString& title, const wxPoint& pos, const wxSize& size, long style ) : wxFrame( parent, id, title, pos, size, style )
{
	this->SetSizeHints( wxDefaultSize, wxDefaultSize );
	
	m_mainMenubar = new wxMenuBar( 0 );
	m_fileMenu = new wxMenu();
	wxMenuItem* m_fileExitMenuItem;
	m_fileExitMenuItem = new wxMenuItem( m_fileMenu, wxID_ANY, wxString( wxT("E&xit") ) + wxT('\t') + wxT("Alt+F4"), wxT("Exit the application"), wxITEM_NORMAL );
	m_fileMenu->Append( m_fileExitMenuItem );
	
	m_mainMenubar->Append( m_fileMenu, wxT("&File") );
	
	m_helpMenu = new wxMenu();
	wxMenuItem* m_helpAboutMenuItem;
	m_helpAboutMenuItem = new wxMenuItem( m_helpMenu, wxID_ANY, wxString( wxT("&About") ) + wxT('\t') + wxT("F1"), wxT("Display the about dialog"), wxITEM_NORMAL );
	m_helpMenu->Append( m_helpAboutMenuItem );
	
	m_mainMenubar->Append( m_helpMenu, wxT("&Help") );
	
	this->SetMenuBar( m_mainMenubar );
	
	wxBoxSizer* initialFrameSizer;
	initialFrameSizer = new wxBoxSizer( wxVERTICAL );
	
	m_mainPanelBase = new wxPanel( this, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL );
	wxBoxSizer* mainSizer;
	mainSizer = new wxBoxSizer( wxVERTICAL );
	
	m_mainPanelBase->SetSizer( mainSizer );
	m_mainPanelBase->Layout();
	mainSizer->Fit( m_mainPanelBase );
	initialFrameSizer->Add( m_mainPanelBase, 1, wxEXPAND, 5 );
	
	this->SetSizer( initialFrameSizer );
	this->Layout();
	
	// Connect Events
	this->Connect( m_fileExitMenuItem->GetId(), wxEVT_COMMAND_MENU_SELECTED, wxCommandEventHandler( $(ProjectName)FrameBase::OnExit ) );
	this->Connect( m_helpAboutMenuItem->GetId(), wxEVT_COMMAND_MENU_SELECTED, wxCommandEventHandler( $(ProjectName)FrameBase::OnAbout ) );
}

$(ProjectName)FrameBase::~$(ProjectName)FrameBase()
{
	// Disconnect Events
	this->Disconnect( wxID_ANY, wxEVT_COMMAND_MENU_SELECTED, wxCommandEventHandler( $(ProjectName)FrameBase::OnExit ) );
	this->Disconnect( wxID_ANY, wxEVT_COMMAND_MENU_SELECTED, wxCommandEventHandler( $(ProjectName)FrameBase::OnAbout ) );
}
