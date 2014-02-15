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
    [self.selectedPhotos addObject:@"Image1.jpg"];
    
//    str=[[NSBundle mainBundle] pathForResource:@"Image2" ofType:@"jpg"];
//    xmlURL = [NSURL fileURLWithPath:str];
    [self.selectedPhotos addObject:@"Image2.jpg"];
    
//    str=[[NSBundle mainBundle] pathForResource:@"Image3" ofType:@"jpg"];
//    xmlURL = [NSURL fileURLWithPath:str];
    [self.selectedPhotos addObject:@"Image3.jpg"];
    
    // Get the path of the file to write
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"MyFile.mov"];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *error = nil;

    if ([fileMgr removeItemAtPath:appFile error:&error] != YES)
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);

    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:appFile] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    /*NSDictionary * compressionProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt: 1000000], AVVideoAverageBitRateKey,
                                            [NSNumber numberWithInt: 16], AVVideoMaxKeyFrameIntervalKey,
                                            AVVideoProfileLevelH264Main31, AVVideoProfileLevelKey,
                                            nil];
     */
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:1280], AVVideoWidthKey,
                                   [NSNumber numberWithInt:720], AVVideoHeightKey,
                                   //compressionProperties, AVVideoCompressionPropertiesKey,
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
    if (buffer == NULL)
    {
        CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    }
    //convert uiimage to CGImage.
    
    int frameCount = 0;
    double numberOfSecondsPerFrame = 6;
    NSUInteger fps = 30;
    double frameDuration = fps * numberOfSecondsPerFrame;

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
                NSLog(@"appending %d attemp %d\n", frameCount, j);
                
                //CMTime frameTime = CMTimeMake(frameCount*100,(int32_t) 10);
                CMTime frameTime = CMTimeMake(frameCount*frameDuration,(int32_t) fps);

                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                CVPixelBufferPoolRef bufferPool = adaptor.pixelBufferPool;
                NSParameterAssert(bufferPool != NULL);
                
                //[NSThread sleepForTimeInterval:0.05];
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
    //get the iOS version of the device
    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version < 6.0)
    {
        [videoWriter finishWriting];
        //NSLog (@"finished writing iOS version:%f",version);
        
    } else {
        [videoWriter finishWritingWithCompletionHandler:^(){
            //NSLog (@"finished writing iOS version:%f",version);
        }];
    }
 
    
    //OK now add an audio file to move file
//    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    //Get the saved audio song path to merge it in video
    //NSURL *audio_inputFileUrl ;
    //NSString *filePath = [self applicationDocumentsDirectory];
    //NSString *outputFilePath1 = [filePath stringByAppendingPathComponent:@"mySong.m4a"];
    //audio_inputFileUrl = [[NSURL alloc]initFileURLWithPath:outputFilePath1];
    
    // this is the video file that was just written above
//    NSURL    *video_inputFileUrl = [[NSURL alloc]initFileURLWithPath:appFile];
    
//    [NSThread sleepForTimeInterval:2.0];
    
    // create the final video output file as MOV file - may need to be MP4, but this works so far...
//    NSString *outputFilePath = [documentsDirectory stringByAppendingPathComponent:@"Slideshow_video.mov"];
//    NSURL    *outputFileUrl = [[NSURL alloc]initFileURLWithPath:outputFilePath];
    
//    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath])
//        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    
    //AVURLAsset get video without audio
//    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video_inputFileUrl options:nil];
//    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
//    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
//    [NSThread sleepForTimeInterval:3.0];
    
    //If audio song merged
   /* if (![self.appDelegate.musicFilePath isEqualToString:@"Not set"])
    {
        //*************************make sure all exception is off***********************
        AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:nil];
        CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        if (![audioAsset tracksWithMediaType:AVMediaTypeAudio].count == 0) {
            [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        }
    }
*/
    
    [NSThread sleepForTimeInterval:0.1];
    
    //AVAssetExportSession to export the video
/*    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    _assetExport.outputURL = outputFileUrl;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:^(void){
        switch (_assetExport.status) {
            case AVAssetExportSessionStatusCompleted:
//#if !TARGET_IPHONE_SIMULATOR
                [self saveMovieToCameraRoll:outputFileUrl];
//#endif
                //[self RemoveSlideshowImagesInTemp];
                //[self removeAudioFileFromDocumentsdirectory:outputFilePath1];
                //[self removeAudioFileFromDocumentsdirectory:videoOutputPath];
                NSLog(@"AVAssetExportSessionStatusCompleted");
                /*dispatch_async(dispatch_get_main_queue(), ^{
                    if (alrtCreatingVideo && alrtCreatingVideo.visible) {
                        [alrtCreatingVideo dismissWithClickedButtonIndex:alrtCreatingVideo.firstOtherButtonIndex animated:YES];
                        [databaseObj isVideoCreated:appDelegate.pro_id];
                        [self performSelector:@selector(successAlertView) withObject:nil afterDelay:0.0];
                    }
                });
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed:%@",_assetExport.error);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Canceled:%@",_assetExport.error);
                break;
            default:
                break;
        }
    }];
*/
    
    
    
    
    
    ///////////////////
    //NSString *videostr=[[NSBundle mainBundle] pathForResource:@"MyFile" ofType:@"mov"];
    NSURL *theURL = [NSURL fileURLWithPath:appFile];


//    MPMoviePlayerViewController *movieVC = [[MPMoviePlayerViewController alloc] initWithContentURL:theURL];
    
//    movieVC.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    
    
//    [self presentMoviePlayerViewControllerAnimated:movieVC];

    
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
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                        CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    //CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
    //                                    frameSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
    //                                  &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));

    //CGContextConcatCTM(context, CGAffineTransformMakeScale(0,0));
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
	NSLog(@"writing \"%@\" to photos album", outputURL);
	[library writeVideoAtPathToSavedPhotosAlbum:outputURL
								completionBlock:^(NSURL *assetURL, NSError *error) {
									if (error) {
										NSLog(@"assets library failed (%@)", error);
									}
									else {
										//[[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
										if (error)
											NSLog(@"Couldn't remove temporary movie file \"%@\"", outputURL);
									}
								}];
}
@end
