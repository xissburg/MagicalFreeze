//
//  ViewController.h
//  MagicalFreeze
//
//  Created by xissburg on 7/24/13.
//  Copyright (c) 2013 xissburg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
