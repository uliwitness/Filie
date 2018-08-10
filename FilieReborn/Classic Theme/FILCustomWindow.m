//
//  FILCustomWindow.m
//  Filie
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILCustomWindow.h"

@implementation FILCustomWindow

-(BOOL) canBecomeKeyWindow
{
	return YES;
}


-(BOOL) canBecomeMainWindow
{
	return YES;
}


-(void) performClose: (id)sender
{
	[self close];
}


-(void) performZoom: (id)sender
{
	[self zoom: self];
}


-(BOOL)	validateMenuItem: (NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(performClose:))
	{
		return YES;
	}
	else if (menuItem.action == @selector(performZoom:))
	{
		return YES;
	}
	else
	{
		return [super validateMenuItem: menuItem];
	}
}


-(NSWindowStyleMask)styleMask
{
	return super.styleMask | NSWindowStyleMaskTitled | NSWindowStyleMaskResizable; // So we show up in the window menu.
}

@end
