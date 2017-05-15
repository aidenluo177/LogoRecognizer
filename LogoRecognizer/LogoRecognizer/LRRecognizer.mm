//
//  LRRecognizer.m
//  LogoRecognizer
//
//  Created by aidenluo on 15/05/2017.
//  Copyright © 2017 AidenLuo. All rights reserved.
//

#import "LRRecognizer.h"

@implementation LRRecognizer

- (BOOL)recoginzeObjectIn:(UIImage *)image
{
    if (!image) {
        assert(@"image can not be nil");
        return false;
    }
    NSLog(@"===Begin recoginzing===");
    NSString *cascadePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"cascade" ofType:@"xml"];
    std::vector<cv::Rect> recognizeRegions;
    cv::Mat scene;
    UIImageToMat(image, scene);
    cvtColor(scene, scene, CV_BGR2GRAY);
    equalizeHist(scene, scene);
    cv::CascadeClassifier cascade;
    cascade.load([cascadePath UTF8String]);
    cascade.detectMultiScale(scene, recognizeRegions);
    NSLog(@"===End recoginzing===");
    return recognizeRegions.size() > 0;
}

@end
