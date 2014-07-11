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
//- (NSImage *)compositeMaskOver:(NSImage *)image;
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
        self.previewType = BrushScribbles;
        self.brushType = Foreground;
        self.brushRadius = 10;

        _scribbleView = [[NSImageView alloc] initWithFrame:self.bounds];
        [_scribbleView setTranslatesAutoresizingMaskIntoConstraints:NO];
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
            dispatch_async(dispatch_get_main_queue(), ^{
//                self.image = [self compositeMaskOver:_rawImage];
                _scribbleView.image = [[NSImage alloc] initWithCGImage:[_maskRep CGImage] size:_maskRep.size];
            });
        } else {
            [NSThread sleepForTimeInterval:0.03];
        }
    }
}

- (void)cursorUpdate:(NSEvent *)event
{
    NSCursor *brushCursor = [[NSCursor alloc] initWithImage:[self cursorImage] hotSpot:CGPointMake(self.brushRadius, self.brushRadius)];
    [brushCursor set];
}

- (void)setRawImage:(NSImage *)image
{
    _rawImage = [image copy];
    [self createMaskImageFor:_rawImage];
    self.image = _rawImage;
    _scribbleView.image = nil;
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
        _rawRep = [rep copy];
        size = rep.size;
    }

    NSImage* resultImage = [[NSImage alloc] initWithSize:size];
    [resultImage lockFocus];
    [kEraserColor set];
    NSRectFill(CGRectMake(0, 0, size.width, size.height));
    [resultImage unlockFocus];

    _maskRep = [resultImage bitmapImageRepresentation];
}

//- (NSImage *)compositeMaskOver:(NSImage *)image
//{
//    NSImage *result = nil;
//
//    @autoreleasepool {
//        CIImage *maskCI = [[CIImage alloc] initWithBitmapImageRep:_maskRep];
//        CIImage *rawCI = [[CIImage alloc] initWithBitmapImageRep:_rawRep];
//        CIImage *alphaCI = nil;
//
//        CIFilter *maskToAlpha = [CIFilter filterWithName:@"CIMaskToAlpha"];
//        [maskToAlpha setDefaults];
//        [maskToAlpha setValue:maskCI forKey:@"inputImage"];
//        alphaCI = [maskToAlpha valueForKey:@"outputImage"];
//
//        CIFilter *blendFilter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"];
//        [blendFilter setDefaults];
//        [blendFilter setValue:maskCI forKey:@"inputImage"];
//        [blendFilter setValue:rawCI forKey:@"inputBackgroundImage"];
//        [blendFilter setValue:alphaCI forKey:@"inputMaskImage"];
//        rawCI = [blendFilter valueForKey:@"outputImage"];
//
//        NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:rawCI];
//        result = [[NSImage alloc] initWithSize:rep.size];
//        [result addRepresentation:rep];
//
//        maskCI = nil;
//        rawCI = nil;
//        alphaCI = nil;
//    }
//
//    return result;
////    return [[NSImage alloc] initWithCGImage:[_maskRep CGImage] size:_maskRep.size];
//}

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

        // Outline and fill the path
        [circlePath fill];
        [linePath stroke];
        
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
