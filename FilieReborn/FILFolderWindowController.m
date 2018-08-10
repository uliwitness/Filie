//
//  FILFolderWindow.m
//  FilieReborn
//
//  Created by Uli Kusterer on 08.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILFolderWindowController.h"
#import "FILFileIconView.h"
#import "FILAppDelegate.h"
#import "NSString+FILMD5Hash.h"


NSString *FILWindowRectKey = @"FILWindowRect";


@interface NSURL (FILCaseInsensitiveCompare)
-(NSComparisonResult) caseInsensitiveCompare:(NSURL *)otherURL;
@end

@implementation NSURL (FILCaseInsensitiveCompare)
-(NSComparisonResult) caseInsensitiveCompare:(NSURL *)otherURL
{
	return [self.lastPathComponent caseInsensitiveCompare: otherURL.lastPathComponent];
}
@end


@interface FILFolderWindowController ()

@property (weak) IBOutlet NSView *filesView;
@property (weak) IBOutlet NSTextField *numberOfObjectsField;
@property (weak) IBOutlet NSTextField *diskSpaceUsedField;
@property (weak) IBOutlet NSTextField *diskSpaceAvailableField;
@property (weak) IBOutlet NSScrollView *iconsScrollView;
@property (strong) dispatch_queue_t dispatchQueue;

@end

@implementation FILFolderWindowController

-(instancetype)	initWithURL: (NSURL *)folderURL
{
	if (self = [super initWithWindowNibName:[self className]])
	{
		_folderURL = folderURL;
		_dispatchQueue = dispatch_queue_create(folderURL.path.UTF8String, DISPATCH_QUEUE_SERIAL);
		self.shouldCascadeWindows = NO;
	}
	return self;
}

