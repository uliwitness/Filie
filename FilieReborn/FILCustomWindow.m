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

@end
