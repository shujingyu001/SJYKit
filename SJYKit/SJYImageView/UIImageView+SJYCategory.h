//
//  UIImageView+SJYCategory.h
//  SJYKit
//
//  Created by 舒靖宇 on 2017/6/20.
//  Copyright © 2017年 舒靖宇. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    ImageStyleDefaults=0,//先在本地判断，没有就先设置默认图然后下载完后重新设置并且储存沙盒缓存
    ImageStyleRefresh,//直接下载图片不询问缓存，下载好后在本地做好缓存
    ImageStyleOnlySet//仅仅下载图片设置，不缓存
    //其他请求方式遇到了再添加
} SJYImageStyle;


@interface UIImageView (SJYCategory)

/**
 *  根据缓存机制请求图片
 *  参数:
 *  urlString           图片链接
 *  placeholderImage    默认图(请求成功会被替换)
 *  options             图片请求机制(详情见枚举)
 *  suffix              图片文件保存后缀(常见png、jpg、gif),传nil或其他字符则默认png
 *  callBackImage       瞎写的回调代码块，反正自己看得懂，代码块优先级返回:本地缓存>网络请求图>nil
 */
-(void)SJYGetNetworkImageWith:(NSString *)urlString placeholderImage:(UIImage *)placeImage options:(SJYImageStyle)imageStyle suffix:(NSString *)suffix callBackImage:(void(^)(UIImage * getedImage))image;


/**
 *计算图片缓存
 */
+(unsigned long long)shareCache;

/**
 *清空缓存
 */
+(void)clearSJYImageCache;




@end
