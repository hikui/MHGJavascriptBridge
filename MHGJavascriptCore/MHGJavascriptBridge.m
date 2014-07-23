//
//  MHGJavascirptCore.m
//  MHGJavascriptCore
//
//  Created by 缪和光 on 9/04/2014.
//  Copyright (c) 2014 Hokuang. All rights reserved.
//

#import "MHGJavascriptBridge.h"

@interface MHGJavascripBridgeUtility : NSObject

+ (NSDictionary *)dictionaryWithURLArgumentsString:(NSString *)args;
+ (NSString *)URLArgumentsStringFromDictionary:(NSDictionary *)dict;

+ (NSString *)stringByURLEncoding:(NSString *)str;
+ (NSString *)stringByURLDecoding:(NSString *)str;

@end

@implementation MHGJavascripBridgeUtility

+ (NSDictionary *)dictionaryWithURLArgumentsString:(NSString *)args
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    NSArray *components = [args componentsSeparatedByString:@"&"];
    [components enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *stop) {
        if (component.length == 0) {
            return;
        }
        NSRange pos = [component rangeOfString:@"="];
        NSString *key;
        NSString *val;
        if (pos.location == NSNotFound) {
            key = [self stringByURLDecoding:component];
            val = @"";
        } else {
            key = [self stringByURLDecoding:[component substringToIndex:pos.location]];
            val = [self stringByURLDecoding:[component substringFromIndex:pos.location + pos.length]];
            if (!key) key = @"";
            if (!val) val = @"";
            [ret setObject:val forKey:key];
        }
    }];
    return ret;
}

+ (NSString *)URLArgumentsStringFromDictionary:(NSDictionary *)dict
{
    __block NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:dict.count];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *encodedKey = [self stringByURLEncoding:key];
        NSString *value = [dict objectForKey:key];
        NSString *encodedValue = [self stringByURLEncoding:[value description]];
        NSString *kvPair = [NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue];
        [arguments addObject:kvPair];
    }];
    return [arguments componentsJoinedByString:@"&"];
}

+ (NSString *)stringByURLEncoding:(NSString *)str
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)str,NULL,
                                                                                             (CFStringRef)@";/?:@&=$+{}<>,",kCFStringEncodingUTF8));
	return result;
}

+ (NSString *)stringByURLDecoding:(NSString *)str
{
    NSMutableString *outputStr = [NSMutableString stringWithString:str];
    [outputStr replaceOccurrencesOfString:@"+"
                               withString:@" "
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [outputStr length])];
    
    return [outputStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end

@interface MHGJavascriptBridge ()

@property (nonatomic, strong) NSMutableDictionary *nativeBlocks;

@end

@implementation MHGJavascriptBridge

- (id)init
{
    self = [super init];
    if (self) {
        _nativeBlocks = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (BOOL)interceptRequest:(NSURLRequest *)request
{
    // 格式：mhgjavascriptbridge://call_native_block/blockName?params={"x":"y","z":[1,3,4]}
    
    static NSString *scheme = @"mhgjavascriptbridge";
    NSURL *url = request.URL;
    if (![url.scheme isEqualToString:scheme]) {
        return NO;
    }
    if (![url.host isEqualToString:@"call_native_block"]) {
        return NO;
    }
    NSArray *pathComponents = url.pathComponents;
    NSString *blockName = pathComponents[1];
    MHGNativeCodeBlock block = self.nativeBlocks[blockName];
    if (block == NULL) {
        return NO;
    }
    NSString *queryString = nil;
    if (url.query) {
        queryString = [MHGJavascripBridgeUtility stringByURLDecoding:url.query];
        queryString = [queryString substringFromIndex:7];
    }
    if (queryString) {
        NSDictionary *nativeParams = [NSJSONSerialization JSONObjectWithData:[queryString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if (nativeParams == nil) {
            return NO;
        }
        block(nativeParams);
    }else{
        block(nil);
    }
    
    return YES;
}

- (NSString *)callJavascriptFunction:(NSString *)functionName withParams:(NSArray *)params
{
    NSMutableString *jsParamString = [[NSMutableString alloc]init];
    
    if (params == nil) {
        return [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@()",functionName]];
    }
    
    __block BOOL shouldContinue = YES;
    [params enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
            NSData *JSONData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
            NSString *JSONString = [[NSString alloc]initWithData:JSONData encoding:NSUTF8StringEncoding];
            if (JSONString == nil) {
                *stop = YES;
                shouldContinue = NO;
            }else{
                [jsParamString appendString:JSONString];
            }
        }else if([obj isKindOfClass:[NSString class]]){
            NSString *str = obj;
            NSMutableString *escapedString = [[NSMutableString alloc]initWithCapacity:str.length];
            for (int i=0; i<str.length; i++) {
                unichar c = [str characterAtIndex:i];
                if (c=='\"'||c=='\''||c=='\n'||c=='\\'||c=='\t'||c=='\r'||c=='\0'||c=='\a'||c=='\b'||c=='\f') {
                    [escapedString appendString:@"\\"];
                }
                [escapedString appendFormat:@"%c",c];
            }
            [jsParamString appendFormat:@"\"%@\"",escapedString];
        }else{
            [jsParamString appendFormat:@"%@",obj];
        }
        if (idx != params.count-1) {
            [jsParamString appendString:@","];
        }
    }];
    if (!shouldContinue) {
        return nil;
    }
    NSString *call = [NSString stringWithFormat:@"%@(%@)",functionName,jsParamString];
    return [self.webView stringByEvaluatingJavaScriptFromString:call];
}

- (void)setBlockName:(NSString *)blockName block:(MHGNativeCodeBlock)block
{
    self.nativeBlocks[blockName] = [block copy];
}

@end
