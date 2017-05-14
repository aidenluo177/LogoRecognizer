//
//  LRViewController.m
//  LogoRecognizer
//
//  Created by aidenluo on 14/05/2017.
//  Copyright © 2017 AidenLuo. All rights reserved.
//

#import "LRViewController.h"

@interface LRViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIView *preview;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *videoCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@end

@implementation LRViewController

+ (instancetype)create
{
    return [[LRViewController alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.preview = [[UIView alloc] initWithFrame:CGRectZero];
    self.preview.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:self.preview atIndex:0];
    [self.delegate LRViewControllerViewDidLoad:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:true animated:animated];
    [self.delegate LRViewControllerViewWillAppear:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startCamera];
    [self.delegate LRViewControllerViewDidAppear:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.delegate LRViewControllerViewWillDisappear:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.delegate LRViewControllerViewDidDisappear:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.preview.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

- (IBAction)backAction:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:true];
}

- (IBAction)photoAlbumAction:(UIButton *)sender {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [self showAlert:@"请授权使用相册"];
        return;
    }
    UIImagePickerController *pickerController = [UIImagePickerController new];
    pickerController.delegate = self;
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerController.allowsEditing = NO;
    pickerController.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:pickerController animated:true completion:^{
        
    }];
}

#pragma mark - AVFoundation Init

- (void)startCamera
{
    [LRViewController requestCameraPermission:^(BOOL granted) {
        if (granted) {
            [self initializeCamera];
        } else {
            [self showAlert:@"请授权使用摄像头"];
        }
    }];
}

- (void)initializeCamera
{
    if (!self.session) {
        self.session = [[AVCaptureSession alloc] init];
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
        CGRect bounds = self.preview.layer.bounds;
        self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.captureVideoPreviewLayer.bounds = bounds;
        self.captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        [self.preview.layer addSublayer:self.captureVideoPreviewLayer];
        self.videoCaptureDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
        NSError *error = nil;
        self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoCaptureDevice error:&error];
        if (!self.videoDeviceInput) {
            [self showAlert:[error localizedDescription]];
            return;
        }
        if([self.session canAddInput:self.videoDeviceInput]) {
            [self.session  addInput:self.videoDeviceInput];
            self.captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        } else {
            [self showAlert:@"Can't add video device input"];
            return;
        }
        self.videoDataOutput = [AVCaptureVideoDataOutput new];
        [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("ARVideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)];
        if ([self.session canAddOutput:self.videoDataOutput]) {
            [self.session addOutput:self.videoDataOutput];
        } else {
            [self showAlert:@"Can't add video device output"];
            return;
        }
    }
    
    //if we had disabled the connection on capture, re-enable it
    if (![self.captureVideoPreviewLayer.connection isEnabled]) {
        [self.captureVideoPreviewLayer.connection setEnabled:YES];
    }
    
    [self.session startRunning];
}

- (void)stopCamera
{
    [self.session stopRunning];
    self.session = nil;
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) return device;
    }
    return nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:true completion:^{
        
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSLog(@"%@",image);
    [picker dismissViewControllerAnimated:true completion:^{
        
    }];
}

#pragma mark - Permission

+ (void)requestCameraPermission:(void (^)(BOOL granted))completionBlock
{
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            // return to main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                if(completionBlock) {
                    completionBlock(granted);
                }
            });
        }];
    } else {
        completionBlock(YES);
    }
}

#pragma mark - Custom

- (void)showAlert:(NSString *)msg
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"msg" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:true completion:^{
            
        }];
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:^{
        
    }];
}

@end
