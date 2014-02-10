//
//  ViewController.m
//  videocreator
//
//  Created by Michael Rizkalla on 2/8/14.
//  Copyright (c) 2014 yahoo. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *selectedPhotos;

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize)size;
- (void)saveMovieToCameraRoll:(NSURL *)outputURL;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.selectedPhotos = [NSMutableArray array];
    
    
    // Create the NSArray of urls
//    NSString *str=[[NSBundle mainBundle] pathForResource:@"Image1" ofType:@"jpg"];
//    NSURL *xmlURL = [NSURL fileURLWithPath:str];
//    [self.selectedPhotos addObject:@"Image1.jpg"];
    
//    str=[[NSBundle mainBundle] pathForResource:@"Image2" ofType:@"jpg"];
//    xmlURL = [NSURL fileURLWithPath:str];
//    [self.selectedPhotos addObject:@"Image2.jpg"];
    
//    str=[[NSBundle mainBundle] pathForResource:@"Image3" ofType:@"jpg"];
//    xmlURL = [NSURL fileURLWithPath:str];
    [self.selectedPhotos addObject:@"Image3.jpg"];
    
    // Get the path of the file to write
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"MyFile.mov"];
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:appFile] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    NSDictionary * compressionProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt: 1000000], AVVideoAverageBitRateKey,
                                            [NSNumber numberWithInt: 16], AVVideoMaxKeyFrameIntervalKey,
                                            AVVideoProfileLevelH264Main31, AVVideoProfileLevelKey,
                                            nil];
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:640], AVVideoWidthKey,
                                   [NSNumber numberWithInt:480], AVVideoHeightKey,
                                   compressionProperties, AVVideoCompressionPropertiesKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                        assetWriterInputWithMediaType:AVMediaTypeVideo
                                        outputSettings:videoSettings];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:nil];

    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //Video encoding
    
    CVPixelBufferRef buffer = NULL;
    
    //convert uiimage to CGImage.
    
    int frameCount = 0;
    CGSize size = CGSizeMake(640, 480);
    
    for(int i = 0; i<[self.selectedPhotos count]; i++)
    {
        CGImageRef imref = [[UIImage imageNamed:[self.selectedPhotos objectAtIndex:i]] CGImage];

        buffer = [self pixelBufferFromCGImage:imref andSize:size];
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                printf("appending %d attemp %d\n", frameCount, j);
                
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) 10);
                
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                CVPixelBufferPoolRef bufferPool = adaptor.pixelBufferPool;
                NSParameterAssert(bufferPool != NULL);
                
                [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok)
        {
            printf("error appending image %d times %d\n", frameCount, j);
        }
        frameCount++;
        CVBufferRelease(buffer);
    }
    
    [writerInput markAsFinished];
    //[videoWriter finishWriting];
    
    //NSString *videostr=[[NSBundle mainBundle] pathForResource:@"MyFile" ofType:@"mov"];
    NSURL *theURL = [NSURL fileURLWithPath:appFile];

/*
    MPMoviePlayerViewController *movieVC = [[MPMoviePlayerViewController alloc] initWithContentURL:theURL];
    
    movieVC.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    
    
    [self presentMoviePlayerViewControllerAnimated:movieVC];

    
    [movieVC.moviePlayer prepareToPlay];
    
    
    
    [movieVC.moviePlayer play];
*/    
    [self saveMovieToCameraRoll:theURL];

    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image andSize:(CGSize)frameSize
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeScale(0,0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)saveMovieToCameraRoll:(NSURL *)outputURL
{
    // save the movie to the camera roll
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	//NSLog(@"writing \"%@\" to photos album", outputURL);
	[library writeVideoAtPathToSavedPhotosAlbum:outputURL
								completionBlock:^(NSURL *assetURL, NSError *error) {
									if (error) {
										NSLog(@"assets library failed (%@)", error);
									}
									else {
										[[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
										if (error)
											NSLog(@"Couldn't remove temporary movie file \"%@\"", outputURL);
									}
								}];
}
@end
