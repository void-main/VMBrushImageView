//
//  VMBrushImageView.h
//  Example
//
//  Created by Sun Peng on 14-7-10.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kForegroundColor  [NSColor greenColor]
#define kBackgroundColor  [NSColor redColor]
#define kEraserColor      [NSColor whiteColor]

typedef enum : NSUInteger {
    Foreground = 0,
    Background = 1,
    Eraser     = 2,
} BrushType;

typedef enum : NSUInteger {
    BrushScribbles,
    Checkerboard,
    PureColor,
    Custom,
} PreviewType;

@interface VMBrushImageView : NSImageView {
    NSImage *_rawImage;
    NSImage *_maskImage;

    NSCursor *_brushCursor;

    CGPoint _lastPoint;
}

@property float brushRadius;
@property BrushType brushType;
@property PreviewType previewType;

- (void)setImage:(NSImage *)image;

- (void)increaseBrushRadius:(float)increment;
- (void)decreaseBrushRadius:(float)decrement;

@end
