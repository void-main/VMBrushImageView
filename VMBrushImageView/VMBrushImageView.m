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

- (void)createMaskImageFor:(NSImage *)image;
- (void)scribbleFrom:(CGPoint)start to:(CGPoint)end radius:(float)radius type:(BrushType)type;

@end

@interface VMBrushImageView (ViewHierarchy)

- (NSScrollView *)parentScrollView;

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
        self.maxBrushRadius = 40;
        self.minBrushRadius = 2;

        _triggerDuringMove = NO;
        _maskOperationBlock = nil;

        _scribbleView = [[NSImageView alloc] initWithFrame:self.bounds];
        [_scribbleView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_scribbleView setWantsLayer:YES];
        [_scribbleView setAlphaValue:0.5];
        [self addSubview:_scribbleView];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scribbleView]|"
                                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_scribbleView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scribbleView]|"
                                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_scribbleView)]];

        _pointsToDraw = [[NSMutableArray alloc] init];

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

    _scribbling = YES;

    NSThread *drawScribbleThread = [[NSThread alloc] initWithTarget:self selector:@selector(drawScirbble) object:nil];
    [drawScribbleThread start];

    [_pointsToDraw removeAllObjects];

    // Add a start point and a same end point
    [_pointsToDraw addObject:[NSValue valueWithPoint:point]];
    [_pointsToDraw addObject:[NSValue valueWithPoint:point]];

    [self needsDisplay];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    CGPoint point = [theEvent locationInWindow];
    point = [self convertPoint:point fromView:nil];

    [_pointsToDraw addObject:[NSValue valueWithPoint:point]];
    [self needsDisplay];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    _scribbling = NO;
}

- (void)drawScirbble
{
    CGPoint lastPoint = CGPointMake(-1, -1);
    while (_scribbling || _pointsToDraw.count > 0) {
        if (_pointsToDraw.count > 0) {
            CGPoint newPoint = [[_pointsToDraw objectAtIndex:0] pointValue];
            [_pointsToDraw removeObjectAtIndex:0];
            if (lastPoint.x < 0 && lastPoint.x < 0) {
                lastPoint = newPoint;
                continue;
            }

            [self scribbleFrom:lastPoint to:newPoint radius:self.brushRadius type:self.brushType];

            lastPoint = newPoint;
            NSImage *maskImage = nil;
            if (_triggerDuringMove && _maskOperationBlock) {
                NSImage *newMask = _maskOperationBlock(self.image, maskImage);
                _maskRep = [newMask bitmapImageRepresentation];
                _scribbleView.image = newMask;
            } else {
                maskImage = [[NSImage alloc] initWithCGImage:[_maskRep CGImage] size:_maskRep.size];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                _scribbleView.image = maskImage;
            });
        } else {
            [NSThread sleepForTimeInterval:0.03];
        }
    }

    if (_maskOperationBlock) {
        NSImage *newMask = _maskOperationBlock(self.image, [[NSImage alloc] initWithCGImage:[_maskRep CGImage] size:_maskRep.size]);
        _maskRep = [newMask bitmapImageRepresentation];
        _scribbleView.image = newMask;
    }
}

- (void)cursorUpdate:(NSEvent *)event
{
    NSCursor *brushCursor = [[NSCursor alloc] initWithImage:[self cursorImage] hotSpot:CGPointMake(self.brushRadius, self.brushRadius)];
    [brushCursor set];
}

#pragma mark -
#pragma mark Basic Operations
- (void)setRawImage:(NSImage *)image
{
    [self createMaskImageFor:image];
    self.image = image;
    _scribbleView.image = nil;
    [self needsDisplay];
}

- (void)setMaskOperation:(ImageOperationBlock)maskOperations triggerDuringMove:(BOOL)triggerDuringMove
{
    _maskOperationBlock = maskOperations;
    _triggerDuringMove = triggerDuringMove;
}

#pragma mark -
#pragma mark UI interactions
- (void)increaseBrushRadius:(float)increment
{
    self.brushRadius += increment;
    if (self.brushRadius > self.maxBrushRadius) self.brushRadius = self.maxBrushRadius;
}

- (void)decreaseBrushRadius:(float)decrement
{
    self.brushRadius -= decrement;
    if (self.brushRadius < self.minBrushRadius) self.brushRadius = self.minBrushRadius;
}

