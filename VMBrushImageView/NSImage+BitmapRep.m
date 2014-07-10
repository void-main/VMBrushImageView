//
//  NSImage+BitmapRep.m
//  LensBlur
//
//  Created by Sun Peng on 14-1-21.
//  Copyright (c) 2014年 NexusHubs. All rights reserved.
//

#import "NSImage+BitmapRep.h"

@implementation NSImage (BitmapRep)

- (NSBitmapImageRep *)bitmapImageRepresentation {
    int width = self.size.width;
    int height = self.size.height;
    
    if(width < 1 || height < 1)
        return nil;
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes: NULL
                             pixelsWide: width
                             pixelsHigh: height
                             bitsPerSample: 8
                             samplesPerPixel: 4
                             hasAlpha: YES
                             isPlanar: NO
                             colorSpaceName: NSDeviceRGBColorSpace
                             bytesPerRow: 0
                             bitsPerPixel: 0];
    
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep: rep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: ctx];
    [self drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, width, height) operation:NSCompositeCopy fraction:1.0];
    [ctx flushGraphics];
    [NSGraphicsContext restoreGraphicsState];
    
    return rep;
}

@end
