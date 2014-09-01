//
//  OptionsPaneViewController.h
//  CGToss
//
//  Created by Blade on 8/28/14.
//  Copyright (c) 2014 Blade Chapman. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OptionsPaneDelegate;

@interface OptionsPaneViewController : UIViewController

@property id<OptionsPaneDelegate>delegate;

@end

#pragma mark - Protocol
@protocol OptionsPaneDelegate <NSObject>

- (void)closeCalledFromSender:(OptionsPaneViewController *)sender;

@end