//
//  FILScrollView.m
//  Filie
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILScrollView.h"

@implementation FILScrollView

-(void)	tile
{
	NSRect box = self.bounds;
	NSRect hScrollerBox = box;
	NSRect vScrollerBox = box;
	
	NSDivideRect(self.bounds, &hScrollerBox, &box, 16, NSMaxYEdge);
	hScrollerBox.size.width -= 16 - 1;
	NSDivideRect(self.bounds, &vScrollerBox, &box, 16, NSMaxXEdge);
	vScrollerBox.size.height -= 16 - 1;

	box.size.width = hScrollerBox.size.width;
	box.size.height = vScrollerBox.size.height;
	
	[self.contentView setFrame: box];
	[self.horizontalScroller setFrame: hScrollerBox];
	[self.verticalScroller setFrame: vScrollerBox];
}

@end
