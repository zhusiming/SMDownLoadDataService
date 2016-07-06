//
//  SMDownloadDataService.m
//  SMDownloadDataService
//
//  Created by 朱思明 on 16/3/15.
//  Copyright © 2016年 朱思明. All rights reserved.
//

#import "SMDownloadDataService.h"
#import <objc/runtime.h>

@implementation SMDownloadDataService

- (void)dealloc
{
    [self stopAllDownload];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 0.创建文件夹
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:kPath_base_downLoad_file attributes:nil];

        // 1.获取当前下载文件的配置信息
        _congfigurePath = [NSString stringWithFormat:@"%@/%@",kPath_base_downLoad_file,kPath_downLoad_configureFile];
        _configure = [[NSMutableDictionary alloc] initWithContentsOfFile:_congfigurePath];
        if (_configure == nil) {
            _configure = [[NSMutableDictionary alloc] init];
        }
        
        // 2.创建当前下载配置对象
        _sessionConfigure = [NSURLSessionConfiguration backgroundSessionConfiguration:@"back_sessionConfigure"];
        //[[[NSUserDefaults standardUserDefaults] objectForKey:kIs_allow_3G_play] boolValue];
//        _sessionConfigure.allowsCellularAccess = [[[NSUserDefaults standardUserDefaults] objectForKey:kIs_allow_3G_play] boolValue];
        // 创建session对象
        _session = [NSURLSession sessionWithConfiguration:_sessionConfigure delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        // 3.初始化当前所有未完成下载的任务字典
        _allDoadLoadTaskDic = [[NSMutableDictionary alloc] init];
        
        // 4.通过当前对象的配置信息开始初始化所有未完成任务
        for (NSString *videoKey in _configure.allKeys) {
            // 01 获取当前下载任务的配置信息
            NSMutableDictionary *videoDic = _configure[videoKey];
            // 02 获取当前任务的状态
            if ([videoDic[SMDownloadKey_DownLoadType] intValue] != SMDownloadDataServiceDownLoadTypeComplete) {
                // 当前不是完成状态
                // 03 添加当前下载状态
                [videoDic setObject:@(SMDownloadDataServiceDownLoadTypeSuspend) forKey:SMDownloadKey_DownLoadType];
                // 04 把配置文件写入到本地
                [_configure setObject:videoDic forKey:videoKey];
                [_configure writeToFile:_congfigurePath atomically:YES];
                // 05 获取已经下载完成的临时文件
//                NSData *l_data = [[NSData alloc] initWithContentsOfFile:kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalTemporaryPath])];
                // 06 获取当前文件的网络下载路径
                NSString *downLoadUrlString = videoDic[SMDownloadKey_httpUrlString];
                NSURL *url = [NSURL URLWithString:downLoadUrlString];
                // 07 开始创建任务
                NSURLSessionDownloadTask *downLoadTask = [_session downloadTaskWithURL:url];
                objc_setAssociatedObject(downLoadTask, [@"videoKey" UTF8String], videoKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [_allDoadLoadTaskDic setObject:downLoadTask forKey:videoKey];
                // 7.清楚本地写入的临时文件
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalTemporaryPath]) error:nil];
                // 08 暂停任务
                [downLoadTask suspend];
            }
        }
        
        
    }
    return self;
}

/*
 *  单例创建对象的方法
 */
+ (instancetype)shareInstance
{
    static SMDownloadDataService * downloadManagerInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManagerInstance = [[self alloc] init];
    });
    return downloadManagerInstance;
}

/**
 *  添加下载任务
 */
- (void)addStartDownloadWithVideoKey:(NSString *)videoKey downLoadUrlString:(NSString *)downLoadUrlString
{
    // 1.文件下载完成路径
//    NSString *filePath = [NSString stringWithFormat:@"%@/%@.mp4",kPath_base_downLoad_file,videoKey];
//    NSString *l_filePath = [NSString stringWithFormat:@"%@/%@",kPath_base_downLoad_file,videoKey];
    NSString *filePath = [NSString stringWithFormat:@"%@.mp4",videoKey];
    NSString *l_filePath = [NSString stringWithFormat:@"%@",videoKey];
    // 2.获取当前视频配置信息字典
    NSMutableDictionary *videoDic = [_configure objectForKey:videoKey];
    if (videoDic == nil) {
        // 1、添加下载配置文件
        videoDic = [[NSMutableDictionary alloc] init];
        // 01 添加下载完成地址
        [videoDic setObject:filePath forKey:SMDownloadKey_LocalCompletePath];
        // 02 添加临时下载地址
        [videoDic setObject:l_filePath forKey:SMDownloadKey_LocalTemporaryPath];
        // 03 添加当前下载状态
        [videoDic setObject:@(SMDownloadDataServiceDownLoadTypeDownLoad) forKey:SMDownloadKey_DownLoadType];
        // 04 当前完成进度
        [videoDic setObject:@0 forKey:SMDownloadKey_DownLoadProgress];
        // 05 添加文件网络下载地址
        [videoDic setObject:downLoadUrlString forKey:SMDownloadKey_httpUrlString];
        // 06 添加文件已下载大小
        [videoDic setObject:@0 forKey:SMDownloadKey_DownLoadFileSize];
        // 07 当前当前文件总大小
        [videoDic setObject:@0 forKey:SMDownloadKey_SumFileSize];
        // 2.把配置文件写入到本地
        [_configure setObject:videoDic forKey:[NSString stringWithFormat:@"%@",videoKey]];
        [_configure writeToFile:_congfigurePath atomically:YES];
        // 3.开始执行下载任务
        // 01 创建文件下载路径
        NSURL *url = [NSURL URLWithString:downLoadUrlString];
        // 创建下载任务
//        _sessionConfigure.discretionary = [[[NSUserDefaults standardUserDefaults] objectForKey:kIs_allow_3G_play] boolValue];
        NSURLSessionDownloadTask * downLoadTask = [_session downloadTaskWithURL:url];
        objc_setAssociatedObject(downLoadTask, [@"videoKey" UTF8String], videoKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_allDoadLoadTaskDic setObject:downLoadTask forKey:videoKey];
        // 开始执行下载任务
        [downLoadTask resume];
    }
}

