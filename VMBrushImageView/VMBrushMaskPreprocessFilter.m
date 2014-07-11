//
//  VMBrushPreprocessFilter.m
//  Example
//
//  Created by Sun Peng on 14-7-11.
//  Copyright (c) 2014年 Void Main. All rights reserved.
//

#import "VMBrushMaskPreprocessFilter.h"

@implementation VMBrushPreprocessFilter

static CIKernel *brushPreprocessKernel = nil;

+ (void)initialize
{
    [CIFilter registerFilterName: @"VMBrushMaskPreprocessFilter"
                     constructor: self
                 classAttributes:
     @{kCIAttributeFilterDisplayName : @"Brush Mask Preprocesser",
       kCIAttributeFilterCategories : @[
               kCICategoryColorAdjustment,
               kCICategoryStillImage]}
     ];
}

+ (CIFilter *)filterWithName: (NSString *)name
{
    CIFilter  *filter;
    filter = [[self alloc] init];
    return filter;
}

- (id)init
{
    if (brushPreprocessKernel == nil)
    {
        NSString *code = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource: @"VMBrushMaskPreprocessKernel" ofType: @"cikernel"]
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];
        NSArray     *kernels = [CIKernel kernelsWithString: code];
        brushPreprocessKernel = kernels[0];
    }
    return [super init];
}

- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage: inputImage];

    return [self apply: brushPreprocessKernel, src, kCIApplyOptionDefinition, [src definition], nil];
}

@end
