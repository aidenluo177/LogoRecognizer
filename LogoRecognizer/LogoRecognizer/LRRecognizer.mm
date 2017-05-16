//
//  LRRecognizer.m
//  LogoRecognizer
//
//  Created by aidenluo on 15/05/2017.
//  Copyright © 2017 AidenLuo. All rights reserved.
//

#import "LRRecognizer.h"

@interface LRRecognizer ()
{
    cv::CascadeClassifier* cascade;
}

@end

@implementation LRRecognizer

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *cascadePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"cascade" ofType:@"xml"];
        cascade = new cv::CascadeClassifier();
        cascade -> load([cascadePath UTF8String]);
    }
    return self;
}

- (void)dealloc
{
    delete cascade;
}

- (BOOL)recoginzeObjectIn:(UIImage *)image
{
    @autoreleasepool {
        if (!image) {
            assert(@"image can not be nil");
            return false;
        }
        std::vector<cv::Rect> recognizeRegions;
        cv::Mat scene;
        UIImageToMat(image, scene);
        cvtColor(scene, scene, CV_BGR2GRAY);
        equalizeHist(scene, scene);
        cascade -> detectMultiScale(scene, recognizeRegions);
        scene.release();
        return recognizeRegions.size() > 0;
    }
}

@end
