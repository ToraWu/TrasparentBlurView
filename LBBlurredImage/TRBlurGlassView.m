//
//  TRBlurGlassView.m
//  LBBlurredImage
//
//  Created by Tora on 13-1-24.
//  Copyright (c) 2013年 Tora Wu. All rights reserved.
//

#import "TRBlurGlassView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>

@interface TRBlurGlassView ()

@property (nonatomic) CIContext *ciContext;

@end

@implementation TRBlurGlassView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.layer.cornerRadius = 20.0f;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        self.blurRadius = 2.5;
        
        EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.ciContext  = [CIContext contextWithEAGLContext:myEAGLContext options:nil];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    UIView *view = [[self.window subviews] objectAtIndex:0];
    self.hidden = YES;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, view.bounds.size.height);
    CGContextScaleCTM (context, 1, -1);
    CGContextClipToRect(context, CGRectInset([self convertRect:rect toView:view], -2*self.blurRadius, -2*self.blurRadius));
    [view.layer renderInContext:context];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.hidden = NO;
    
    
    CIImage *sourceImage = [CIImage imageWithCGImage:viewImage.CGImage];
    
    
    // Apply clamp filter:
    // this is needed because the CIGaussianBlur when applied makes
    // a trasparent border around the image
    
    NSString *clampFilterName = @"CIAffineClamp";
    CIFilter *clamp = [CIFilter filterWithName:clampFilterName];
    
    [clamp setValue:sourceImage
             forKey:kCIInputImageKey];
    
    CIImage *clampResult = [clamp valueForKey:kCIOutputImageKey];
    
    
    // Apply Gaussian Blur filter
    
    NSString *gaussianBlurFilterName = @"CIGaussianBlur";
    CIFilter *gaussianBlur           = [CIFilter filterWithName:gaussianBlurFilterName];
    
    [gaussianBlur setValue:clampResult
                    forKey:kCIInputImageKey];
    [gaussianBlur setValue:[NSNumber numberWithFloat:self.blurRadius]
                    forKey:@"inputRadius"];
    
    CIImage *gaussianBlurResult = [gaussianBlur valueForKey:kCIOutputImageKey];

    
    CGRect convertedRect = [self convertRect:rect toView:view];
    NSLog(@"%.0f*%.0f", sourceImage.extent.size.width, sourceImage.extent.size.height);
    CGImageRef cgImage = [self.ciContext createCGImage:gaussianBlurResult
                                       fromRect:convertedRect];
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, cgImage);
    //[self.ciContext drawImage:gaussianBlurResult inRect:convertedRect fromRect:rect];
}


/*
- (void)layoutSubviews {
    UIView *view = [[self.window subviews] objectAtIndex:0];
    self.hidden = YES;
    UIGraphicsBeginImageContext(view.bounds.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.hidden = NO;
    [self setImageToBlur: viewImage
              blurRadius: 20
                    rect: [self convertRect:self.bounds toView:view]
         completionBlock: ^(NSError *error){
             NSLog(@"The blurred image has been setted");
         }];
}
*/

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [event.allTouches anyObject];
    if (touch) {
        CGPoint currentTouchPoint = [touch locationInView:self.superview];
        CGPoint previousTouchPoint = [touch previousLocationInView:self.superview];
        
        self.frame = CGRectMake(self.frame.origin.x + (currentTouchPoint.x - previousTouchPoint.x),
                                self.frame.origin.y + (currentTouchPoint.y - previousTouchPoint.y),
                                self.frame.size.width, self.frame.size.height);
        [self setNeedsDisplay];
    }
}

@end
