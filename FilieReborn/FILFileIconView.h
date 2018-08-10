//
//  FILFileIconView.h
//  FilieReborn
//
//  Created by Uli Kusterer on 08.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FILFileIconView : NSButton

@property (nonatomic, strong) NSURL *fileURL;

-(instancetype) initWithFrame:(NSRect)frameRect NS_UNAVAILABLE;
-(instancetype)	initWithURL: (NSURL *)fileURL;

@end
