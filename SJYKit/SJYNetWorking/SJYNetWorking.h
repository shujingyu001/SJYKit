//
//  SJYNetWorking.h
//  SJYKit
//
//  Created by 舒靖宇 on 2017/6/11.
//  Copyright © 2017年 舒靖宇. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SJYNetWorking : NSObject<NSURLConnectionDataDelegate>

//图片下载请求队列并发数目
@property(nonatomic,assign)NSUInteger imageQueueCount;


/**
 * 网络请求创建
 */
+(instancetype _Nullable)createDefault;


/**
 *  最简单请求
 */
-(void)dataGetUrlString:(NSString *_Nullable)urlStr success:(void(^_Nullable)(NSURLSessionDataTask * _Nonnull dataTask ,id _Nullable responseData))success failure:(void (^_Nullable)(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError))failure;

/**
 *  自定方式请求
 */
-(void)dataGetType:(NSString *_Nullable)method UrlString:(NSString *_Nullable)urlStr parameters:(id _Nullable )parameters success:(void(^_Nullable)(NSURLSessionDataTask * _Nonnull dataTask ,id _Nullable responseData))success failure:(void (^_Nullable)(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError))failure;

/**
 *  开启get请求
 */
-(void)Get:(NSString *_Nullable)urlStr parameters:(id _Nullable )parameters success:(void(^_Nullable)(NSURLSessionDataTask * _Nonnull dataTask ,id _Nullable responseData))success failure:(void (^_Nullable)(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError))failure;

/**
 *  开启post请求
 */
-(void)Post:(NSString *_Nullable)urlStr parameters:(id _Nullable )parameters success:(void(^_Nullable)(NSURLSessionDataTask * _Nonnull dataTask ,id _Nullable responseData))success failure:(void (^_Nullable)(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError))failure;

/**
 * 图片队列请求,默认并发量为5
 */
-(void)imageGetWithURL:(NSString *_Nullable)imageURL callBack:(void(^_Nullable)(NSData * _Nullable imageData,NSError * _Nullable error))imageBack;

@end
