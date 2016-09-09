//
//  UIImage+ResizeMagick.m
//
//
//  Created by Vlad Andersen on 1/5/13.
//
//

#import "UIImage+ResizeMagick.h"

static CGInterpolationQuality _interpolationQuality = kCGInterpolationNone;

@implementation UIImage (ResizeMagick)

// width	Width given, height automagically selected to preserve aspect ratio.
// xheight	Height given, width automagically selected to preserve aspect ratio.
// widthxheight	Maximum values of height and width given, aspect ratio preserved.
// widthxheight^	Minimum values of width and height given, aspect ratio preserved.
// widthxheight!	Exact dimensions, no aspect ratio preserved.
// widthxheight#	Crop to this exact dimensions.

+(void)setInterpolationQuality:(CGInterpolationQuality)quality {
    _interpolationQuality = quality;
}

+(CGInterpolationQuality)interpolationQuality {
    return _interpolationQuality;
}

- (UIImage *) resizedImageByMagick: (NSString *) spec
{
    
    if([spec hasSuffix:@"!"]) {
        NSString *specWithoutSuffix = [spec substringToIndex: [spec length] - 1];
        NSArray *widthAndHeight = [specWithoutSuffix componentsSeparatedByString: @"x"];
        NSUInteger width = labs([[widthAndHeight objectAtIndex: 0] integerValue]);
        NSUInteger height = labs([[widthAndHeight objectAtIndex: 1] integerValue]);
        UIImage *newImage = [self resizedImageWithMinimumSize: CGSizeMake (width, height)];
        return [newImage drawImageInBounds: CGRectMake (0, 0, width, height)];
    }
    
    if([spec hasSuffix:@"#"]) {
        NSString *specWithoutSuffix = [spec substringToIndex: [spec length] - 1];
        NSArray *widthAndHeight = [specWithoutSuffix componentsSeparatedByString: @"x"];
        NSUInteger width = labs([[widthAndHeight objectAtIndex: 0] integerValue]);
        NSUInteger height = labs([[widthAndHeight objectAtIndex: 1] integerValue]);
        UIImage *newImage = [self resizedImageWithMinimumSize: CGSizeMake (width, height)];
        return [newImage croppedImageWithRect: CGRectMake ((newImage.size.width - width) / 2, (newImage.size.height - height) / 2, width, height)];
    }
    
    if([spec hasSuffix:@"^"]) {
        NSString *specWithoutSuffix = [spec substringToIndex: [spec length] - 1];
        NSArray *widthAndHeight = [specWithoutSuffix componentsSeparatedByString: @"x"];
        return [self resizedImageWithMinimumSize: CGSizeMake (labs([[widthAndHeight objectAtIndex: 0] integerValue]),
                                                              labs([[widthAndHeight objectAtIndex: 1] integerValue]))];
    }
    
    NSArray *widthAndHeight = [spec componentsSeparatedByString: @"x"];
    if ([widthAndHeight count] == 1) {
        return [self resizedImageByWidth: [spec integerValue]];
    }
    if ([[widthAndHeight objectAtIndex: 0] isEqualToString: @""]) {
        return [self resizedImageByHeight: labs([[widthAndHeight objectAtIndex: 1] integerValue])];
    }
    return [self resizedImageWithMaximumSize: CGSizeMake (labs([[widthAndHeight objectAtIndex: 0] integerValue]),
                                                          labs([[widthAndHeight objectAtIndex: 1] integerValue]))];
}

- (CGImageRef) CGImageWithCorrectOrientation CF_RETURNS_RETAINED
{
    if (self.imageOrientation == UIImageOrientationDown) {
        //retaining because caller expects to own the reference
        CGImageRef cgImage = [self CGImage];
        CGImageRetain(cgImage);
        return cgImage;
    }
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, _interpolationQuality);
    
    if (self.imageOrientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, 90 * M_PI/180);
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, -90 * M_PI/180);
    } else if (self.imageOrientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, 180 * M_PI/180);
    }
    
    [self drawAtPoint:CGPointMake(0, 0)];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIGraphicsEndImageContext();
    
    return cgImage;
}


