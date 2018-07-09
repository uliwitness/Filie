//
//  FILTitlebarStripesView.m
//  Filie
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILTitlebarStripesView.h"

@implementation FILTitlebarStripesView

- (void)drawRect:(NSRect)dirtyRect
{
	BOOL isActiveWindow = self.window != nil && (NSApplication.sharedApplication.mainWindow == self.window || NSApplication.sharedApplication.keyWindow == self.window);

	if (isActiveWindow)
	{
		NSPoint startPos = { NSMinX(self.bounds) + 2, NSMinY(self.bounds) + 3 };
		NSPoint endPos = { NSMaxX(self.bounds) - 2, NSMinY(self.bounds) + 3 };
		
		while (startPos.y < (NSMaxY(self.bounds) - 3))
		{
			[NSBezierPath strokeLineFromPoint: startPos toPoint: endPos];
			
			startPos.y += 2;
			endPos.y += 2;
		}
	}
}

-(void) viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (self.window)
	{
		[NSNotificationCenter.defaultCenter removeObserver: self name: NSWindowDidBecomeKeyNotification object: self.window];
		[NSNotificationCenter.defaultCenter removeObserver: self name: NSWindowDidResignKeyNotification object: self.window];
		[NSNotificationCenter.defaultCenter removeObserver: self name: NSWindowDidBecomeMainNotification object: self.window];
		[NSNotificationCenter.defaultCenter removeObserver: self name: NSWindowDidResignMainNotification object: self.window];
	}
}


-(void)keyOrMainStatusDidChange: (NSNotification *)notification
{
	[self setNeedsDisplay: YES];
}


-(void) viewDidMoveToWindow
{
	if (self.window)
	{
		[NSNotificationCenter.defaultCenter addObserver: self selector: @selector(keyOrMainStatusDidChange:) name: NSWindowDidBecomeKeyNotification object: self.window];
		[NSNotificationCenter.defaultCenter addObserver: self selector: @selector(keyOrMainStatusDidChange:) name: NSWindowDidResignKeyNotification object: self.window];
		[NSNotificationCenter.defaultCenter addObserver: self selector: @selector(keyOrMainStatusDidChange:) name: NSWindowDidBecomeMainNotification object: self.window];
		[NSNotificationCenter.defaultCenter addObserver: self selector: @selector(keyOrMainStatusDidChange:) name: NSWindowDidResignMainNotification object: self.window];
		[self setNeedsDisplay: YES];
	}
}

@end
