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
        //self.layer.cornerRadius = 20.0f;
        //self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        self.blurRadius = 2.5;
        
        EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.ciContext  = [CIContext contextWithEAGLContext:myEAGLContext options:nil];
        
        //self.maskImage = [[QRCodeGenerator shareInstance] qrImageForString:@"http://roundqr.sinaapp.com/index.php" withPixSize:8 withMargin:2 withMode:5 withOutputSize:400];
    }
    return self;
}

- (UIImage *)captureView:(UIView *)view {
    CGRect screenRect = [view bounds];
    UIGraphicsBeginImageContext(screenRect.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] set];
    CGContextFillRect(ctx, screenRect);
    [view.layer renderInContext:ctx];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    ctx = nil;
    
    return newImage;
}

- (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    
    CGImageRef srcImg  = image.CGImage;
	CGImageRef maskRef = maskImage.CGImage;
    
	CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
	CGImageRef masked = CGImageCreateWithMask(srcImg, mask);
    UIImage *result = [UIImage imageWithCGImage:masked];
    
    CGImageRelease(masked);
    CGImageRelease(mask);
    
	return result;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect
{
    
    CGFloat screenScale = [UIScreen mainScreen].scale;
    
    // Drawing code
    UIView *view = [[self.window subviews] objectAtIndex:0];
    self.hidden = YES;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, screenScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, view.bounds.size.height);
    CGContextScaleCTM (context, 1/screenScale, -1/screenScale);
    [view.layer renderInContext:context];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.hidden = NO;
    
    CIImage *sourceImage = [CIImage imageWithCGImage:viewImage.CGImage];
    
    NSString *cropFilterName = @"CICrop";
    CIFilter *crop = [CIFilter filterWithName:cropFilterName];
    
    [crop setValue:sourceImage
             forKey:kCIInputImageKey];
    [crop setValue:[CIVector vectorWithCGRect:[self convertRect:rect toView:view]] forKey:@"inputRectangle"];
    
    CIImage *cropResult = [crop valueForKey:kCIOutputImageKey];
    
    
    // Apply clamp filter:
    // this is needed because the CIGaussianBlur when applied makes
    // a trasparent border around the image
    
    NSString *clampFilterName = @"CIAffineClamp";
    CIFilter *clamp = [CIFilter filterWithName:clampFilterName];
    
    [clamp setValue:cropResult
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
    
    context = UIGraphicsGetCurrentContext();

    CGRect convertedRect = [self convertRect:rect toView:view];
    CGImageRef srcImg = [self.ciContext createCGImage:gaussianBlurResult
                                             fromRect:cropResult.extent];
    
    if (self.maskImage) {
        
        CGImageRef maskRef = self.maskImage.CGImage;
        
        CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                            CGImageGetHeight(maskRef),
                                            CGImageGetBitsPerComponent(maskRef),
                                            CGImageGetBitsPerPixel(maskRef),
                                            CGImageGetBytesPerRow(maskRef),
                                            CGImageGetDataProvider(maskRef), NULL, true);
        
        CGImageRef masked = CGImageCreateWithMask(srcImg, mask);
        
        convertedRect = CGRectApplyAffineTransform(convertedRect, CGAffineTransformMakeScale(1, -1));
        convertedRect = CGRectApplyAffineTransform(convertedRect, CGAffineTransformMakeTranslation(0, view.bounds.size.height*screenScale));
        
        CGImageRef cropedViewImage = CGImageCreateWithImageInRect(viewImage.CGImage, convertedRect);
        CGContextDrawImage(context, rect, cropedViewImage);
        //CGContextSetBlendMode (context, kCGBlendModeMultiply);
        CGContextDrawImage(context, rect, masked);
        
        CGImageRelease(mask);
        CGImageRelease(cropedViewImage);
        CGImageRelease(masked);
    } else {
        CGContextDrawImage(context, rect, srcImg);
    }
    
    CGImageRelease(srcImg);
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
