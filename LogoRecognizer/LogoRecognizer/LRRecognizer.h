//
//  LRRecognizer.h
//  LogoRecognizer
//
//  Created by aidenluo on 15/05/2017.
//  Copyright © 2017 AidenLuo. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LRRecognizer : NSObject

- (BOOL)recoginzeObjectIn:(UIImage *)image isPhoto:(BOOL)isPhoto;

@end
