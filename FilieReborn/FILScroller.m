//
//  FILScroller.m
//  Filie
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILScroller.h"


typedef enum _FILScrollerHitPart
{
	FILScrollerHitPartNone = 0,
	FILScrollerHitPartMinArrow,
	FILScrollerHitPartMaxArrow,
	FILScrollerHitPartKnob,
	FILScrollerHitPartMinPage,
	FILScrollerHitPartMaxPage
} FILScrollerHitPart;


@interface FILScroller ()

@property FILScrollerHitPart trackedPart;
@property NSPoint trackStartPos;
@property double trackingStartValue;

@end


@implementation FILScroller

+(CGFloat)	scrollerWidthForControlSize:(NSControlSize)controlSize scrollerStyle:(NSScrollerStyle)scrollerStyle
{
	return 16;
}


-(void) getMinArrowBox: (NSRect *)minArrowBox maxArrowBox: (NSRect *)maxArrowBox trackBox: (NSRect *)trackBox knobBox: (NSRect *)knobBox
{
	BOOL isHorzNotVert = self.bounds.size.width > self.bounds.size.height;
	*trackBox = self.bounds;
	
	CGFloat doubleValue = self.doubleValue;
	if (doubleValue > 1.0)
		doubleValue = 1.0;
	if (doubleValue < 0.0)
		doubleValue = 0.0;
	
	CGFloat knobProportion = self.knobProportion;
	
	if (isHorzNotVert)
	{
		*minArrowBox = (NSRect){ NSZeroPoint, { self.bounds.size.height, self.bounds.size.height } };
		*maxArrowBox = (NSRect){ { NSMaxX(self.bounds) - self.bounds.size.height, 0 }, { self.bounds.size.height, self.bounds.size.height } };
		
		trackBox->origin.x += minArrowBox->size.width;
		trackBox->size.width -= minArrowBox->size.width + maxArrowBox->size.width;
		
		*knobBox = *trackBox;
		knobBox->size.width *= knobProportion;
		knobBox->origin.x += (trackBox->size.width - knobBox->size.width) * doubleValue;
	}
	else
	{
		*minArrowBox = (NSRect){ NSZeroPoint, { self.bounds.size.width, self.bounds.size.width } };
		*maxArrowBox = (NSRect){ { 0, NSMaxY(self.bounds) - self.bounds.size.width }, { self.bounds.size.width, self.bounds.size.width } };
		
		trackBox->origin.y += minArrowBox->size.height;
		trackBox->size.height -= minArrowBox->size.height + maxArrowBox->size.height;
		
		*knobBox = *trackBox;
		knobBox->size.height *= knobProportion;
		knobBox->origin.y += (trackBox->size.height - knobBox->size.height) * doubleValue;
	}
}


-(void) drawRect: (NSRect)dirtyRect
{
	[NSColor.whiteColor setFill];
	[NSBezierPath fillRect: self.bounds];
	
	[NSColor.blackColor setStroke];
	[NSBezierPath strokeRect: self.bounds];
	
	NSRect minArrowBox;
	NSRect maxArrowBox;
	NSRect trackBox;
	NSRect knobBox;
	
	[self getMinArrowBox: &minArrowBox maxArrowBox: &maxArrowBox trackBox: &trackBox knobBox: &knobBox];

	if (self.trackedPart == FILScrollerHitPartMinArrow)
	{
		[NSColor.blackColor setFill];
		[NSBezierPath fillRect: minArrowBox];
	}
	[NSBezierPath strokeRect: minArrowBox];

	if (self.trackedPart == FILScrollerHitPartMaxArrow)
	{
		[NSColor.blackColor setFill];
		[NSBezierPath fillRect: maxArrowBox];
	}
	[NSBezierPath strokeRect: maxArrowBox];
	
	if (self.knobProportion > 0.0 && self.knobProportion < 1.0)
	{
		[NSColor.lightGrayColor setFill];
		[NSBezierPath fillRect: trackBox];

		[NSColor.whiteColor setFill];
		[NSBezierPath fillRect: knobBox];
		[NSBezierPath strokeRect: knobBox];
	}
}


-(void) mouseDown:(NSEvent *)event
{
	self.trackStartPos = [self convertPoint: event.locationInWindow fromView: nil];
	self.trackingStartValue = self.doubleValue;
	
	NSRect minArrowBox;
	NSRect maxArrowBox;
	NSRect trackBox;
	NSRect knobBox;
	
	[self getMinArrowBox: &minArrowBox maxArrowBox: &maxArrowBox trackBox: &trackBox knobBox: &knobBox];
	
	if (NSPointInRect(self.trackStartPos, minArrowBox))
		self.trackedPart = FILScrollerHitPartMinArrow;
	else if (NSPointInRect(self.trackStartPos, maxArrowBox))
		self.trackedPart = FILScrollerHitPartMaxArrow;
	else if (NSPointInRect(self.trackStartPos, knobBox))
		self.trackedPart = FILScrollerHitPartKnob;
	else if (NSPointInRect(self.trackStartPos, trackBox))
	{
		if (self.trackStartPos.x < NSMinX(knobBox) || self.trackStartPos.y < NSMinY(knobBox))
			self.trackedPart = FILScrollerHitPartMinPage;
		else
			self.trackedPart = FILScrollerHitPartMaxPage;
	}
	else
		self.trackedPart = FILScrollerHitPartNone;
	
	[self setNeedsDisplay: YES];
}


-(void) mouseDragged:(NSEvent *)event
{
	NSPoint trackEndPos = [self convertPoint: event.locationInWindow fromView: nil];

	if (self.trackedPart == FILScrollerHitPartKnob)
	{
		NSRect minArrowBox;
		NSRect maxArrowBox;
		NSRect trackBox;
		NSRect knobBox;
		
		[self getMinArrowBox: &minArrowBox maxArrowBox: &maxArrowBox trackBox: &trackBox knobBox: &knobBox];

		BOOL isHorzNotVert = self.bounds.size.width > self.bounds.size.height;
		CGFloat possibleDistance = isHorzNotVert ? (trackBox.size.width - knobBox.size.width) : (trackBox.size.height - knobBox.size.height);

		NSSize diff = { trackEndPos.x - _trackStartPos.x, trackEndPos.y - _trackStartPos.y };
		CGFloat traveledValue = isHorzNotVert ? (diff.width / possibleDistance) : (diff.height / possibleDistance);
		
		CGFloat newValue = self.trackingStartValue + traveledValue;
		if (newValue > 1.0)
			newValue = 1.0;
		else if (newValue < 0)
			newValue = 0;
		
		self.doubleValue = newValue;
		
		[self sendAction:self.action to:self.target];
		
		[self setNeedsDisplay: YES];
	}
}


-(void) mouseUp:(NSEvent *)event
{
	self.trackedPart = FILScrollerHitPartNone;
	[self setNeedsDisplay: YES];
}


+(BOOL) compatibleWithOverlayScrollers
{
	return NO;
}

@end
