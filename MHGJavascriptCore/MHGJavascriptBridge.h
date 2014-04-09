//
//  MHGJavascirptCore.h
//  MHGJavascriptCore
//
//  Created by 缪和光 on 9/04/2014.
//  Copyright (c) 2014 Hokuang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^MHGNativeCodeBlock)(NSArray *);

@interface MHGJavascriptBridge : NSObject<UIWebViewDelegate>

@property (nonatomic, unsafe_unretained) UIWebView *webView;

@property (nonatomic, strong) NSMutableDictionary *nativeBlocks;

- (BOOL)interceptRequest:(NSURLRequest *)request;

- (NSString *)callJavascriptFunction:(NSString *)functionName withParams:(NSArray *)params;

@end
