//
//  VMCenteringClipView.m
//  VMPhotoEditor
//
//  Created by Sun Peng on 7/6/14.
//  Copyright (c) 2014 Void Main. All rights reserved.
//

#import "VMCenteringClipView.h"

@implementation VMCenteringClipView

-(void)centerDocument
{
	NSRect docRect = [[self documentView] frame];
	NSRect clipRect = [self bounds];

	if( docRect.size.width < clipRect.size.width )
		clipRect.origin.x = ( docRect.size.width - clipRect.size.width ) / 2.0;
	else
		clipRect.origin.x = _lookingAt.x * docRect.size.width - ( clipRect.size.width / 2.0 );

	if( docRect.size.height < clipRect.size.height )
		clipRect.origin.y = ( docRect.size.height - clipRect.size.height ) / 2.0;
	else
		clipRect.origin.y = _lookingAt.y * docRect.size.height - ( clipRect.size.height / 2.0 );

	[self scrollToPoint:[self constrainScrollPoint:clipRect.origin]];
	[[self superview] reflectScrolledClipView:self];
}

-(NSPoint)constrainScrollPoint:(NSPoint)proposedNewOrigin
{
	NSRect docRect = [[self documentView] frame];
	NSRect clipRect = [self bounds];
	float maxX = docRect.size.width - clipRect.size.width;
	float maxY = docRect.size.height - clipRect.size.height;

	clipRect.origin = proposedNewOrigin; // shift origin to proposed location

	// If the clip view is wider than the doc, we can't scroll horizontally
	if( docRect.size.width < clipRect.size.width )
		clipRect.origin.x = round( maxX / 2.0 );
	else
		clipRect.origin.x = round( MAX(0,MIN(clipRect.origin.x,maxX)) );

	// If the clip view is taller than the doc, we can't scroll vertically
	if( docRect.size.height < clipRect.size.height )
		clipRect.origin.y = round( maxY / 2.0 );
	else
		clipRect.origin.y = round( MAX(0,MIN(clipRect.origin.y,maxY)) );

	// Save center of view as proportions so we can later tell where the user was focused.
	_lookingAt.x = NSMidX(clipRect) / docRect.size.width;
	_lookingAt.y = NSMidY(clipRect) / docRect.size.height;

	return clipRect.origin;
}

-(void)viewBoundsChanged:(NSNotification *)notification
{
	NSPoint savedPoint = _lookingAt;
	[super viewBoundsChanged:notification];
	_lookingAt = savedPoint;
	[self centerDocument];
}

-(void)viewFrameChanged:(NSNotification *)notification
{
	NSPoint savedPoint = _lookingAt;
	[super viewFrameChanged:notification];
	_lookingAt = savedPoint;
	[self centerDocument];
}

-(void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	[self centerDocument];
}

-(void)setFrameOrigin:(NSPoint)newOrigin
{
	[super setFrameOrigin:newOrigin];
	[self centerDocument];
}

-(void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	[self centerDocument];
}

-(void)setFrameRotation:(CGFloat)angle
{
	[super setFrameRotation:angle];
	[self centerDocument];
}

@end