- (UIImage *) resizedImageByWidth:  (NSUInteger) width
{
    CGImageRef imgRef = [self CGImageWithCorrectOrientation];
    CGSize originalSize = [UIImage originalSizeWithImageRef:imgRef];
    CGFloat height = [UIImage resizedHeightByWidth:width originalSize:originalSize];
    CGImageRelease(imgRef);
    return [self drawImageInBounds: CGRectMake(0, 0, width, height)];
}

- (UIImage *) resizedImageByHeight:  (NSUInteger) height
{
    CGImageRef imgRef = [self CGImageWithCorrectOrientation];
    CGSize originalSize = [UIImage originalSizeWithImageRef:imgRef];
    CGFloat width = [UIImage resizedWidthByHeight:height originalSize:originalSize];
    CGImageRelease(imgRef);
    return [self drawImageInBounds: CGRectMake(0, 0, width, height)];
}

- (UIImage *) resizedImageWithMinimumSize: (CGSize) size
{
    CGImageRef imgRef = [self CGImageWithCorrectOrientation];
    CGSize originalSize = [UIImage originalSizeWithImageRef:imgRef];
    size = [UIImage resizedSizeWithMinimumSize:size originalSize:originalSize];
    CGImageRelease(imgRef);
    return [self drawImageInBounds: CGRectMake(0, 0, size.width, size.height)];
}

- (UIImage *) resizedImageWithMaximumSize: (CGSize) size
{
    CGImageRef imgRef = [self CGImageWithCorrectOrientation];
    CGSize originalSize = [UIImage originalSizeWithImageRef:imgRef];
    size = [UIImage resizedSizeWithMaximumSize:size originalSize:originalSize];
    CGImageRelease(imgRef);
    return [self drawImageInBounds: CGRectMake(0, 0, size.width, size.height)];
}

- (UIImage *) drawImageInBounds: (CGRect) bounds
{
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, _interpolationQuality);
    [self drawInRect: bounds];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (UIImage*) croppedImageWithRect: (CGRect) rect
{
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, _interpolationQuality);
    CGRect drawRect = CGRectMake(-rect.origin.x, -rect.origin.y, self.size.width, self.size.height);
    CGContextClipToRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    [self drawInRect:drawRect];
    UIImage* subImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return subImage;
}

+(CGSize)originalSizeWithImageRef:(CGImageRef)imgRef
{
    return CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
}

+(CGSize)ratioSizeWithOriginalSize:(CGSize)original expectedSize:(CGSize)expected
{
    CGFloat widthRatio = expected.width / original.width;
    CGFloat heightRatio = expected.height / original.height;
    return CGSizeMake(widthRatio, heightRatio);
}

+ (CGFloat) resizedHeightByWidth: (NSUInteger) width originalSize:(CGSize)original
{
    CGFloat ratio = width/original.width;
    return round(original.height * ratio);
}

+ (CGFloat) resizedWidthByHeight: (NSUInteger) height originalSize:(CGSize)original
{
    CGFloat ratio = height/original.height;
    return round(original.width * ratio);
}

+ (CGSize) resizedSizeWithMaximumSize: (CGSize) size originalSize: (CGSize) original
{
    CGSize ratioSize = [UIImage ratioSizeWithOriginalSize:original expectedSize:size];
    CGFloat scaleRatio = ratioSize.width < ratioSize.height ? ratioSize.width : ratioSize.height;
    return CGSizeMake(round(original.width * scaleRatio), round(original.height * scaleRatio));
}

+ (CGSize) resizedSizeWithMinimumSize: (CGSize) size originalSize: (CGSize) original
{
    CGSize ratioSize = [UIImage ratioSizeWithOriginalSize:original expectedSize:size];
    CGFloat scaleRatio = ratioSize.width > ratioSize.height ? ratioSize.width : ratioSize.height;
    return CGSizeMake(round(original.width * scaleRatio), round(original.height * scaleRatio));
}

@end
