//
//  OptionsPaneViewController.m
//  CGToss
//
//  Created by Blade on 8/28/14.
//  Copyright (c) 2014 Blade Chapman. All rights reserved.
//

#import "OptionsPaneViewController.h"

@interface OptionsPaneViewController ()

@end

@implementation OptionsPaneViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    [self.view setBackgroundColor:[UIColor colorWithRed:69/255.f green:97/255.f blue:169/255.f alpha:0.8f]];

    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onCloseButton:)];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:swipeGesture];
}

- (void)viewDidLoad
{


}

- (IBAction)onCloseButton:(id)sender {
    [self.delegate closeCalledFromSender:self];
}
- (IBAction)onEraserButton:(id)sender {
    [self.delegate eraserMode:YES];
}
- (IBAction)onDrawButton:(id)sender {
    [self.delegate eraserMode:NO];
}

@end
