//
//  MHGWebViewController.m
//  MHGJavascriptCore
//
//  Created by 缪 和光 on 14-4-10.
//  Copyright (c) 2014年 Hokuang. All rights reserved.
//

#import "MHGWebViewController.h"
#import "MHGJavascriptBridge.h"

@interface MHGWebViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) MHGJavascriptBridge *bridge;

@end

@implementation MHGWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _bridge = [[MHGJavascriptBridge alloc]init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bridge.webView = self.webView;
    [self.bridge setBlockName:@"hahaha" block:^(NSDictionary *dict) {
        NSLog(@"%@",dict);
    }];
    
    __weak typeof(self) weakMe = self;
    [self.bridge setBlockName:@"loadImage" block:^(NSDictionary *paramDict) {
        NSString *urlStr = paramDict[@"url"];
        if (urlStr.length == 0) {
            return;
        }
        NSURL *url = [NSURL URLWithString:urlStr];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSData *d = [NSData dataWithContentsOfURL:url];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
            NSString *path = paths[0];
            path = [path stringByAppendingPathComponent:@"result.jpg"];
            BOOL b = [d writeToFile:path atomically:YES];
            NSURL *fileURL = [NSURL fileURLWithPath:path];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakMe.bridge callJavascriptFunction:@"setImageWithURL" withParams:@[fileURL.absoluteString]];
            });
        });
    }];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"refresh" style:UIBarButtonItemStyleBordered target:self action:@selector(refresh)];
    
    NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:templatePath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refresh
{
    [self.bridge callJavascriptFunction:@"test" withParams:@[@{@"xx":@"yy"}]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [self.bridge interceptRequest:request];
    return YES;
}

@end
