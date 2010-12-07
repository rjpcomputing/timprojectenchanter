//Qt
$("#")include <QApplication>
$("#")include <QMessageBox>

$("#")include "$(ProjectName)Frame.h"
$("#")include "$(ProjectName)Version.h"

$(ProjectName)Frame::$(ProjectName)Frame( QWidget* parent ) :
	QMainWindow( parent ),
	$(ProjectName)FrameBase( parent )
{
	setupUi( this );
	
	// Add a simple location for status bar text
	m_statusBarTextWidget = new QLabel( m_statusBar );
	m_statusBar->addWidget( m_statusBarTextWidget );
	
	// Connect events
	connect( actionAbout, SIGNAL( triggered() ), this, SLOT( OnAbout() ) );
}

$(ProjectName)Frame::~$(ProjectName)Frame()
{		
}

void $(ProjectName)Frame::OnAbout()
{
	QMessageBox::about
	(
		this,
		"About $(ProjectName)...",
		QString
		(
			"$(ProjectName)\n\n"
			"$(ProjectName) SVN Revision\t" $(ProjectName:upper())_SVN_REVISION_STRING
		)
	);
}

void $(ProjectName)Frame::SetStatusBarText( const QString& text )
{
	m_statusBarTextWidget->setText( text );
}
