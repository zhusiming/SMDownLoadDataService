//
//  SMDownloadDataService.h
//  SMDownloadDataService
//
//  Created by 朱思明 on 16/3/15.
//  Copyright © 2016年 朱思明. All rights reserved.
//

#import <Foundation/Foundation.h>
// 1.当前文件下载的根目录
#define kPath_base_downLoad_file [NSHomeDirectory() stringByAppendingFormat:@"/Documents/VideoDownLoad"]
#define kPath_complete_downLoad_file(subPath) [NSHomeDirectory() stringByAppendingFormat:@"/Documents/VideoDownLoad/%@",subPath]
#define kPath_downLoad_configureFile @"kConfigureFile.plist"

// 2.当前文件下载状态
typedef enum {
    SMDownloadDataServiceDownLoadTypeNone,      // 无状态
    SMDownloadDataServiceDownLoadTypeSuspend,   // 为停止下载状态
    SMDownloadDataServiceDownLoadTypeComplete,  // 为已经下载完成状态
    SMDownloadDataServiceDownLoadTypeDownLoad   // 为正在下载状态
}SMDownloadDataServiceDownLoadType;

// 3.本地配置文件数据字典key
// 01 添加下载完成地址
static const NSString *SMDownloadKey_LocalCompletePath = @"SMDownloadKey_LocalCompletePath";
// 02 添加临时下载地址
static const NSString *SMDownloadKey_LocalTemporaryPath = @"SMDownloadKey_LocalTemporaryPath";
// 03 添加当前下载状态
static const NSString *SMDownloadKey_DownLoadType = @"SMDownloadKey_DownLoadType";
// 04 当前完成进度
static const NSString *SMDownloadKey_DownLoadProgress = @"SMDownloadKey_DownLoadProgress";
// 05 添加文件网络下载地址
static const NSString *SMDownloadKey_httpUrlString = @"SMDownloadKey_httpUrlString";
// 06 添加文件当前大小
static const NSString *SMDownloadKey_DownLoadFileSize = @"SMDownloadKey_DownLoadFileSize";
// 07 获取当前文件总大小
static const NSString *SMDownloadKey_SumFileSize = @"SMDownloadKey_SumFileSize";


@protocol SMDownloadDataServiceDelegate <NSObject>

- (void)downloadProgress:(double)progress withVideoKey:(NSString *)videoKey;

@end

@interface SMDownloadDataService : NSObject<NSURLSessionDownloadDelegate>
{
    NSString *_congfigurePath;           // 配置文件的路径
    NSMutableDictionary *_configure;    // 所有下载文件的配置字典
    
    // 当前下载任务的字典
    NSMutableDictionary *_allDoadLoadTaskDic;
    
    // 当前下载配置对象
    NSURLSessionConfiguration * _sessionConfigure;
    NSURLSession * _session;
}
/*
 *  单例创建对象的方法
 */
+ (instancetype)shareInstance;


/**
 *  代理对象
 */
@property (nonatomic , weak) id <SMDownloadDataServiceDelegate> delegate;

/**
 *  添加下载任务
 */
- (void)addStartDownloadWithVideoKey:(NSString *)videoKey downLoadUrlString:(NSString *)downLoadUrlString;

/**
 *  暂停下载任务
 */
- (void)stopDownloadWithVideoKey:(NSString *)videoKey;

/**
 *  继续下载任务
 */
- (void)openDownloadWithVideoKey:(NSString *)videoKey;

/**
 *  删除下载任务
 */
- (void)deleteDownloadWithVideoKey:(NSString *)videoKey;

/**
 *  获取当前任务的状态
 */
- (NSDictionary *)getDownloadConfigureWithVideoKey:(NSString *)videoKey;

/**
 *  暂停所有任务
 */
- (void)stopAllDownload;

@end
