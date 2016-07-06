//
//  ViewController.h
//  SMDownLoadDataService
//
//  Created by 朱思明 on 16/7/5.
//  Copyright © 2016年 朱思明. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMDownloadDataService.h"

@interface ViewController : UIViewController<SMDownloadDataServiceDelegate>
{
    SMDownloadDataService *_downloadDataService;
    __weak IBOutlet UILabel *_progressOneLabel;
    
    __weak IBOutlet UIButton *_oneButton;
    
    
}

- (IBAction)oneButtonAction:(UIButton *)sender;

@end

