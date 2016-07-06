//
//  ViewController.m
//  SMDownLoadDataService
//
//  Created by 朱思明 on 16/7/5.
//  Copyright © 2016年 朱思明. All rights reserved.
//

#import "ViewController.h"

#define kfileNameOne @"file_one"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // 创建文件下载管理对象
    _downloadDataService = [SMDownloadDataService shareInstance];
    _downloadDataService.delegate = self;
    
    // 获取文件1的状态
    NSDictionary *oneDic = [_downloadDataService getDownloadConfigureWithVideoKey:kfileNameOne];
    // 根据状态设置信息
    if (oneDic != nil) {
        // 有下载信息
        // 1.设置下载状态
        SMDownloadDataServiceDownLoadType downLoadType = [oneDic[SMDownloadKey_DownLoadType] intValue];
        if (downLoadType == SMDownloadDataServiceDownLoadTypeNone) {
            [_oneButton setTitle:@"开始下载" forState:UIControlStateNormal];
        } else if (downLoadType == SMDownloadDataServiceDownLoadTypeSuspend) {
            [_oneButton setTitle:@"继续下载" forState:UIControlStateNormal];
        } else if (downLoadType == SMDownloadDataServiceDownLoadTypeComplete) {
            [_oneButton setTitle:@"删除下载" forState:UIControlStateNormal];
        } else if (downLoadType == SMDownloadDataServiceDownLoadTypeDownLoad) {
            [_oneButton setTitle:@"暂停下载" forState:UIControlStateNormal];
        }
        
        // 2.设置下载进度
        double progress = [oneDic[SMDownloadKey_DownLoadProgress] doubleValue];
        _progressOneLabel.text = [NSString stringWithFormat:@"%lf",progress];
        
    } else {
        [_oneButton setTitle:@"开始下载" forState:UIControlStateNormal];
         _progressOneLabel.text = @"0";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)oneButtonAction:(UIButton *)sender {
    // 获取当前文件下载的状态
    NSDictionary *oneDic = [_downloadDataService getDownloadConfigureWithVideoKey:kfileNameOne];
    SMDownloadDataServiceDownLoadType downLoadType = [oneDic[SMDownloadKey_DownLoadType] intValue];
    if (downLoadType == SMDownloadDataServiceDownLoadTypeNone) {
        // 无状态
        // 开始执行下载功能
        [_downloadDataService addStartDownloadWithVideoKey:kfileNameOne downLoadUrlString:@"http://www.cxwlbj.com/UploadFiles/1c/1/3.mp4"];
        [_oneButton setTitle:@"暂停下载" forState:UIControlStateNormal];
    } else if (downLoadType == SMDownloadDataServiceDownLoadTypeSuspend) {
        
        // 为停止下载状态
        // 开始执行继续下载功能
        [_downloadDataService openDownloadWithVideoKey:kfileNameOne];
        [_oneButton setTitle:@"暂停下载" forState:UIControlStateNormal];
    } else if (downLoadType == SMDownloadDataServiceDownLoadTypeComplete) {
        // 为已经下载完成状态
        // 按钮应为不可以，在这里面我们测试删除下载
        [_downloadDataService deleteDownloadWithVideoKey:kfileNameOne];
        _progressOneLabel.text = @"0";
        [_oneButton setTitle:@"开始下载" forState:UIControlStateNormal];
    } else if (downLoadType == SMDownloadDataServiceDownLoadTypeDownLoad) {
        // 为正在下载状态
        // 执行暂停
        [_downloadDataService stopDownloadWithVideoKey:kfileNameOne];
        [_oneButton setTitle:@"继续下载" forState:UIControlStateNormal];
    }
    
}

#pragma mark - SMDownloadDataServiceDelegate
- (void)downloadProgress:(double)progress withVideoKey:(NSString *)videoKey
{
    if ([videoKey isEqualToString:kfileNameOne]) {
         _progressOneLabel.text = [NSString stringWithFormat:@"%lf",progress];
        if (progress == 1) {
            [_oneButton setTitle:@"删除下载" forState:UIControlStateNormal];
        }
    }
}
@end
