//
//  ViewController.m
//  CGToss
//
//  Created by Blade on 8/24/14.
//  Copyright (c) 2014 Blade Chapman. All rights reserved.
//

#import "ViewController.h"
#import "DrawingView.h"
#import "OptionsPaneViewController.h"

@interface ViewController ()

@property UIScrollView *scrollView;
@property DrawingView *contentView;

@end

@implementation ViewController {
    OptionsPaneViewController *_menuViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _menuViewController = [[OptionsPaneViewController alloc] init];
    _menuViewController.delegate = self;

    CGRect screenSize = self.view.frame;
    _scrollView = [[UIScrollView alloc] initWithFrame:screenSize];
    _contentView = [[DrawingView alloc] initWithFrame:screenSize];
    _scrollView.scrollEnabled = NO;

    [_scrollView setMinimumZoomScale:1.0];
    [_scrollView setMaximumZoomScale:10.0];

    [_scrollView setDelegate:self];
    [self.view addSubview:_scrollView];
    [_scrollView addSubview:_contentView];

    [_scrollView setContentSize:screenSize.size];

    self.view.backgroundColor = [UIColor whiteColor];

    UIView *gestureView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, self.view.frame.size.height)];
    [gestureView setBackgroundColor:[UIColor clearColor]];
    UISwipeGestureRecognizer *openMenu = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openMenu:)];
    [openMenu setDirection:UISwipeGestureRecognizerDirectionRight];
    [gestureView addGestureRecognizer:openMenu];
    [self.view addSubview:gestureView];

}

#pragma mark - Gesture Recognizers
- (void)openMenu:(id)sender
{
    _menuViewController.view.center = CGPointMake(-_menuViewController.view.frame.size.width/2.f,
                                                  self.view.frame.size.height/2.f);
    [self.view addSubview:_menuViewController.view];
    [UIView animateWithDuration:0.25 animations:^{
        _menuViewController.view.center = CGPointMake(_menuViewController.view.frame.size.width/2.f, self.view.frame.size.height/2.f);
    } completion:^(BOOL finished) {

    }];
}

#pragma mark - Options Delegate
- (void)closeCalledFromSender:(OptionsPaneViewController*)sender
{
    [UIView animateWithDuration:0.25 animations:^{
        sender.view.center = CGPointMake(-sender.view.frame.size.width/2.f, self.view.frame.size.height/2.f);
    } completion:^(BOOL finished) {
        [sender.view removeFromSuperview];
    }];
}

#pragma mark - ScrollView Delegates
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _contentView;
}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(float)scale
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithBool:YES]
                     forKey:kCATransactionDisableActions];
    _contentView.layer.contentsScale = scale;
    [CATransaction commit];
}



@end
