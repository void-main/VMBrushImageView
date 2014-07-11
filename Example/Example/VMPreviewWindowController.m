//
//  VMPreviewWindowController.m
//  Example
//
//  Created by Sun Peng on 14-7-11.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMPreviewWindowController.h"
#import "NSImage+BitmapRep.h"

@implementation VMPreviewWindowController

static void *VMPreviewWindowControllerContext = nil;

- (id)initWithImage:(NSImage *)image mask:(NSImage *)mask
{
    self = [super initWithWindowNibName:@"VMPreviewWindowController"];
    if (self) {
        _image = image;
        _mask = mask;

        [self addObserver:self forKeyPath:@"previewType" options:NSKeyValueObservingOptionNew context:&VMPreviewWindowControllerContext];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"previewType"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [self.previewTypeSelection removeAllItems];
    [self.previewTypeSelection addItemsWithTitles:@[@"Pure Blue", @"Checker Board", @"Custom"]];

    self.previewType = PureBlue;
}

- (IBAction)previewTypeChanged:(id)sender {
    self.previewType = [sender indexOfSelectedItem];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &VMPreviewWindowControllerContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }

    if ([keyPath isEqualToString:@"previewType"]) {
        [self setImageForType];
    }
}

- (void)setImageForType
{
    if (self.previewType == PureBlue) {
        self.backgroundImage = [[NSImage alloc] initWithSize:_image.size];
        [self.backgroundImage lockFocus];
        [[NSColor blueColor] set];
        NSRectFill(NSMakeRect(0, 0, _image.size.width, _image.size.height));
        [self.backgroundImage unlockFocus];
    } else if (self.previewType == CheckerBoard) {
        @autoreleasepool {
            CIFilter *filter = [CIFilter filterWithName:@"CICheckerboardGenerator"];
            [filter setDefaults];
            [filter setValue:[CIVector vectorWithX:_image.size.width * 0.5 Y:_image.size.height * 0.5] forKey:@"inputCenter"];
            [filter setValue:[CIColor colorWithRed:0.8 green:0.8 blue:0.8] forKey:@"inputColor0"];
            [filter setValue:[CIColor colorWithRed:0 green:0 blue:0] forKey:@"inputColor1"];
            [filter setValue:[NSNumber numberWithFloat:10.0] forKey:@"inputWidth"];
            CIImage *result = [filter valueForKey:@"outputImage"];
            result = [result imageByCroppingToRect:CGRectMake(0, 0, _image.size.width, _image.size.height)];

            NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:result];
            self.backgroundImage = [[NSImage alloc] initWithSize:rep.size];
            [self.backgroundImage addRepresentation:rep];
        }
    } else if (self.previewType == CustomImage) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setAllowedFileTypes:@[@"public.image"]];
        [openPanel setCanChooseFiles:YES];
        [openPanel setCanChooseDirectories:NO];
        if ([openPanel runModal] == NSOKButton) {
            NSURL *imageURL = [openPanel URL];
            self.backgroundImage = [[NSImage alloc] initWithContentsOfURL:imageURL];
        }
    }

    @autoreleasepool {
        CIImage *foregroundCI = [[CIImage alloc] initWithBitmapImageRep:[_image bitmapImageRepresentation]];
        CIImage *backgroundCI = [[CIImage alloc] initWithBitmapImageRep:[self.backgroundImage bitmapImageRepresentation]];
        CIImage *maskCI = [[CIImage alloc] initWithBitmapImageRep:[_mask bitmapImageRepresentation]];

        CIFilter *filter = [CIFilter filterWithName:@"CIBlendWithAlphaMask"];
        [filter setDefaults];
        [filter setValue:foregroundCI forKey:@"inputImage"];
        [filter setValue:backgroundCI forKey:@"inputBackgroundImage"];
        [filter setValue:maskCI forKey:@"inputMaskImage"];

        NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:[filter valueForKey:@"outputImage"]];
        self.resultImage = [[NSImage alloc] initWithSize:rep.size];
        [self.resultImage addRepresentation:rep];
    }
}

@end
