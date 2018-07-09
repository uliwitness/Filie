//
//  FILActiveOnlyButtonView.m
//  Filie
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILActiveOnlyButtonView.h"

@implementation FILActiveOnlyButtonView

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
	self.hidden = !self.window.isKeyWindow && !self.window.isMainWindow;
}


-(void) viewDidMoveToWindow
{
	if (self.window)
	{
		[NSNotificationCenter.defaultCenter addObserver: self selector: @selector(keyOrMainStatusDidChange:) name: NSWindowDidBecomeKeyNotification object: self.window];
		[NSNotificationCenter.defaultCenter addObserver: self selector: @selector(keyOrMainStatusDidChange:) name: NSWindowDidResignKeyNotification object: self.window];
		[NSNotificationCenter.defaultCenter addObserver: self selector: @selector(keyOrMainStatusDidChange:) name: NSWindowDidBecomeMainNotification object: self.window];
		[NSNotificationCenter.defaultCenter addObserver: self selector: @selector(keyOrMainStatusDidChange:) name: NSWindowDidResignMainNotification object: self.window];

		self.hidden = !self.window.isKeyWindow && !self.window.isMainWindow;
	}
}

@end
