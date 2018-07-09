//
//  FILFolderWindow.h
//  FilieReborn
//
//  Created by Uli Kusterer on 08.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FILFolderWindowController : NSWindowController <NSWindowDelegate>

@property NSURL *folderURL;

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)	initWithURL: (NSURL *)folderURL;

@end
