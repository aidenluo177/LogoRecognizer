//
//  LRViewController.m
//  LogoRecognizer
//
//  Created by aidenluo on 14/05/2017.
//  Copyright © 2017 AidenLuo. All rights reserved.
//

#import "LRRecognizer.h"
#import "LRViewController.h"
#import "LBXScanViewStyle.h"
#import "LBXScanView.h"

@interface LRViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIView *preview;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDevice *videoCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureConnection *videoConnection;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (assign, atomic) BOOL isRecoginzing;
@property (strong, nonatomic) LRRecognizer *recognizer;
@property (nonatomic,strong) LBXScanView* qRScanView;

@end

@implementation LRViewController

+ (instancetype)create
{
    return [[LRViewController alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.enableRecognize = true;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.recognizer = [LRRecognizer new];
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
    [self drawScanView];
    //不延时，可能会导致界面黑屏并卡住一会
    [self performSelector:@selector(startCamera) withObject:nil afterDelay:0.2];
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
    [self stopCamera];
    [_qRScanView stopScanAnimation];
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
    if (self.navigationController.childViewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:true];
    } else {
        [self dismissViewControllerAnimated:true completion:^{
            
        }];
    }
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
        self.isRecoginzing = true;
        [self.delegate LRViewControllerPhotoSelectViewWillAppear:self];
    }];
}

#pragma mark - AVFoundation Init

- (void)startCamera
{
    [LRViewController requestCameraPermission:^(BOOL granted) {
        if (granted) {
            [self initializeCamera];
        } else {
            [_qRScanView stopDeviceReadying];
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
        [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:true];
        [self.videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("ARVideoDataOutputQueue", DISPATCH_QUEUE_SERIAL)];
        if ([self.session canAddOutput:self.videoDataOutput]) {
            [self.session addOutput:self.videoDataOutput];
        } else {
            [self showAlert:@"Can't add video device output"];
            return;
        }
        self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    //if we had disabled the connection on capture, re-enable it
    if (![self.captureVideoPreviewLayer.connection isEnabled]) {
        [self.captureVideoPreviewLayer.connection setEnabled:YES];
    }
    
    [self.session startRunning];
    [_qRScanView stopDeviceReadying];
    [_qRScanView startScanAnimation];
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
    
    if (self.isRecoginzing || !self.enableRecognize) {
        return;
    }
    self.isRecoginzing = true;
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    BOOL recognizeSuccess = [self.recognizer recoginzeObjectIn:image isPhoto:false];
    if (recognizeSuccess) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate LRViewControllerRecognizeLogoSuccess:self];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate LRViewControllerRecognizeLogoFail:self];
        });
    }
    self.isRecoginzing = false;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:true completion:^{
        self.isRecoginzing = false;
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    id obj = info[UIImagePickerControllerOriginalImage];
    if (obj && [obj isKindOfClass:[UIImage class]]) {
        UIImage *image = obj;
        CGFloat imageWidth = image.size.width >= image.size.height ? image.size.width : image.size.height;
        CGFloat scale = MAX(MIN(imageWidth/640, 4),1);
        UIImage *resizeImage = [UIImage imageWithCGImage:image.CGImage scale:image.scale * scale orientation:image.imageOrientation];
        BOOL recognizeSuccess = [self.recognizer recoginzeObjectIn:resizeImage isPhoto:true];
        [picker dismissViewControllerAnimated:true completion:^{
            if (recognizeSuccess) {
                [self.delegate LRViewControllerRecognizePhotoLogoSuccess:self];
            } else {
                [self.delegate LRViewControllerRecognizePhotoLogoFail:self];
            }
            self.isRecoginzing = false;
        }];
    } else {
        [picker dismissViewControllerAnimated:true completion:^{
            [self.delegate LRViewControllerRecognizePhotoLogoFail:self];
            self.isRecoginzing = false;
        }];
    }
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

#pragma mark - Helper Method

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
    @autoreleasepool {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        UIImage *image = [UIImage imageWithCGImage:newImage];
        CGImageRelease(newImage);
        return image;
    }
}

#pragma mark --模仿支付宝
+ (LBXScanViewStyle*)ZhiFuBaoStyle
{
    //设置扫码区域参数
    LBXScanViewStyle *style = [[LBXScanViewStyle alloc]init];
    style.centerUpOffset = 60;
    style.xScanRetangleOffset = 80;
    
    if ([UIScreen mainScreen].bounds.size.height <= 480 )
    {
        //3.5inch 显示的扫码缩小
        style.centerUpOffset = 40;
        style.xScanRetangleOffset = 60;
    }
    
    style.notRecoginitonArea = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    style.photoframeAngleStyle = LBXScanViewPhotoframeAngleStyle_On;
    style.photoframeLineW = 4.0;
    style.photoframeAngleW = 20;
    style.photoframeAngleH = 20;
    style.colorAngle = [UIColor colorWithRed:0x00 green:0x7b/255.0 blue:0x4f/255.0 alpha:1.0];
    style.colorRetangleLine = style.colorAngle;
    style.isNeedShowRetangle = YES;
    style.anmiationStyle = LBXScanViewAnimationStyle_LineMove;
    
    //使用的支付宝里面网格图片
    UIImage *imgFullNet = [UIImage imageNamed:@"qrcode_scan_full_net" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    style.animationImage = imgFullNet;
    
    return style;
}

//绘制扫描区域
- (void)drawScanView
{
    if (!_qRScanView)
    {
        CGRect rect = self.view.frame;
        rect.origin = CGPointMake(0, 0);
        
        self.qRScanView = [[LBXScanView alloc]initWithFrame:rect style:[LRViewController ZhiFuBaoStyle]];
        
        [self.overlayView addSubview:_qRScanView];
    }
    [_qRScanView startDeviceReadyingWithText:@"相机启动中"];
}

@end
