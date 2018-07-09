//
//  AppDelegate.h
//  FilieReborn
//
//  Created by Uli Kusterer on 08.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class FILFolderWindowController;


@interface FILAppDelegate : NSObject <NSApplicationDelegate>

-(void) openURL: (NSURL *)fileURL;
-(void)	removeWindowController: (FILFolderWindowController *)windowController;

@end

