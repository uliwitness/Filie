//
//  FILFolderWindow.h
//  FilieReborn
//
//  Created by Uli Kusterer on 08.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FILIconLayout : NSObject // This entire object must be safe to use from multiple threads.

+(FILIconLayout *)defaultLayout;
+(FILIconLayout *)desktopLayout;

-(NSPoint)	startPositionInRect: (NSRect)windowRect;
-(NSRect)	placeFrame: (NSRect)newFrame inRect: (NSRect)windowRect updatingPoint: (NSPoint *)currPos;
-(NSPoint)	advancePoint: (NSPoint)currPos afterPlacingRect: (NSRect)newFrame inRect: (NSRect)windowRect;

@end


@interface FILFolderWindowController : NSWindowController <NSWindowDelegate>

@property NSURL *folderURL;
@property FILIconLayout *iconLayout;

-(instancetype)init NS_UNAVAILABLE;
-(instancetype)	initWithURL: (NSURL *)folderURL;

@end
