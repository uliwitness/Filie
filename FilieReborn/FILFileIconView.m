//
//  FILFileIconView.m
//  FilieReborn
//
//  Created by Uli Kusterer on 08.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILFileIconView.h"


@implementation FILFileIconView

-(instancetype)	initWithURL: (NSURL *)fileURL
{
	if (self = [super initWithFrame:NSZeroRect])
	{
		self.buttonType = NSButtonTypeMomentaryPushIn;
		self.bezelStyle = NSRegularSquareBezelStyle;
		self.imagePosition = NSImageAbove;
		self.translatesAutoresizingMaskIntoConstraints = YES;
		self.title = [NSFileManager.defaultManager displayNameAtPath: fileURL.path];
		self.image = [NSWorkspace.sharedWorkspace iconForFile: fileURL.path];
		self.fileURL = fileURL;
		self.bordered = NO;
	}
	return self;
}

@end
