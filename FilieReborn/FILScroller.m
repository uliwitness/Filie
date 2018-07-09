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
@property double trackingCurrentValue;
@property NSTimer *trackingRepeatTimer;

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


-(instancetype)initWithFrame:(NSRect)frameRect
{
	if (self = [super initWithFrame:frameRect])
	{
		_trackingCurrentValue = -1.0;
	}
	return self;
}


-(instancetype)initWithCoder:(NSCoder *)coder
{
	if (self = [super initWithCoder:coder])
	{
		_trackingCurrentValue = -1.0;
	}
	return self;
}


-(void) getMinArrowBox: (NSRect *)minArrowBox maxArrowBox: (NSRect *)maxArrowBox trackBox: (NSRect *)trackBox knobBox: (NSRect *)knobBox trackingKnobBox: (NSRect *)trackingKnobBox
{
	BOOL isHorzNotVert = self.bounds.size.width > self.bounds.size.height;
	*trackBox = self.bounds;
	
	CGFloat doubleValue = self.doubleValue;
	if (doubleValue > 1.0)
		doubleValue = 1.0;
	if (doubleValue < 0.0)
		doubleValue = 0.0;

	CGFloat trackingCurrentValue = self.trackingCurrentValue;
	if (trackingCurrentValue > 1.0)
		trackingCurrentValue = 1.0;
	if (trackingCurrentValue < 0.0)
		trackingCurrentValue = 0.0;

	//CGFloat knobProportion = self.knobProportion;
	
	if (isHorzNotVert)
	{
		*minArrowBox = (NSRect){ NSZeroPoint, { self.bounds.size.height, self.bounds.size.height } };
		*maxArrowBox = (NSRect){ { NSMaxX(self.bounds) - self.bounds.size.height, 0 }, { self.bounds.size.height, self.bounds.size.height } };
		
		trackBox->origin.x += minArrowBox->size.width - 1;
		trackBox->size.width -= minArrowBox->size.width - 1 + maxArrowBox->size.width - 1;
		
		*knobBox = *trackBox;
		//knobBox->size.width *= knobProportion;
		//if (knobBox->size.width < minArrowBox->size.width) // We don't just enforce a minimum, System 7 always had square thumbs.
			knobBox->size.width = minArrowBox->size.width;
		*trackingKnobBox = *knobBox;
		
		knobBox->origin.x += (trackBox->size.width - knobBox->size.width) * doubleValue;
		trackingKnobBox->origin.x += (trackBox->size.width - trackingKnobBox->size.width) * trackingCurrentValue;
	}
	else
	{
		*minArrowBox = (NSRect){ NSZeroPoint, { self.bounds.size.width, self.bounds.size.width } };
		*maxArrowBox = (NSRect){ { 0, NSMaxY(self.bounds) - self.bounds.size.width }, { self.bounds.size.width, self.bounds.size.width } };
		
		trackBox->origin.y += minArrowBox->size.height - 1;
		trackBox->size.height -= minArrowBox->size.height - 1 + maxArrowBox->size.height - 1;
		
		*knobBox = *trackBox;
		//knobBox->size.height *= knobProportion;
		//if (knobBox->size.height < minArrowBox->size.height) // We don't just enforce a minimum, System 7 always had square thumbs.
			knobBox->size.height = minArrowBox->size.height;
		*trackingKnobBox = *knobBox;

		knobBox->origin.y += (trackBox->size.height - knobBox->size.height) * doubleValue;
		trackingKnobBox->origin.y += (trackBox->size.height - trackingKnobBox->size.height) * trackingCurrentValue;
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
	BOOL isHorzNotVert = self.bounds.size.width > self.bounds.size.height;

	NSRect minArrowBox;
	NSRect maxArrowBox;
	NSRect trackBox;
	NSRect knobBox;
	NSRect trackingKnobBox;
	
	[self getMinArrowBox: &minArrowBox maxArrowBox: &maxArrowBox trackBox: &trackBox knobBox: &knobBox trackingKnobBox: &trackingKnobBox];

	[NSColor.whiteColor setFill];
	[NSBezierPath fillRect: self.bounds];
	
	if (isNecessary && isActiveWindow)
	{
		NSImage *pattern = [NSImage imageNamed: @"scrollTrackPattern"];
		NSColor *patternColor = [NSColor colorWithPatternImage: pattern];
		[patternColor setFill];
		[NSBezierPath fillRect: trackBox];
	}

	[NSColor.blackColor setStroke];
	[NSBezierPath strokeRect: [self rectForStroking: self.bounds]];
	
	if (isActiveWindow)
	{
		[NSGraphicsContext saveGraphicsState];

		NSAffineTransform *minArrowTransform = [NSAffineTransform transform];
		[minArrowTransform translateXBy:NSMidX(minArrowBox) yBy:NSMidY(minArrowBox)];
		if (isHorzNotVert)
			[minArrowTransform rotateByDegrees: -90.0];
		[minArrowTransform concat];

		NSImage *upArrowImage = (self.trackedPart == FILScrollerHitPartMinArrow) ? [NSImage imageNamed:@"scrollArrowUpPressed"] : [NSImage imageNamed:@"scrollArrowUp"];
		[upArrowImage drawInRect:(NSRect){ { minArrowBox.size.width / -2.0, minArrowBox.size.height / -2.0 }, minArrowBox.size }];
		[NSGraphicsContext restoreGraphicsState];

		[NSBezierPath strokeRect: [self rectForStroking: minArrowBox]];
		
		[NSGraphicsContext saveGraphicsState];
		NSAffineTransform *maxArrowTransform = [NSAffineTransform transform];
		[maxArrowTransform translateXBy:NSMidX(maxArrowBox) yBy:NSMidY(maxArrowBox)];
		[maxArrowTransform scaleXBy: 1.0 yBy: -1.0];
		if (isHorzNotVert)
			[maxArrowTransform rotateByDegrees: 90.0];
		[maxArrowTransform concat];
		
		upArrowImage = (self.trackedPart == FILScrollerHitPartMaxArrow) ? [NSImage imageNamed:@"scrollArrowUpPressed"] : [NSImage imageNamed:@"scrollArrowUp"];
		[upArrowImage drawInRect:(NSRect){ { maxArrowBox.size.width / -2.0, maxArrowBox.size.height / -2.0 }, maxArrowBox.size }];
		[NSGraphicsContext restoreGraphicsState];
		
		[NSBezierPath strokeRect: [self rectForStroking: maxArrowBox]];
		
		if (isNecessary)
		{
			[NSColor.whiteColor setFill];
			[NSBezierPath fillRect: knobBox];
			[NSBezierPath strokeRect: [self rectForStroking: knobBox]];
			
			if (self.trackingCurrentValue >= 0)
			{
				[NSBezierPath strokeRect: [self rectForStroking: trackingKnobBox]];
			}
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
	NSRect trackingKnobBox;
	
	[self getMinArrowBox: &minArrowBox maxArrowBox: &maxArrowBox trackBox: &trackBox knobBox: &knobBox trackingKnobBox: &trackingKnobBox];
	
	if (NSPointInRect(self.trackStartPos, minArrowBox))
	{
		self.trackedPart = FILScrollerHitPartMinArrow;
		myHitPart = NSScrollerDecrementLine;
		[self sendAction:self.action to:self.target];
		
		self.trackingRepeatTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(arrowTrackingTimer:) userInfo: nil repeats: YES];
	}
	else if (NSPointInRect(self.trackStartPos, maxArrowBox))
	{
		self.trackedPart = FILScrollerHitPartMaxArrow;
		myHitPart = NSScrollerIncrementLine;
		[self sendAction:self.action to:self.target];

		self.trackingRepeatTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(arrowTrackingTimer:) userInfo: nil repeats: YES];
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


-(void) arrowTrackingTimer: (NSTimer *)sender
{
	[self sendAction:self.action to:self.target];
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
		NSRect trackingKnobBox;
		
		[self getMinArrowBox: &minArrowBox maxArrowBox: &maxArrowBox trackBox: &trackBox knobBox: &knobBox trackingKnobBox: &trackingKnobBox];

		BOOL isHorzNotVert = self.bounds.size.width > self.bounds.size.height;
		CGFloat possibleDistance = isHorzNotVert ? (trackBox.size.width - knobBox.size.width) : (trackBox.size.height - knobBox.size.height);

		NSSize diff = { trackEndPos.x - _trackStartPos.x, trackEndPos.y - _trackStartPos.y };
		CGFloat traveledValue = isHorzNotVert ? (diff.width / possibleDistance) : (diff.height / possibleDistance);
		
		CGFloat newValue = self.trackingStartValue + traveledValue;
		if (newValue > 1.0)
			newValue = 1.0;
		else if (newValue < 0)
			newValue = 0;
		
		self.trackingCurrentValue = newValue;
		
		[self setNeedsDisplay: YES];
	}
}


-(void) mouseUp:(NSEvent *)event
{
	if (self.trackingCurrentValue >= 0.0)
	{
		self.doubleValue = self.trackingCurrentValue;
		myHitPart = NSScrollerKnob;
		[self sendAction:self.action to:self.target];
		self.trackingCurrentValue = -1.0;
	}

	[self.trackingRepeatTimer invalidate];
	self.trackingRepeatTimer = nil;
	
	self.trackedPart = FILScrollerHitPartNone;
	[self setNeedsDisplay: YES];
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


-(void)setFloatValue:(float)floatValue
{
	[super setFloatValue: floatValue];
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
