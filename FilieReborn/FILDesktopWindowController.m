//
//  FILDesktopWindowController.m
//  FilieReborn
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILDesktopWindowController.h"


@interface FILDesktopWindowController ()

@property (weak) IBOutlet NSImageView *desktopImageView;

@end


@implementation FILDesktopWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.window.level = kCGDesktopIconWindowLevel;
	
	NSScreen * theScreen = NSScreen.screens.firstObject;
	NSRect mainScreenBox = theScreen.frame;
	[self.window setFrame: mainScreenBox display: NO];
	
	NSURL *desktopImageURL = [NSWorkspace.sharedWorkspace desktopImageURLForScreen: theScreen];
	BOOL isDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath: desktopImageURL.path isDirectory: &isDirectory] && isDirectory)
	{
		NSError * err = nil;
		desktopImageURL = [NSFileManager.defaultManager contentsOfDirectoryAtURL:desktopImageURL includingPropertiesForKeys: @[] options: NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles error: &err].firstObject;
	}
//	NSDictionary<NSWorkspaceDesktopImageOptionKey, id> *desktopImageOptions = [NSWorkspace.sharedWorkspace desktopImageOptionsForScreen: theScreen];
	NSImage *desktopImage = [[NSImage alloc] initWithContentsOfURL: desktopImageURL];
	self.desktopImageView.image = desktopImage;
}

- (NSArray<NSURL *> *)files
{
	NSError *err = nil;
	NSArray<NSURL *> *files = [NSFileManager.defaultManager contentsOfDirectoryAtURL: self.folderURL includingPropertiesForKeys: @[] options: NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles error: &err];
	NSArray<NSURL *> *volumes = [NSFileManager.defaultManager mountedVolumeURLsIncludingResourceValuesForKeys: @[] options:NSVolumeEnumerationSkipHiddenVolumes];
	
	return [volumes arrayByAddingObjectsFromArray: files];
}

@end
