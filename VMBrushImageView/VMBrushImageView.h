//
//  VMBrushImageView.h
//  Example
//
//  Created by Sun Peng on 14-7-10.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#define kForegroundColor  [NSColor greenColor]
#define kBackgroundColor  [NSColor redColor]
#define kEraserColor      [NSColor clearColor]

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
    NSImageView *_scribbleView;

    NSImage *_rawImage;
    NSBitmapImageRep *_rawRep;
    NSBitmapImageRep *_maskRep;

    NSCursor *_brushCursor;

    BOOL _scribbling;
    NSMutableArray *_pointsToDraw;
}

@property float brushRadius;
@property BrushType brushType;
@property PreviewType previewType;

- (void)setRawImage:(NSImage *)image;

- (void)increaseBrushRadius:(float)increment;
- (void)decreaseBrushRadius:(float)decrement;

@end