- (void)resetMask {
    @autoreleasepool {
        // Get the graphics context that we are currently executing under
        NSGraphicsContext* bitmapGraphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:_maskRep];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:bitmapGraphicsContext];

        [kEraserColor set];
        NSRectFill(NSMakeRect(0, 0, _maskRep.size.width, _maskRep.size.height));

        [bitmapGraphicsContext flushGraphics];
        [NSGraphicsContext restoreGraphicsState];

        bitmapGraphicsContext = nil;
    }

    _scribbleView.image = [[NSImage alloc] initWithCGImage:[_maskRep CGImage] size:_maskRep.size];
}

#pragma mark -
#pragma mark Output
- (NSImage *)outMask
{
    NSImage *result = nil;
    @autoreleasepool {
        CIImage *maskCI = [[CIImage alloc] initWithBitmapImageRep:_maskRep];
        CIImage *alphaCI = nil;

        CIFilter *maskToAlpha = [CIFilter filterWithName:@"CIMaskToAlpha"];
        [maskToAlpha setDefaults];
        [maskToAlpha setValue:maskCI forKey:@"inputImage"];
        alphaCI = [maskToAlpha valueForKey:@"outputImage"];

        NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:alphaCI];
        result = [[NSImage alloc] initWithSize:rep.size];
        [result addRepresentation:rep];

        maskCI = nil;
        alphaCI = nil;
    }
    
    return result;
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
            cursorColor = kForegroundColor;
            break;
        case Background:
            cursorColor = kBackgroundColor;
            break;
        default:
            cursorColor = kEraserColor;
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
- (void)createMaskImageFor:(NSImage *)image
{
    CGSize size;
    @autoreleasepool {
        NSBitmapImageRep *rep = [image bitmapImageRepresentation];
        size = rep.size;
    }

    NSImage* resultImage = [[NSImage alloc] initWithSize:size];
    [resultImage lockFocus];
    [kEraserColor set];
    NSRectFill(CGRectMake(0, 0, size.width, size.height));
    [resultImage unlockFocus];

    _maskRep = [resultImage bitmapImageRepresentation];
}

- (void)scribbleFrom:(CGPoint)start to:(CGPoint)end radius:(float)radius type:(BrushType)type
{
    CGFloat magnification = 1.0f;

    NSScrollView *scrollView = [self parentScrollView];
    if (scrollView) {
        magnification = scrollView.magnification;
    }

    radius = roundf(radius) / magnification;
    start.x = roundf(start.x);
    start.y = roundf(start.y);
    end.x = roundf(end.x);
    end.y = roundf(end.y);

    @autoreleasepool {
        // Get the graphics context that we are currently executing under
        NSGraphicsContext* bitmapGraphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:_maskRep];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:bitmapGraphicsContext];

        // Set the color in the current graphics context for future draw operations
        switch (type) {
            case Foreground:
                [kForegroundColor set];
                break;
            case Background:
                [kBackgroundColor set];
                break;
            default:
                [kEraserColor set];
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

        // http://www.cocoabuilder.com/archive/cocoa/144472-nscolor-clearcolor-and-nsbezierpath-not-compatible.html
        // According to Stefan in the thread,
        // `NSBezierPath uses the NSCompositeSourceOver operation, therefore clearColor does not do anything.`
        // But my eraser color is [NSColor clearColor], so I have to change compositingOperation for Eraser type
        NSGraphicsContext *context = nil;
        if (type == Eraser) {
            context = [NSGraphicsContext currentContext];
            [context saveGraphicsState];
            [context setCompositingOperation:NSCompositeClear];
        }


        // Outline and fill the path
        [circlePath fill];
        [linePath stroke];

        if (type == Eraser) {
            [context restoreGraphicsState];
        }

        [bitmapGraphicsContext flushGraphics];
        [NSGraphicsContext restoreGraphicsState];
        
        bitmapGraphicsContext = nil;
    }
}

#pragma mark -
#pragma mark View Hierarchy
- (NSScrollView *)parentScrollView
{
    if (([self.superview isKindOfClass:[NSClipView class]]) &&
        ([self.superview.superview isKindOfClass:[NSScrollView class]])) {
        NSScrollView *scrollView = (NSScrollView *)self.superview.superview;
        return scrollView;
    }

    return nil;
}

@end
