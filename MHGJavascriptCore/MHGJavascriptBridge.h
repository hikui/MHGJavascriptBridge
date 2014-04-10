//
//  MHGJavascirptCore.h
//  MHGJavascriptCore
//
//  Created by 缪和光 on 9/04/2014.
//  Copyright (c) 2014 Hokuang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^MHGNativeCodeBlock)(NSDictionary *paramDict);

@interface MHGJavascriptBridge : NSObject<UIWebViewDelegate>

@property (nonatomic, unsafe_unretained) UIWebView *webView;

- (BOOL)interceptRequest:(NSURLRequest *)request;

- (NSString *)callJavascriptFunction:(NSString *)functionName withParams:(NSArray *)params;

- (void)setBlockName:(NSString *)blockName block:(MHGNativeCodeBlock)block;

@end
