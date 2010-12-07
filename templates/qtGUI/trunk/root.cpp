$("#")include <QApplication>
$("#")include <QDesktopServices>

$("#")include "$(ProjectName)Frame.h"

int main( int argc, char* argv[] )
{	
	QApplication app( argc, argv );
	app.setApplicationName( "$(ProjectName)" );
	app.setOrganizationName( "My Company" );

    $(ProjectName)Frame $(ProjectName:lower())Frame;
    $(ProjectName:lower())Frame.show();
	
    int retVal = app.exec();
    
	return retVal;
}
