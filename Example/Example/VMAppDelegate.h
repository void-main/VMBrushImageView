//
//  VMAppDelegate.h
//  Example
//
//  Created by Sun Peng on 14-7-10.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VMBrushImageView;
@class VMPreviewWindowController;
@interface VMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet VMBrushImageView *brushImageView;
@property (nonatomic, strong) VMPreviewWindowController *previewWindowController;

@end
