//
//  ViewController.m
//  Demo
//
//  Created by aidenluo on 14/05/2017.
//  Copyright © 2017 AidenLuo. All rights reserved.
//

#import "ViewController.h"
#import <LogoRecognizer/LogoRecognizer.h>

@interface ViewController ()<LRViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:false animated:animated];
}

- (IBAction)testSDKAction:(UIButton *)sender {
    LRViewController *vc = [LRViewController create];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:true];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)LRViewControllerViewDidLoad:(LRViewController *)controller
{
//    UIView *container = controller.overlayView;
//    container.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
//    UILabel *tip = [UILabel new];
//    tip.text = @"可在此View是自定义想要的效果";
//    tip.textColor = [UIColor whiteColor];
//    [tip sizeToFit];
//    tip.translatesAutoresizingMaskIntoConstraints = false;
//    [container addSubview:tip];
//    [tip.centerXAnchor constraintEqualToAnchor:container.centerXAnchor].active = true;
//    [tip.topAnchor constraintEqualToAnchor:container.topAnchor constant:10].active = true;
}

- (void)LRViewControllerViewWillAppear:(LRViewController *)controller
{
    
}

- (void)LRViewControllerViewDidAppear:(LRViewController *)controller
{
    
}

- (void)LRViewControllerViewWillDisappear:(LRViewController *)controller
{
    
}

- (void)LRViewControllerViewDidDisappear:(LRViewController *)controller
{
    
}

- (void)LRViewControllerRecognizeLogoSuccess:(LRViewController *)controller
{
    NSLog(@"识别成功");
}

- (void)LRViewControllerRecognizeLogoFail:(LRViewController *)controller
{
    NSLog(@"识别失败");
}

- (void)LRViewControllerPhotoSelectViewWillAppear:(LRViewController *)controller
{
    NSLog(@"调起相册");
}

- (void)LRViewControllerRecognizePhotoLogoSuccess:(LRViewController *)controller
{
    NSLog(@"相册识别成功");
}

- (void)LRViewControllerRecognizePhotoLogoFail:(LRViewController *)controller
{
    NSLog(@"相册识别失败");
}

@end
