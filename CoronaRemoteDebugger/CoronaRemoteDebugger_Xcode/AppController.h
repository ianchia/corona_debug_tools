#import <Cocoa/Cocoa.h>

@class AsyncSocket;

@interface AppController : NSObject
{
	AsyncSocket *listenSocket;
	AsyncSocket *pushSocket;
	NSMutableArray *connectedSockets;
	
	BOOL isRunning;
	
   IBOutlet id logView;
   IBOutlet id portField;
   IBOutlet id startStopButton;
   IBOutlet id commandTextfield;
}
- (IBAction)startStop:(id)sender;
- (IBAction)commandTextfield:(id)sender;

@end
