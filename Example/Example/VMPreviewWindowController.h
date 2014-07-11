//
//  VMPreviewWindowController.h
//  Example
//
//  Created by Sun Peng on 14-7-11.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

typedef enum : NSUInteger {
    PureBlue,
    CheckerBoard,
    CustomImage
} PreviewType;

@interface VMPreviewWindowController : NSWindowController {
    NSImage *_image;
    NSImage *_mask;
}

@property PreviewType previewType;
@property (nonatomic, strong) NSImage *backgroundImage;
@property (nonatomic, strong) NSImage *resultImage;
@property (strong) IBOutlet NSPopUpButton *previewTypeSelection;

- (id)initWithImage:(NSImage *)image mask:(NSImage *)mask;

@end
