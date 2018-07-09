//
//  FILTextField.m
//  Filie
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILTextField.h"

@implementation FILTextField

- (void)drawRect:(NSRect)dirtyRect
{
	BOOL antiAlias = NSGraphicsContext.currentContext.shouldAntialias;
	NSGraphicsContext.currentContext.shouldAntialias = NO;
	
    [super drawRect:dirtyRect];
    
	NSGraphicsContext.currentContext.shouldAntialias = antiAlias;
}

@end