/**
 *  暂停下载任务
 */
- (void)stopDownloadWithVideoKey:(NSString *)videoKey
{
    NSURLSessionDownloadTask *downLoadTask = [_allDoadLoadTaskDic objectForKey:videoKey];
    if (downLoadTask == nil) {
        return;
    }
    
    [downLoadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        // 1.记录当前信息
        NSMutableDictionary *videoDic = [_configure objectForKey:videoKey];
        if (videoDic == nil) {
            return ;
        }
        // 2.添加当前下载状态
        [videoDic setObject:@(SMDownloadDataServiceDownLoadTypeSuspend) forKey:SMDownloadKey_DownLoadType];
        // 3.把配置文件写入到本地
        [_configure setObject:videoDic forKey:videoKey];
        [_configure writeToFile:_congfigurePath atomically:YES];

        // 4.把已经下载好的文件保存到文本临时文件夹中
        BOOL isWrite = [resumeData writeToFile:kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalTemporaryPath]) atomically:NO];
        if (isWrite == YES) {
            NSLog(@"文件下载缓存本地成功");
        } else {
             NSLog(@"文件下载缓存本地失败");
        }
    }];
}

/**
 *  继续下载任务
 */
- (void)openDownloadWithVideoKey:(NSString *)videoKey
{
    // 1.获取当前暂停状态下的下载任务
    NSURLSessionDownloadTask *downLoadTask = [_allDoadLoadTaskDic objectForKey:videoKey];
    // 2.获取当前信息
    NSMutableDictionary *videoDic = [_configure objectForKey:videoKey];
 
    // 4.添加当前下载状态
    [videoDic setObject:@(SMDownloadDataServiceDownLoadTypeDownLoad) forKey:SMDownloadKey_DownLoadType];
    // 5.把配置文件写入到本地
    [_configure setObject:videoDic forKey:videoKey];
    [_configure writeToFile:_congfigurePath atomically:YES];
    // 6.获取已经下载完成的临时文件
    NSString *fileUrl = kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalTemporaryPath]);
    NSData *l_data = [[NSData alloc] initWithContentsOfFile:fileUrl];
    
//    _sessionConfigure.discretionary = [[[NSUserDefaults standardUserDefaults] objectForKey:kIs_allow_3G_play] boolValue];
    if (l_data == nil) {
        NSString *downLoadUrlString = videoDic[SMDownloadKey_httpUrlString];
        NSURL *url = [NSURL URLWithString:downLoadUrlString];
        downLoadTask = [_session downloadTaskWithURL:url];
    } else {
        downLoadTask = [_session downloadTaskWithResumeData:l_data];
    }
    objc_setAssociatedObject(downLoadTask, [@"videoKey" UTF8String], videoKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [_allDoadLoadTaskDic setObject:downLoadTask forKey:videoKey];
    // 7.清楚本地写入的临时文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalTemporaryPath]) error:nil];
    // 8.开始下载
    [downLoadTask resume];
}

/**
 *  删除下载任务
 */
- (void)deleteDownloadWithVideoKey:(NSString *)videoKey
{
    // 1.获取当前下载任务
    NSURLSessionDownloadTask *downLoadTask = [_allDoadLoadTaskDic objectForKey:videoKey];
    if (downLoadTask != nil) {
        // 2.取消下载任务
        [downLoadTask cancel];
        // 3.在内存中一处当前任务
        [_allDoadLoadTaskDic removeObjectForKey:videoKey];
    }
    // 4.获取当前信息
    NSMutableDictionary *videoDic = [_configure objectForKey:videoKey];
    // 5.清楚本地写入的临时文件和下载完成的
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalTemporaryPath]) error:nil];
    [fileManager removeItemAtPath:kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalCompletePath]) error:nil];
    // 6.移除配置文件
    [_configure removeObjectForKey:videoKey];
    [_configure writeToFile:_congfigurePath atomically:YES];

}

/**
 *  获取当前任务的状态
 */
