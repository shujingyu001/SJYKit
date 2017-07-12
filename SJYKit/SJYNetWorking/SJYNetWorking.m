//
//  SJYNetWorking.m
//  SJYKit
//
//  Created by 舒靖宇 on 2017/6/11.
//  Copyright © 2017年 舒靖宇. All rights reserved.
//

#import "SJYNetWorking.h"
//#import <UIKit/UIKit.h>

#import "Reachability.h"

static SJYNetWorking * _SJYSession;

@interface SJYNetWorking()
//NSURLSessionDelegate,
//NSURLSessionDataDelegate,
//NSURLSessionTaskDelegate,
//NSURLSessionDownloadDelegate

//判断是不是有网络
@property(nonatomic,assign)BOOL isNetWork;

//图片下载队列线程
@property(nonatomic)NSOperationQueue * imageOperationQueue;

@end

@implementation SJYNetWorking

#pragma mark 初始化相关
// 为了使实例易于外界访问 我们一般提供一个类方法
// 类方法命名规范 share类名|default类名|类名
+(instancetype _Nullable)createDefault{
    //return _SJYSession;
    if(!_SJYSession){
        _SJYSession = [[super allocWithZone:NULL] init];
    }
    return  _SJYSession;
}

//严谨起见,重写
+(id) allocWithZone:(struct _NSZone *)zone
{
    return [SJYNetWorking createDefault];
}

-(id) copyWithZone:(NSZone *)zone
{
    return [SJYNetWorking createDefault];
}

-(id) mutablecopyWithZone:(NSZone *)zone
{
    return [SJYNetWorking createDefault];
}


#pragma mark 初始化各种数据
-(instancetype)init{
    if (self = [super init]) {
        //初始化图片下载队列(其他队列,可并发串行)
        _imageOperationQueue = [[NSOperationQueue alloc]init];
        //默认有网络
        self.isNetWork = YES;
        //图片下载默认队列并发数目为5
        self.imageQueueCount = 5;
        
        //创建网络监听
        [self createNetWorkState];
    }
    return self;
}

#pragma mark 网络监听
-(void)createNetWorkState{
    //注册通知监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    //开启监听
    Reachability *reach = [Reachability reachabilityWithHostName:@"SJYNetWorking"];
    [reach startNotifier];
    
}

//网络状态变化
-(void)reachabilityChanged:(NSNotification *)notification{
    Reachability *reach = [notification object];
    if([reach isKindOfClass:[Reachability class]]){
        //接收当前状态变化
        NetworkStatus status = [reach currentReachabilityStatus];
        //网络判断,发送通知，更新UI
        [self updateInterfaceWithReachability:status];
    }
}

//网络判断
-(void)updateInterfaceWithReachability:(NetworkStatus)status{
    if(status == NotReachable){
        _isNetWork = NO;
        NSLog(@"网络连接断开");
    }else if (status==ReachableViaWiFi) {
        _isNetWork = YES;
        NSLog(@"无线网络连接");
    }else if (status==ReachableViaWWAN){
        _isNetWork = YES;
        NSLog(@"数据网络连接");
    }
}

#pragma mark 数据请求方法
/**
 *  自定方式请求
 */
-(void)dataGetType:(NSString *)method UrlString:(NSString *)urlStr parameters:(id)parameters success:(void(^)(NSURLSessionDataTask * _Nonnull dataTask ,id _Nullable responseData))success failure:(void (^)(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError))failure{
    
    if ([method isEqualToString:@"GET"]) {
        //GET请求
        [self Get:urlStr parameters:parameters success:^(NSURLSessionDataTask * _Nonnull dataTask, id  _Nullable responseData) {
            success(dataTask,responseData);
            
        } failure:^(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError) {
            failure(dataTask,responseError);
        }];
        
    }else if ([method isEqualToString:@"POST"]){
        //POST请求
        [self Post:urlStr parameters:parameters success:^(NSURLSessionDataTask * _Nonnull dataTask, id  _Nullable responseData) {
            success(dataTask,responseData);
            
        } failure:^(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError) {
            failure(dataTask,responseError);
        }];
        
    }else{
        NSDictionary * userInfo = @{NSLocalizedDescriptionKey:@"method请求类型不能识别"};
        NSError * error = [NSError errorWithDomain:@"参数传输错误" code:331 userInfo:userInfo];
        
        failure(nil,error);
    }
    
    
}

/**
 *  开启get请求
 */
-(void)Get:(NSString *)urlStr parameters:(id)parameters success:(void(^)(NSURLSessionDataTask * _Nonnull dataTask ,id _Nullable responseData))success failure:(void (^)(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError))failure{
    //请求链接
    NSURL * URL = [NSURL URLWithString:urlStr];
    
    //创建请求体
    NSURLRequest * request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    //获取请求单例对象
    NSURLSession * session = [NSURLSession sharedSession];
    
    //4.根据会话对象创建一个Task(发送请求）
    /**
     * 第一个参数：请求对象
     * 第二个参数：completionHandler回调（请求完成【成功|失败】的回调）
     * data：响应体信息（期望的数据）
     * response：响应头信息，主要是对服务器端的描述
     * error：错误信息，如果请求失败，则error有值
     */
    NSURLSessionDataTask *dataTask;
    
    dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error == nil) {
            //数据请求成功
            success(dataTask,data);
            
        }else{
            //数据请求失败
            failure(dataTask,error);
        }
    }];
    //5.执行任务
    [dataTask resume];
}

