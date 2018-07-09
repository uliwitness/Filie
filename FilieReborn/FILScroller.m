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
{
	NSScrollerPart myHitPart;
}

@property FILScrollerHitPart trackedPart;
@property NSPoint trackStartPos;
@property double trackingStartValue;

@end


@implementation FILScroller

+(CGFloat)	scrollerWidthForControlSize:(NSControlSize)controlSize scrollerStyle:(NSScrollerStyle)scrollerStyle
{
	return 16;
}


+(BOOL) compatibleWithOverlayScrollers
{
	return NO;
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
		
		trackBox->origin.x += minArrowBox->size.width - 1;
		trackBox->size.width -= minArrowBox->size.width - 1 + maxArrowBox->size.width - 1;
		
		*knobBox = *trackBox;
		knobBox->size.width *= knobProportion;
		if (knobBox->size.width < minArrowBox->size.width)
			knobBox->size.width = minArrowBox->size.width;
		knobBox->origin.x += (trackBox->size.width - knobBox->size.width) * doubleValue;
	}
	else
	{
		*minArrowBox = (NSRect){ NSZeroPoint, { self.bounds.size.width, self.bounds.size.width } };
		*maxArrowBox = (NSRect){ { 0, NSMaxY(self.bounds) - self.bounds.size.width }, { self.bounds.size.width, self.bounds.size.width } };
		
		trackBox->origin.y += minArrowBox->size.height - 1;
		trackBox->size.height -= minArrowBox->size.height - 1 + maxArrowBox->size.height - 1;
		
		*knobBox = *trackBox;
		knobBox->size.height *= knobProportion;
		if (knobBox->size.height < minArrowBox->size.height)
			knobBox->size.height = minArrowBox->size.height;
		knobBox->origin.y += (trackBox->size.height - knobBox->size.height) * doubleValue;
	}
}


-(NSRect) rectForStroking:(NSRect)rectForFilling
{
	NSRect rectForStroking = rectForFilling;
	rectForStroking.origin.x += 0.5;
	rectForStroking.origin.y += 0.5;
	rectForStroking.size.width -= 1.0;
	rectForStroking.size.height -= 1.0;
	return rectForStroking;
}


-(void) drawRect: (NSRect)dirtyRect
{
	BOOL isActiveWindow = self.window != nil && (NSApplication.sharedApplication.mainWindow == self.window || NSApplication.sharedApplication.keyWindow == self.window);
	BOOL isNecessary = self.knobProportion > 0.0 && self.knobProportion < 1.0;
	if (isNecessary)
		isNecessary = self.isEnabled;
	
	NSRect minArrowBox;
	NSRect maxArrowBox;
	NSRect trackBox;
	NSRect knobBox;
	
	[self getMinArrowBox: &minArrowBox maxArrowBox: &maxArrowBox trackBox: &trackBox knobBox: &knobBox];

	[NSColor.whiteColor setFill];
	[NSBezierPath fillRect: self.bounds];
	
	if (isNecessary && isActiveWindow)
	{
		[NSColor.lightGrayColor setFill];
		[NSBezierPath fillRect: trackBox];
	}

	[NSColor.blackColor setStroke];
	[NSBezierPath strokeRect: [self rectForStroking: self.bounds]];
	
	if (isActiveWindow)
	{
		if (self.trackedPart == FILScrollerHitPartMinArrow)
		{
			[NSColor.blackColor setFill];
			[NSBezierPath fillRect: minArrowBox];
		}
		[NSBezierPath strokeRect: [self rectForStroking: minArrowBox]];
		
		if (self.trackedPart == FILScrollerHitPartMaxArrow)
		{
			[NSColor.blackColor setFill];
			[NSBezierPath fillRect: maxArrowBox];
		}
		[NSBezierPath strokeRect: [self rectForStroking: maxArrowBox]];
		
		if (isNecessary)
		{
			[NSColor.whiteColor setFill];
			[NSBezierPath fillRect: knobBox];
			[NSBezierPath strokeRect: [self rectForStroking: knobBox]];
		}
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
	{
		self.trackedPart = FILScrollerHitPartMinArrow;
		myHitPart = NSScrollerDecrementLine;
		[self sendAction:self.action to:self.target];
	}
	else if (NSPointInRect(self.trackStartPos, maxArrowBox))
	{
		self.trackedPart = FILScrollerHitPartMaxArrow;
		myHitPart = NSScrollerIncrementLine;
		[self sendAction:self.action to:self.target];
	}
	else if (NSPointInRect(self.trackStartPos, knobBox))
		self.trackedPart = FILScrollerHitPartKnob;
	else if (NSPointInRect(self.trackStartPos, trackBox))
	{
		if (self.trackStartPos.x < NSMinX(knobBox) || self.trackStartPos.y < NSMinY(knobBox))
		{
			myHitPart = NSScrollerDecrementPage;
			self.trackedPart = FILScrollerHitPartMinPage;
		}
		else
		{
			myHitPart = NSScrollerIncrementPage;
			self.trackedPart = FILScrollerHitPartMaxPage;
		}
		[self sendAction:self.action to:self.target];
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
		myHitPart = NSScrollerKnob;
		[self sendAction:self.action to:self.target];
		
		[self setNeedsDisplay: YES];
	}
}


-(void)setHitPart: (NSScrollerPart)inPart
{
	myHitPart = inPart;
	
	[self setNeedsDisplay: YES];
}

-(NSScrollerPart)hitPart
{
	return myHitPart;
}


-(void) mouseUp:(NSEvent *)event
{
	self.trackedPart = FILScrollerHitPartNone;
	[self setNeedsDisplay: YES];
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