- (NSURL *) folderInfoURL
{
	NSError *err = nil;
	NSURL *folderInfoURL = [self.folderURL URLByAppendingPathComponent: [NSString stringWithFormat:@".Filie_Store_%@", NSUserName()]];
	if (![NSFileManager.defaultManager fileExistsAtPath: folderInfoURL.path])
	{
		[@{} writeToURL:folderInfoURL atomically:YES];
	}
	
	// Couldn't write the file? Probably system directory, create a file in a writable location for this user:
	if (![NSFileManager.defaultManager isWritableFileAtPath: folderInfoURL.path] || ![NSFileManager.defaultManager isReadableFileAtPath: folderInfoURL.path])
	{
		NSURL *desktopDBURL = [NSURL fileURLWithPath:[@"~/Library/Application Support/Filie/Desktop Database/" stringByExpandingTildeInPath]];
		[NSFileManager.defaultManager createDirectoryAtURL:desktopDBURL withIntermediateDirectories:YES attributes:nil error: &err];
		
		NSString *uniqueIdentifier = [self.folderURL.path MD5String];
		NSString *folderName = [self.folderURL.lastPathComponent stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
		
		if ((uniqueIdentifier.length + folderName.length) > 200)
		{
			folderName = [folderName substringToIndex:200 - uniqueIdentifier.length];
		}
		uniqueIdentifier = [folderName stringByAppendingString: uniqueIdentifier];
		uniqueIdentifier = [uniqueIdentifier stringByAppendingString: @".plist"];
		folderInfoURL = [desktopDBURL URLByAppendingPathComponent: uniqueIdentifier];
	}
	return folderInfoURL;
}

- (NSDictionary *) folderInfo
{
	return [NSDictionary dictionaryWithContentsOfURL: self.folderInfoURL] ?: @{};
}

- (NSRect)preferredWindowFrame
{
	NSString *windowBoxStr = [self.folderInfo objectForKey: FILWindowRectKey];
	if (windowBoxStr)
	{
		return NSRectFromString(windowBoxStr);
	}
	
	return NSMakeRect(100, 100, 512, 342); // TODO: Apply a proper stagger relative to parent window.
}

- (NSArray<NSURL *> *)files // *** MAY BE CALLED ON OUR DISPATCH QUEUE'S THREAD!
{
	NSError *err = nil;
	NSArray<NSURL *> *files = [NSFileManager.defaultManager contentsOfDirectoryAtURL: self.folderURL includingPropertiesForKeys: @[] options: NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles error: &err];

	return files;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	NSWindow *wd = self.window;
	
	NSRect box = self.preferredWindowFrame;
	[wd setFrame: box display: NO];
	NSRect localWindowRect = { NSZeroPoint, box.size };
	
	self.iconsScrollView.horizontalScroller.scrollerStyle = NSScrollerStyleLegacy;
	self.iconsScrollView.verticalScroller.scrollerStyle = NSScrollerStyleLegacy;
	
	wd.representedURL = self.folderURL;
	wd.title = [NSFileManager.defaultManager displayNameAtPath: self.folderURL.path];
	
	self.filesView.translatesAutoresizingMaskIntoConstraints = YES;
	
	if (!self.iconLayout)
	{
		self.iconLayout = FILIconLayout.defaultLayout;
	}
	
	dispatch_async(_dispatchQueue, ^{
		NSFileManager *fileManager = [NSFileManager new];
		NSPoint currPos = [self.iconLayout startPositionInRect: localWindowRect];
		NSSize maxSize = NSZeroSize;

		NSArray<NSURL *> *files = [self.files sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

		NSError *err = nil;
//		NSDictionary<NSFileAttributeKey, id> *fileAttrs = [fileManager attributesOfItemAtPath: self.folderURL.path error: &err];
//		NSLog(@"fileAttrs = %@", fileAttrs);
		NSDictionary<NSFileAttributeKey, id> *folderAttrs = [fileManager attributesOfFileSystemForPath: self.folderURL.path error: &err];
		//NSLog(@"folderAttrs = %@", folderAttrs);

		dispatch_sync(dispatch_get_main_queue(), ^{
			self.numberOfObjectsField.stringValue = [NSString stringWithFormat:@"%zu Objects", files.count];
			self.diskSpaceUsedField.stringValue = [NSString stringWithFormat:@"%.2f GB on disk", [folderAttrs[NSFileSystemSize] doubleValue] / 1000000000.0];
			self.diskSpaceAvailableField.stringValue = [NSString stringWithFormat:@"%.2f GB available", [folderAttrs[NSFileSystemFreeSize] doubleValue] / 1000000000.0];
		});
		
		for (NSURL *currFile in files)
		{
			__block NSRect newFrame = {};
			__block FILFileIconView *finderIcon = nil;
			
			dispatch_sync(dispatch_get_main_queue(), ^{
				finderIcon = [[FILFileIconView alloc] initWithURL:currFile];
				[finderIcon sizeToFit];
				newFrame = (NSRect){ currPos, finderIcon.frame.size };
			});
			
			newFrame = [self.iconLayout placeFrame: newFrame inRect: localWindowRect updatingPoint: &currPos];

			if (maxSize.width < NSMaxX(newFrame))
				maxSize.width = NSMaxX(newFrame);
			if (maxSize.height < NSMaxY(newFrame))
				maxSize.height = NSMaxY(newFrame);

			currPos = [self.iconLayout advancePoint: currPos afterPlacingRect: newFrame inRect: box];
			
			dispatch_sync(dispatch_get_main_queue(), ^{
				finderIcon.frame = newFrame;
				finderIcon.action = @selector(testAction:);
				finderIcon.target = self;

				[self.filesView addSubview: finderIcon];
				self.filesView.frame = NSMakeRect(0, 0, maxSize.width + 10, maxSize.height + 10);
			});
		}
	});
}


-(IBAction)testAction:(id)sender
{
	NSURL *theURL = [(FILFileIconView *)sender fileURL];
	[(FILAppDelegate *)NSApplication.sharedApplication.delegate openURL: theURL];
}


#pragma - NSWindow Delegate


-(void)	windowDidMove: (NSNotification *)notification
{
	NSMutableDictionary *infoDictionary = [self.folderInfo mutableCopy];
	[infoDictionary setObject: NSStringFromRect(self.window.frame) forKey: FILWindowRectKey];
	if (![infoDictionary writeToURL: self.folderInfoURL atomically: YES])
	{
		NSLog(@"Couldn't write out info to %@", self.folderInfoURL);
	}
}

-(void)	windowDidResize: (NSNotification *)notification
{
	NSMutableDictionary *infoDictionary = [self.folderInfo mutableCopy];
	[infoDictionary setObject: NSStringFromRect(self.window.frame) forKey: FILWindowRectKey];
	if (![infoDictionary writeToURL: self.folderInfoURL atomically: YES])
	{
		NSLog(@"Couldn't write out info to %@", self.folderInfoURL);
	}
}


-(void)windowWillClose:(NSNotification *)notification
{
	[(FILAppDelegate *)NSApplication.sharedApplication.delegate removeWindowController: self];
}

@end


@interface FILDesktopIconLayout : FILIconLayout // This entire object must be safe to use from multiple threads.
@end


@implementation FILDesktopIconLayout

-(NSPoint)	startPositionInRect: (NSRect)windowRect
{
	NSPoint pos = { NSMaxX(windowRect) - 10, NSMinY(windowRect) + 10 };
	return pos;
}

-(NSRect)	placeFrame: (NSRect)newFrame inRect: (NSRect)windowRect updatingPoint: (NSPoint *)currPos
{
	newFrame.origin.x -= newFrame.size.width;
	
	if (NSMaxY(newFrame) > NSMaxY(windowRect))
	{
		currPos->y = NSMinY(windowRect) + 10;
		newFrame.origin = *currPos;
		newFrame.origin.x -= newFrame.size.width; // TODO: should be width of first item in row, not this one.
		
	}
	
	return newFrame;
}

-(NSPoint)	advancePoint: (NSPoint)currPos afterPlacingRect: (NSRect)newFrame inRect: (NSRect)windowRect
{
	currPos.y = NSMaxY(newFrame) + 10;
	
	return currPos;
}

@end



@implementation FILIconLayout

+(FILIconLayout *)defaultLayout
{
	static FILIconLayout *sDefaultLayout = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sDefaultLayout = [FILIconLayout new];
	});
	
	return sDefaultLayout;
}

+(FILIconLayout *)desktopLayout
{
	static FILIconLayout *sDesktopLayout = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sDesktopLayout = [FILDesktopIconLayout new];
	});
	
	return sDesktopLayout;
}

-(NSPoint) startPositionInRect: (NSRect)windowRect
{
	NSPoint pos = { windowRect.origin.x + 10, windowRect.origin.y + 10 };
	return pos;
}

-(NSRect) placeFrame: (NSRect)newFrame inRect: (NSRect)windowRect updatingPoint: (NSPoint *)currPos
{
	if (NSMaxX(newFrame) > NSMaxX(windowRect))
	{
		newFrame.origin.x = NSMinX(windowRect) + 10;
		newFrame.origin.y += newFrame.size.height + 10;
		*currPos = newFrame.origin;
	}
	
	return newFrame;
}

-(NSPoint) advancePoint: (NSPoint)currPos afterPlacingRect: (NSRect)newFrame inRect: (NSRect)windowRect
{
	currPos.x = NSMaxX(newFrame) + 10;
	
	return currPos;
}


@end
