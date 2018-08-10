//
//  FILFileIconView.m
//  FilieReborn
//
//  Created by Uli Kusterer on 08.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILFileIconView.h"
@import QuartzCore;


@interface FILFileIconView ()

@property CALayer *imageLayer;
@property CATextLayer *textLayer;

@end


@implementation FILFileIconView

-(instancetype)	initWithURL: (NSURL *)fileURL
{
	if (self = [super initWithFrame:NSZeroRect])
	{
		self.translatesAutoresizingMaskIntoConstraints = YES;
		NSString *title = [NSFileManager.defaultManager displayNameAtPath: fileURL.path];
		
		BOOL isDirectory = NO;
		BOOL exists = [NSFileManager.defaultManager fileExistsAtPath: fileURL.path isDirectory: &isDirectory];
#pragma unused(exists)
		BOOL isPackage = [NSWorkspace.sharedWorkspace isFilePackageAtPath: fileURL.path];
		NSImage *currImage = nil;
		NSURL * _Nullable associatedAppURL = [NSWorkspace.sharedWorkspace URLForApplicationToOpenURL: fileURL];
		if (associatedAppURL && !isDirectory)
		{
			currImage = [NSWorkspace.sharedWorkspace iconForFile: fileURL.path];
		}
		else
		{
			NSString *imgName = (isDirectory && !isPackage) ? @"GenericFolderIcon" : @"GenericDocumentIcon";
			currImage = [NSImage imageNamed: imgName];
			currImage.size = NSMakeSize(32, 32);
		}
		self.fileURL = fileURL;

		CALayer *backgroundLayer = CALayer.layer;
		backgroundLayer.frame = self.bounds;

		_imageLayer = CALayer.layer;
		_imageLayer.contents = currImage;
		[backgroundLayer addSublayer: _imageLayer];

		NSFont *theFont = [NSFont systemFontOfSize: 12.0];
		
		_textLayer = CATextLayer.layer;
		_textLayer.font = (__bridge CTFontRef) theFont;
		_textLayer.fontSize = 10.0;
		_textLayer.string = title;
		_textLayer.wrapped = NO;
		_textLayer.alignmentMode = kCAAlignmentCenter;
		_textLayer.truncationMode = kCATruncationNone;
		_textLayer.foregroundColor = NSColor.blackColor.CGColor;
		_textLayer.backgroundColor = NSColor.whiteColor.CGColor;
		_textLayer.allowsFontSubpixelQuantization = YES;
		[backgroundLayer addSublayer: _textLayer];

		self.layer = backgroundLayer;
		self.wantsLayer = YES;
	}
	return self;
}


-(void)	sizeToFit
{
	self.frame = (NSRect){ self.frame.origin, { 32, 32 + 20 } };
}


-(void)	layout
{
	[super layout];
	
	NSRect textRect, iconRect;
	NSDivideRect(self.layer.bounds, &iconRect, &textRect, 32, NSMinYEdge);
	
	_imageLayer.frame = iconRect;
	_textLayer.frame = textRect;
}
@end