/**
 *  开启post请求
 */
-(void)Post:(NSString *)urlStr parameters:(id)parameters success:(void(^)(NSURLSessionDataTask * _Nonnull dataTask ,id _Nullable responseData))success failure:(void (^)(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError))failure{
    
    //data是上传的数据
    NSData * PostData;
    
    //判断设置参数
    if ([parameters isKindOfClass:[NSString class]]) {
        PostData = [parameters dataUsingEncoding:NSUTF8StringEncoding];
    }else if([parameters isKindOfClass:[NSDictionary class]]){
        NSArray * keyArr = [parameters allKeys];
        NSString * dataStr;
        NSMutableArray * dictArr = [NSMutableArray array];
        for (NSString * key in keyArr) {
            [dictArr addObject:[NSString stringWithFormat:@"%@=%@",key,parameters[key]]];
        }
        dataStr = [dictArr componentsJoinedByString:@"&"];
        PostData = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    }else{
        NSDictionary * userInfo = @{NSLocalizedDescriptionKey:@"parameter参数类型不能识别(请输入字符串或者字典)"};
        NSError * error = [NSError errorWithDomain:@"参数传输错误" code:331 userInfo:userInfo];
        
        failure(nil,error);
        return;
    }
    
    
    //第一步，创建URL
    NSURL *url = [NSURL URLWithString:urlStr];
    
    //第二步，创建请求
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    //设置请求方式为POST，默认为GET,设置请求方式 方式为大写的 如 :POST GET
    [request setHTTPMethod:@"POST"];

    //把需要上传的data放进request里面
    [request setHTTPBody:PostData];
    
    //POST请求设置了body后需要单独设置请求超时时间
    [request setTimeoutInterval:10];
    
    //获取请求单例对象
    NSURLSession * session = [NSURLSession sharedSession];

    //4.根据会话对象创建一个Task(发送请求）
    /**
     * 第一个参数：请求对象
     * 第二个参数：completionHandler回调（请求完成【成功|失败】的回调）
     * data：响应体信息（期望的数据）
     * response：响应头信息，主要是对服务器端的描述
     * error：错误信息，如果请求失败，则error有值
     */
    NSURLSessionDataTask *dataTask;
    dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error == nil) {
            //数据请求成功
            success(dataTask,data);
            
        }else{
            //数据请求失败
            failure(dataTask,error);
        }

    }];
    //5.执行任务
    [dataTask resume];
    
}




/**
 *  最简单请求
 */
-(void)dataGetUrlString:(NSString *)urlStr success:(void(^)(NSURLSessionDataTask * _Nonnull dataTask ,id _Nullable responseData))success failure:(void (^)(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull responseError))failure{
    //初始化http
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    //默认get请求
    request.HTTPMethod = @"GET";
    //创建会话对象
    NSURLSession *session = [NSURLSession sharedSession];
    //创建请求 Task
    __block NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            //请求成功
            success(dataTask,data);
        }else{
            //请求失败
            failure(dataTask,error);
        }
    }];
    //发送请求
    [dataTask resume];
}

#pragma mark 上传数据请求


#pragma mark 图片队列请求
-(void)imageGetWithURL:(NSString *)imageURL callBack:(void(^)(NSData * _Nullable imageData,NSError * _Nullable error))imageBack{
    //    static NSUInteger currentQueueNum = 0;//当前队列线程数目
    //创建下载线程
    NSBlockOperation * imageBlockOp = [NSBlockOperation blockOperationWithBlock:^{
        
        [self startDownImageURL:[NSURL URLWithString:imageURL] completeWithBlock:^(NSData *data) {
            imageBack(data,nil);
        }];
    }];
    //队列中加入下载线程
    [_imageOperationQueue addOperation:imageBlockOp];
    
}

- (void)startDownImageURL:(NSURL *)imageURL completeWithBlock:(void(^)(NSData * data))data{
    //创建请求对象
    NSURLRequest * request = [NSURLRequest requestWithURL:imageURL];
    //创建网络请求对象
    NSURLSession * session = [NSURLSession sharedSession];
    //获取下载对象
    NSURLSessionDownloadTask * downLoadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"图片数据请求失败:%@",error);
            
        }else{
            //图片数据请求成功
            NSData * imageData = [NSData dataWithContentsOfURL:location options:NSDataReadingUncached error:&error];
            if (error) {
                NSLog(@"图片请求完成后读取失败:%@",error);
            }else{
                //图片数据读取成功
                data(imageData);
            }
        }
    }];
    //开始请求
    [downLoadTask resume];
}


#pragma mark 相关属性设置
//图片请求并发量
-(void)setImageQueueCount:(NSUInteger)imageQueueCount{
    _imageQueueCount = imageQueueCount;
    if (_imageOperationQueue) {
        _imageOperationQueue.maxConcurrentOperationCount = _imageQueueCount;
    }
}

@end
