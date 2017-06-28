//
//  LRViewController.h
//  LogoRecognizer
//
//  Created by aidenluo on 14/05/2017.
//  Copyright © 2017 AidenLuo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@class LRViewController;
@protocol LRViewControllerDelegate <NSObject>

- (void)LRViewControllerViewDidLoad:(LRViewController *)controller;
- (void)LRViewControllerViewWillAppear:(LRViewController *)controller;
- (void)LRViewControllerViewDidAppear:(LRViewController *)controller;
- (void)LRViewControllerViewWillDisappear:(LRViewController *)controller;
- (void)LRViewControllerViewDidDisappear:(LRViewController *)controller;
- (void)LRViewControllerPhotoSelectViewWillAppear:(LRViewController *)controller;
- (void)LRViewControllerRecognizeLogoSuccess:(LRViewController *)controller;
- (void)LRViewControllerRecognizeLogoFail:(LRViewController *)controller;
- (void)LRViewControllerRecognizePhotoLogoSuccess:(LRViewController *)controller;
- (void)LRViewControllerRecognizePhotoLogoFail:(LRViewController *)controller;

@end

@interface LRViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) id<LRViewControllerDelegate> delegate;
@property (assign, atomic) BOOL enableRecognize; //是否启动识别，默认YES

+ (instancetype)create;

@end
