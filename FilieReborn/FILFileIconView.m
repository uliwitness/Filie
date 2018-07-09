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
		
		NSImage *currImage = nil;
		NSURL * _Nullable associatedAppURL = [NSWorkspace.sharedWorkspace URLForApplicationToOpenURL: fileURL];
		if (associatedAppURL)
		{
			currImage = [NSWorkspace.sharedWorkspace iconForFile: fileURL.path];
		}
		else
		{
			currImage = [NSImage imageNamed: @"GenericDocumentIcon"];
			currImage.size = NSMakeSize(32, 32);
		}
		self.image = currImage;

		self.fileURL = fileURL;
		self.bordered = NO;
	}
	return self;
}

@end
