//
//  DrawingView.h
//  DrawingTest
//
//  Created by Darel Chapman on 7/19/14.
//  Copyright (c) 2014 Blade Chapman. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DrawingView : UIView

@property (nonatomic) UIColor *strokeColor;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor;
- (void)initContext:(CGSize)size;
- (void)drawToCache;

- (void)setEraser:(BOOL)isOn;
- (void)clear;


@end


