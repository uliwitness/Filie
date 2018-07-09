//
//  AppDelegate.m
//  FilieReborn
//
//  Created by Uli Kusterer on 08.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILAppDelegate.h"
#import "FILFolderWindowController.h"
#import "FILDesktopWindowController.h"

@interface FILAppDelegate ()

@property (strong) NSMutableArray<FILFolderWindowController *> *allWindowControllers;

@end

@implementation FILAppDelegate

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
	self.allWindowControllers = [NSMutableArray new];
	
	FILFolderWindowController *wc = [[FILDesktopWindowController alloc] initWithURL: [NSURL fileURLWithPath:[@"~/Desktop" stringByExpandingTildeInPath]]];
	[self.allWindowControllers addObject:wc];
	[wc showWindow: self];
}


- (void)applicationWillTerminate: (NSNotification *)aNotification
{
	// Insert code here to tear down your application
}

-(void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls
{
	for (NSURL *currURL in urls)
	{
		[self openURL: currURL];
	}
}


-(void) openURL: (NSURL *)fileURL
{
	BOOL isFolder = NO;
	[NSFileManager.defaultManager fileExistsAtPath: fileURL.path isDirectory:&isFolder];
	
	BOOL isPackage = [NSWorkspace.sharedWorkspace isFilePackageAtPath: fileURL.path];
	
	if (!isFolder || isPackage)
	{
		[NSWorkspace.sharedWorkspace openURL: fileURL];
		return;
	}
	
	FILFolderWindowController *wc = [self windowControllerForURL: fileURL];
	if (!wc)
	{
		wc = [[FILFolderWindowController alloc] initWithURL: fileURL];
		[self.allWindowControllers addObject:wc];
		[wc showWindow: self];
	}
	else
	{
		[wc.window makeKeyAndOrderFront: self];
	}
}


-(void)	removeWindowController: (FILFolderWindowController *)windowController
{
	[self.allWindowControllers performSelector: @selector(removeObject:) withObject: windowController afterDelay: 0.0];
}


-(IBAction)	goHome: (nullable id)sender
{
	NSURL *homeURL = [NSURL fileURLWithPath:[@"~/" stringByExpandingTildeInPath]];
	[self openURL: homeURL];
}


-(IBAction)	goApplications: (nullable id)sender
{
	[self openURL: [NSURL fileURLWithPath:@"/Applications"]];
}


- (nullable FILFolderWindowController *)windowControllerForURL:(NSURL *)folderURL
{
	FILFolderWindowController *wc = nil;
	
	for (FILFolderWindowController *existingWindowController in self.allWindowControllers)
	{
		NSString *inPathString1 = existingWindowController.folderURL.path;
		NSString *inPathString2 = folderURL.path;
		
		if ([inPathString1 rangeOfString: @"/"].location == NSNotFound) {
			[@"./" stringByAppendingString: inPathString1];
		}
		if ([inPathString2 rangeOfString: @"/"].location == NSNotFound) {
			[@"./" stringByAppendingString: inPathString2];
		}
		
		char	*	realPath1 = realpath( inPathString1.fileSystemRepresentation, NULL );
		char	*	realPath2 = realpath( inPathString2.fileSystemRepresentation, NULL );
		
		bool identical = strcmp( realPath1, realPath2 ) == 0;
		
		free(realPath1);
		free(realPath2);
		
		if (identical)
		{
			wc = existingWindowController;
			break;
		}
	}
	
	return wc;
}

@end
