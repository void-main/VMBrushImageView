//
//  VMBrushImageView.m
//  Example
//
//  Created by Sun Peng on 14-7-10.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMBrushImageView.h"
#import "NSImage+BitmapRep.h"

@interface VMBrushImageView (Mask)

- (NSImage *)genMaskImageFor:(NSImage *)image;
- (NSImage *)compositeMask:(NSImage *)mask over:(NSImage *)image;
- (NSImage *)lineOn:(NSImage *)image from:(CGPoint)start to:(CGPoint)end radius:(float)radius type:(BrushType)type;

@end

@interface VMBrushImageView (Cursor)

- (NSImage *)cursorImage;

@end

@implementation VMBrushImageView

static void *VMBrushImageViewContext = nil;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.brushType = Foreground;
        self.brushRadius = 10;

        [self addObserver:self forKeyPath:@"brushType" options:NSKeyValueObservingOptionNew context:&VMBrushImageViewContext];
        [self addObserver:self forKeyPath:@"brushRadius" options:NSKeyValueObservingOptionNew context:&VMBrushImageViewContext];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"brushType"];
    [self removeObserver:self forKeyPath:@"brushRadius"];
}

- (void)viewDidMoveToWindow
{
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                                options:NSTrackingCursorUpdate | NSTrackingActiveInActiveApp
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    CGPoint point = [theEvent locationInWindow];
    point = [self convertPoint:point fromView:nil];
    _maskImage = [self lineOn:_maskImage from:point to:point radius:self.brushRadius type:self.brushType];
    _lastPoint = point;

    [super setImage:[self compositeMask:_maskImage over:_rawImage]];
    [self needsDisplay];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    CGPoint point = [theEvent locationInWindow];
    point = [self convertPoint:point fromView:nil];
    _maskImage = [self lineOn:_maskImage from:_lastPoint to:point radius:self.brushRadius type:self.brushType];
    _lastPoint = point;

    [super setImage:[self compositeMask:_maskImage over:_rawImage]];
    [self needsDisplay];
}

- (void)cursorUpdate:(NSEvent *)event
{
    NSCursor *brushCursor = [[NSCursor alloc] initWithImage:[self cursorImage] hotSpot:CGPointMake(self.brushRadius, self.brushRadius)];
    [brushCursor set];
}

- (void)setImage:(NSImage *)image
{
    _rawImage = [image copy];
    _maskImage = [self genMaskImageFor:_rawImage];
    [super setImage:[self compositeMask:_maskImage over:_rawImage]];
    self.frame = CGRectMake(0, 0, _rawImage.size.width, _rawImage.size.height);
    self.bounds = CGRectMake(0, 0, _rawImage.size.width, _rawImage.size.height);\
    [self needsDisplay];
}

- (void)increaseBrushRadius:(float)increment
{
    self.brushRadius += increment;
}

- (void)decreaseBrushRadius:(float)decrement
{
    self.brushRadius -= decrement;
}

#pragma mark -
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &VMBrushImageViewContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }

    if ([keyPath hasPrefix:@"brush"]) {
        [self updateCursor];
    }
}

#pragma mark -
#pragma mark Brush Cursor
- (void)updateCursor
{
    NSCursor *brushCursor = [[NSCursor alloc] initWithImage:[self cursorImage] hotSpot:CGPointMake(self.brushRadius, self.brushRadius)];
    [brushCursor set];
}

- (NSImage *)cursorImage
{
    NSImage *image = [[NSImage alloc] initWithSize:CGSizeMake(2 * self.brushRadius + 1, 2 * self.brushRadius + 1)];
    [image lockFocus];

    NSColor *cursorColor = nil;
    switch (self.brushType) {
        case Foreground:
            cursorColor = [NSColor greenColor];
            break;
        case Background:
            cursorColor = [NSColor redColor];
            break;
        default:
            cursorColor = [NSColor whiteColor];
            break;
    }

    // Get the graphics context that we are currently executing under
    NSGraphicsContext* gc = [NSGraphicsContext currentContext];

    // Save the current graphics context settings
    [gc saveGraphicsState];

    // Create our circle path
    NSRect rect = NSMakeRect(1, 1, 2 * self.brushRadius - 1, 2 * self.brushRadius - 1);
    NSBezierPath* circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect:rect];

    // Outline and fill the path
    [[NSColor whiteColor] setStroke];
    [circlePath stroke];

    NSRect blackRect = NSMakeRect(2, 2, 2 * self.brushRadius - 3, 2 * self.brushRadius - 3);
    circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect:blackRect];

    // Outline and fill the path
    [cursorColor setStroke];
    [circlePath stroke];

    // Restore the context to what it was before we messed with it
    [gc restoreGraphicsState];
    [image unlockFocus];
    
    return image;
}

#pragma mark -
#pragma mark Mask-related Methods
- (NSImage *)genMaskImageFor:(NSImage *)image
{
    CGSize size;
    @autoreleasepool {
        NSBitmapImageRep *rep = [image bitmapImageRepresentation];
        size = rep.size;
    }

    NSImage* resultImage = [[NSImage alloc] initWithSize:size];
    [resultImage lockFocus];
    [[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0] set];
    NSRectFill(CGRectMake(0, 0, size.width, size.height));
    [resultImage unlockFocus];

    return resultImage;
}

- (NSImage *)compositeMask:(NSImage *)mask over:(NSImage *)image
{
    NSImage *result = [[NSImage alloc] initWithSize:image.size];
    [result lockFocus];
    [image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [mask drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.5];
    [result unlockFocus];

    return result;
}

- (NSImage *)lineOn:(NSImage *)image from:(CGPoint)start to:(CGPoint)end radius:(float)radius type:(BrushType)type
{
    CGFloat magnification = 1.0f;
    if (([self.superview isKindOfClass:[NSClipView class]]) &&
         ([self.superview.superview isKindOfClass:[NSScrollView class]])) {
        NSScrollView *scrollView = (NSScrollView *)self.superview.superview;
        magnification = scrollView.magnification;
    }

    radius = roundf(radius) / magnification;
    start.x = roundf(start.x);
    start.y = roundf(start.y);
    end.x = roundf(end.x);
    end.y = roundf(end.y);

    [image lockFocus];

    // Get the graphics context that we are currently executing under
    NSGraphicsContext* gc = [NSGraphicsContext currentContext];

    // Save the current graphics context settings
    [gc saveGraphicsState];

    // Set the color in the current graphics context for future draw operations
    switch (type) {
        case Foreground:
            [[NSColor greenColor] set];
            break;
        case Background:
            [[NSColor redColor] set];
            break;
        default:
            [[NSColor clearColor] set];
            break;
    }

    NSBezierPath* linePath = [NSBezierPath bezierPath];
    [linePath setLineWidth:2 * radius + 1];

    [linePath moveToPoint:start];
    [linePath curveToPoint:end controlPoint1:start controlPoint2:end];
    [linePath closePath];

    // Create our circle path
    NSRect rect = NSMakeRect(end.x - radius, end.y - radius, 2 * radius + 1, 2 * radius + 1);
    NSBezierPath* circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect: rect];

    // Outline and fill the path
    [circlePath fill];


    [linePath stroke];

    // Restore the context to what it was before we messed with it
    [gc restoreGraphicsState];
    [image unlockFocus];

    return image;
}

@end
