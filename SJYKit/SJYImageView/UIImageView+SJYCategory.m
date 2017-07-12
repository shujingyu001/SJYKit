//
//  UIImageView+SJYCategory.m
//  SJYKit
//
//  Created by 舒靖宇 on 2017/6/20.
//  Copyright © 2017年 舒靖宇. All rights reserved.
//

#import "UIImageView+SJYCategory.h"
#import<CommonCrypto/CommonDigest.h>

#import "SJYNetWorking.h"

@implementation UIImageView (SJYCategory)

#pragma mark 图片下载处理
-(void)SJYGetNetworkImageWith:(NSString *)urlString placeholderImage:(UIImage *)placeImage options:(SJYImageStyle)imageStyle suffix:(NSString *)suffix callBackImage:(void(^)(UIImage * getedImage))image{
    
    //判断处理机制
    if (ImageStyleDefaults==imageStyle) {
        //先在本地判断，没有就先设置默认图然后下载完后重新设置并且储存沙盒缓存
        [self getImageDefaultsWithImageURL:urlString placeImage:placeImage Suffix:suffix callBackImage:^(UIImage * _Nullable imageBack) {
            image(imageBack);
        }];
        
    }else if (ImageStyleRefresh==imageStyle){
        //直接下载图片不询问缓存，下载好后在本地做好缓存
        [self getImageRefreshWithImageURL:urlString placeImage:placeImage Suffix:suffix callBackImage:^(UIImage * _Nullable imageBack) {
            image(imageBack);
        }];
        
    }else if (ImageStyleOnlySet==imageStyle){
        //仅仅下载图片设置，不缓存
        
        
    }else{
        NSLog(@"图片请求失败:图片加载方式options必须为枚举项目");
        image(nil);
    }
}

/**
 * 默认图片请求方式处理(先判断缓存,不存在就请求，完成后缓存)
 */
-(void)getImageDefaultsWithImageURL:(NSString *)urlString placeImage:(UIImage *)placeImage Suffix:(NSString *)suffixName callBackImage:(void(^)(UIImage * _Nullable imageBack))ImageBlock{
    //判断处理机制
    NSFileManager * manager = [NSFileManager defaultManager];
    //先判定是否缓存
    NSString * imagePath = [self getNSCachesDirectoryPathWithImageUrl:urlString andSuffixName:suffixName];
    if ([manager fileExistsAtPath:imagePath]) {
        NSLog(@"图片缓存存在,直接设置");
        self.image = [UIImage imageWithContentsOfFile:imagePath];
        ImageBlock([UIImage imageWithContentsOfFile:imagePath]);//返回图片
    }else{
        //图片没有缓存,异步请求
        NSLog(@"图片缓存不存在，先设置默认图片，然后准备下载");
        [self setPlaceImage:placeImage];
        //请求图片数据
        SJYNetWorking * NetManager = [SJYNetWorking createDefault];
        [NetManager imageGetWithURL:urlString callBack:^(NSData * _Nullable imageData, NSError * _Nullable error) {
            if (imageData) {
                NSLog(@"图片下载完成");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.image = [UIImage imageWithData:imageData];
                    ImageBlock([UIImage imageWithData:imageData]);
                });
                //缓存在本地沙盒
                [imageData writeToFile:imagePath atomically:YES];
                
            }else{
                NSLog(@"图片下载失败");
                ImageBlock(nil);
            }
        }];
    }
}

/**
 * 直接下载图片不询问缓存，下载好后在本地做好缓存
 */
-(void)getImageRefreshWithImageURL:(NSString *)urlString placeImage:(UIImage *)placeImage Suffix:(NSString *)suffixName callBackImage:(void(^)(UIImage * _Nullable imageBack))ImageBlock{
    //获取本地缓存路劲
    NSString * imagePath = [self getNSCachesDirectoryPathWithImageUrl:urlString andSuffixName:suffixName];
    [self setPlaceImage:placeImage];
    //直接异步请求图片，再存到缓存
    //请求图片数据
    SJYNetWorking * NetManager = [SJYNetWorking createDefault];
    [NetManager imageGetWithURL:urlString callBack:^(NSData * _Nullable imageData, NSError * _Nullable error) {
        if (imageData) {
            NSLog(@"图片下载完成");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = [UIImage imageWithData:imageData];
                ImageBlock([UIImage imageWithData:imageData]);
            });
            //缓存在本地
            [imageData writeToFile:imagePath atomically:YES];
        }else{
            NSLog(@"图片下载失败");
            ImageBlock(nil);
        }
    }];
}

/**
 * 仅仅下载图片设置，不缓存
 */
