#import "AppController.h"
#import "AsyncSocket.h"

#define WELCOME_MSG  0
#define ECHO_MSG     1

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface AppController (PrivateAPI)
- (void)logError:(NSString *)msg;
- (void)logInfo:(NSString *)msg;
- (void)logMessage:(NSString *)msg;
- (void)sendMessage;
@end


@implementation AppController

- (id)init
{
	if(self = [super init])
	{
		listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
		pushSocket = [[AsyncSocket alloc] initWithDelegate:self];
		connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
		
		isRunning = NO;
	}
	return self;
}

- (void)awakeFromNib
{
	[logView setString:@""];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSLog(@"Ready");
	
	// Advanced options - enable the socket to contine operations even during modal dialogs, and menu browsing
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

- (void)scrollToBottom
{
	NSScrollView *scrollView = [logView enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0, 0.0);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];
}

- (void)logError:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logInfo:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

- (void)logMessage:(NSString *)msg
{
	NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
	[as autorelease];
	
	[[logView textStorage] appendAttributedString:as];
	[self scrollToBottom];
}

//____________________________________________________________________________________________________________
// @IC MOD starts ////////////////////////////////////////////////////////////////////////////////////////////


// broadcast the string from the text field to all connected socket clients
- (IBAction)commandTextfield:(id)sender
{
   // NSLog(@"command is %@",[commandTextfield stringValue]);
   
   // if the server is running, push the byte array out
   if(isRunning)
	{  
      NSString *broadcastString = [[commandTextfield stringValue] stringByAppendingString:@"\0"];
      NSData *terminatedByteString = [broadcastString dataUsingEncoding:NSUTF8StringEncoding];
      
      int i;
		for(i = 0; i < [connectedSockets count]; i++)
		{
         // iterate through all connected clients
			[[connectedSockets objectAtIndex:i] writeData:terminatedByteString withTimeout:-1 tag:ECHO_MSG];
		}
      
      //NSLog(@"command has been send to asyncsocket writeData");
   }

}

// @IC MOD ends //////////////////////////////////////////////////////////////////////////////////////////////
//____________________________________________________________________________________________________________


- (IBAction)startStop:(id)sender
{
	if(!isRunning)
	{
		int port = [portField intValue];
		
      if (port == nil) port = 8080;
      
		if(port < 0 || port > 65535)
		{
			port = 0;
		}
		
		NSError *error = nil;
		if(![listenSocket acceptOnPort:port error:&error])
		{
			[self logError:FORMAT(@"Error starting server: %@", error)];
			return;
		}
		
		[self logInfo:FORMAT(@"Corona Remote Debugger started on port %hu", [listenSocket localPort])];
		isRunning = YES;
		
		[portField setEnabled:NO];
		[startStopButton setTitle:@"Stop"];
	}
	else
	{
		// Stop accepting connections
		[listenSocket disconnect];
			
		// Stop any client connections
		int i;
		for(i = 0; i < [connectedSockets count]; i++)
		{
			// Call disconnect on the socket,
			// which will invoke the onSocketDidDisconnect: method,
			// which will remove the socket from the list.
			[[connectedSockets objectAtIndex:i] disconnect];
		}
		
		[self logInfo:@"Stopped Corona Remote Debugger"];
		isRunning = false;
		
		[portField setEnabled:YES];
		[startStopButton setTitle:@"Start"];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
/*
 DELEGATE METHODS defined by asyncsocket
*/

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	[connectedSockets addObject:newSocket];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	[self logInfo:FORMAT(@"Accepted client %@:%hu", host, port)];
	
	//NSString *welcomeMsg = @"Welcome to the AsyncSocket Echo Server\r\n";
   NSString *welcomeMsg = @"Welcome to the Corona Remote Debugger\r\n\0"; // add NULL terminator
	NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	[sock writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
	
	// We could call readDataToData:withTimeout:tag: here - that would be perfectly fine.
	// If we did this, we'd want to add a check in onSocket:didWriteDataWithTag: and only
	// queue another read if tag != WELCOME_MSG.
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
   NSLog(@"delegate onSocket:didWriteDataWithTag called.");
   // a message is terminated with a Zero byte
	[sock readDataToData:[AsyncSocket ZeroData] withTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
   // strip the number of bytes defined by strip_length - normally just 1 (ie. the NULL terminator)
   int strip_length = 1;
   
   // @IC - will Corona need the null terminator to receive a msg?
   // check how the Corona socket client is written
   
	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - strip_length)];
	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	if(msg)
	{
		[self logMessage:msg];
	}
	else
	{
		[self logError:@"Error converting received data into UTF-8 String"];
	}
	
	// Even if we were unable to write the incoming data to the log,
	// we're still going to echo it back to the client.
   //NSLog(@"Still within delegate for onSocket:didReadData. About to writeData:withTimeout:tag to echo msg");
   [sock writeData:data withTimeout:-1 tag:ECHO_MSG]; // original line
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	[self logInfo:FORMAT(@"Client Disconnected: %@:%hu", [sock connectedHost], [sock connectedPort])];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	[connectedSockets removeObject:sock];
}

@end