- (NSDictionary *)getDownloadConfigureWithVideoKey:(NSString *)videoKey
{
    return _configure[videoKey];
}

/**
 *  暂停所有任务
 */
- (void)stopAllDownload
{
    for (NSString *key in _allDoadLoadTaskDic.allKeys) {
        [self stopDownloadWithVideoKey:key];
    }
}

#pragma mark - NSURLSessionDownloadDelegate
/*
 只有下载成功才调用的委托方法，在该方法中应该将下载成功后的文件移动到我们想要的目标路径：
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    // 2.记录当前信息
    NSString *videoKey = objc_getAssociatedObject(downloadTask, [@"videoKey" UTF8String]);
    if (videoKey == nil) {
        return;
    }
    NSMutableDictionary *videoDic = [_configure objectForKey:videoKey];
    // 01 添加当前下载状态
    [videoDic setObject:@(SMDownloadDataServiceDownLoadTypeComplete) forKey:SMDownloadKey_DownLoadType];
    // 3.把配置文件写入到本地
    [_configure setObject:videoDic forKey:videoKey];
    [_configure writeToFile:_congfigurePath atomically:YES];
    
    // 将临时文件剪切或者复制Caches文件夹
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // AtPath : 剪切前的文件路径
    // ToPath : 剪切后的文件路径
    [fileManager moveItemAtPath:location.path toPath:kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalCompletePath]) error:nil];
    // 在数组中移除当前下载任务
    [_allDoadLoadTaskDic removeObjectForKey:videoKey];
}

/* 执行下载任务时有数据写入 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSString *videoKey = objc_getAssociatedObject(downloadTask, [@"videoKey" UTF8String]);
    
    if (videoKey == nil) {
        [downloadTask suspend];
        return;
    }
    
    // 1.获得下载进度
    double progress = (double)totalBytesWritten / totalBytesExpectedToWrite;
    NSLog(@"%lf",progress);
    if ([_delegate respondsToSelector:@selector(downloadProgress:withVideoKey:)]) {
        [_delegate downloadProgress:progress withVideoKey:videoKey];
    }
    
    // 2.记录当前信息
    NSMutableDictionary *videoDic = [_configure objectForKey:videoKey];
    if (videoDic == nil) {
        return;
    }
    // 01 添加当前下载状态
    [videoDic setObject:@(SMDownloadDataServiceDownLoadTypeDownLoad) forKey:SMDownloadKey_DownLoadType];
    // 02 当前完成进度
    [videoDic setObject:@(progress) forKey:SMDownloadKey_DownLoadProgress];
    // 03 添加文件已下载大小
    [videoDic setObject:@(totalBytesWritten) forKey:SMDownloadKey_DownLoadFileSize];
    // 04 当前当前文件总大小
    [videoDic setObject:@(totalBytesExpectedToWrite) forKey:SMDownloadKey_SumFileSize];
    // 3.把配置文件写入到本地
    [_configure setObject:videoDic forKey:videoKey];
    [_configure writeToFile:_congfigurePath atomically:YES];
}

/*
 无论下载成功或失败都会调用的方法，类似于try-catch-finally中的finally语句块的执行。如果下载成功，那么error参数的值为nil，否则下载失败，可以通过该参数查看出错信息
 */
/*
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    // 获取当前下载对象
    NSURLSessionDownloadTask *downloadTask = (NSURLSessionDownloadTask *)task;
    if (error == nil) {
        // 2.记录当前信息
        NSString *videoKey = objc_getAssociatedObject(downloadTask, [@"videoKey" UTF8String]);
        NSMutableDictionary *videoDic = [_configure objectForKey:videoKey];
        // 01 添加当前下载状态
        [videoDic setObject:@(SMDownloadDataServiceDownLoadTypeComplete) forKey:SMDownloadKey_DownLoadType];
        // 3.把配置文件写入到本地
        [_configure setObject:videoDic forKey:videoKey];
        [_configure writeToFile:_congfigurePath atomically:YES];
        // 在数组中移除当前下载任务
        [_allDoadLoadTaskDic removeObjectForKey:videoKey];
    } else {
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            // 1.记录当前信息
            NSString *videoKey = objc_getAssociatedObject(downloadTask, [@"videoKey" UTF8String]);
            if (videoKey == nil) {
                return ;
            }
            NSMutableDictionary *videoDic = [_configure objectForKey:videoKey];
            // 2.添加当前下载状态
            [videoDic setObject:@(SMDownloadDataServiceDownLoadTypeSuspend) forKey:SMDownloadKey_DownLoadType];
            // 3.把配置文件写入到本地
            [_configure setObject:videoDic forKey:videoKey];
            [_configure writeToFile:_congfigurePath atomically:YES];
            // 4.把已经下载好的文件保存到文本临时文件夹中
            [resumeData writeToFile:kPath_complete_downLoad_file(videoDic[SMDownloadKey_LocalTemporaryPath]) atomically:YES];
            // 在数组中移除当前下载任务
            [_allDoadLoadTaskDic removeObjectForKey:videoKey];
        }];
    }
}
*/


@end