-(void)getImageOnlySetWithImageURL:(NSString *)urlString placeImage:(UIImage *)placeImage Suffix:(NSString *)suffixName callBackImage:(void(^)(UIImage * _Nullable imageBack))ImageBlock{
    [self setPlaceImage:placeImage];
    //直接异步请求图片，不缓存
        //请求图片数据
    SJYNetWorking * NetManager = [SJYNetWorking createDefault];
    [NetManager imageGetWithURL:urlString callBack:^(NSData * _Nullable imageData, NSError * _Nullable error) {
        if (imageData) {
            NSLog(@"图片下载完成");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = [UIImage imageWithData:imageData];
                ImageBlock([UIImage imageWithData:imageData]);
            });
        }else{
            NSLog(@"图片下载失败");
            ImageBlock(nil);
        }
    }];
}

#pragma mark 设置默认图片
-(void)setPlaceImage:(UIImage *)placeImage{
    //先设置默认图片
    if (placeImage) {
        self.image = placeImage;
    }
}

#pragma mark 图片缓存处理

/**
 * 图片缓存路径
 */
-(NSString * )getNSCachesDirectoryPathWithImageUrl:(NSString *)imageUrl andSuffixName:(NSString *)suffixName{
    
    //获取沙盒基础路径
    NSString * cachePath = [self getNSCachesDirectoryPath];
    if (!cachePath) {
        return nil;
    }
    NSLog(@"图片缓存路径已确认");
    suffixName = [self getImageSuffixName:suffixName];
    NSLog(@"图片后缀为:%@",suffixName);
    return [cachePath stringByAppendingString:[NSString stringWithFormat:@"/%@.%@",[self md5WithurlString:imageUrl],suffixName]];
    
}


/**
 * 图片文件夹沙盒路径
 */
-(NSString *)getNSCachesDirectoryPath{
    //首先,需要获取沙盒路径
    NSString * fileNmae = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString * directoryName;
    //创建文件夹路劲
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * string = [fileNmae stringByAppendingString:@"SJYImage/SJYImageCache"];//本人专属路劲
    
    //创建文件夹
    NSError * error;
    
    [manager createDirectoryAtPath:string withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"图片文件夹缓存路劲出错");
        return nil;
    }
    NSLog(@"图片缓存文件路劲已确认");
    directoryName = [fileNmae stringByAppendingString:@"SJYImage/SJYImageCache"];
    return directoryName;
}

/**
 * 图片后缀处理
 */
-(NSString *)getImageSuffixName:(NSString *)suffix{
    if (!suffix) {
        //默认返回png
        return @"png";
    }
    //将所有字符转换成小写
    suffix = [suffix lowercaseString];
    
    if (![suffix isEqualToString:@"png"]&&![suffix isEqualToString:@"jpg"]&&![suffix isEqualToString:@"gif"]) {
        //将大写字符转为小写
        return @"png";
    }else{
        return suffix;
    }
}

#pragma mark MD5加密 将url通过md5加密
-(NSString *)md5WithurlString:(NSString *)urlString{
    
    //1.首先将字符串转换成UTF-8编码, 因为MD5加密是基于C语言的,所以要先把字符串转化成C语言的字符串
    const char *fooData = [urlString UTF8String];
    
    //2.然后创建一个字符串数组,接收MD5的值
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    //3.计算MD5的值, 这是官方封装好的加密方法:把我们输入的字符串转换成16进制的32位数,然后存储到result中
    CC_MD5(fooData, (CC_LONG)strlen(fooData), result);
    /**
     第一个参数:要加密的字符串
     第二个参数: 获取要加密字符串的长度
     第三个参数: 接收结果的数组
     */
    //4.创建一个字符串保存加密结果
    NSMutableString *saveResult = [NSMutableString string];
    
    //5.从result 数组中获取加密结果并放到 saveResult中
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [saveResult appendFormat:@"%02x", result[i]];
    }
    /*
     x表示十六进制，%02X  意思是不足两位将用0补齐，如果多余两位则不影响
     NSLog("%02X", 0x888);  //888
     NSLog("%02X", 0x4); //04
     */
    return saveResult;
}

#pragma mark 计算缓存
+(unsigned long long)shareCache{
    // 总大小
    unsigned long long size = 0;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    //文件夹目录
    NSString * cacheStr = [[[UIImageView alloc]init] getNSCachesDirectoryPath];
    
    BOOL isDir = NO;//是不是文件目录
    BOOL exist = [manager fileExistsAtPath:cacheStr isDirectory:&isDir];
    
    // 判断路径是否存在
    if (!exist) return size;
    if (isDir) { // 是文件夹
        NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:cacheStr];
        for (NSString *subPath in enumerator) {
            NSString *fullPath = [cacheStr stringByAppendingPathComponent:subPath];
            size += [manager attributesOfItemAtPath:fullPath error:nil].fileSize;
            
        }
    }else{ // 是文件
        size += [manager attributesOfItemAtPath:cacheStr error:nil].fileSize;
    }
    return size;
}

#pragma mark 清空缓存
+(void)clearSJYImageCache{
    //文件夹目录
    NSString * cacheStr = [[[UIImageView alloc]init] getNSCachesDirectoryPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager removeItemAtPath:cacheStr error:NULL]) {
        NSLog(@"Removed successfully");
    }else{
        NSLog(@"Removed failure");
    }
}

@end
