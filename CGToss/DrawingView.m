//
//  DrawingView.m
//  DrawingTest
//
//  Created by Darel Chapman on 7/19/14.
//  Copyright (c) 2014 Blade Chapman. All rights reserved.
//

@import QuartzCore;
//#import "NSData+MPBase64.h"
#import "DrawingView.h"

@interface DrawingView()

@end

typedef struct {
    CGPoint firstPoint;
    CGPoint secondPoint;
} LineSegment;


@implementation DrawingView
{
    void *_cacheBitmap;
    CGContextRef _cacheContext;

    NSMutableArray *_points;
    LineSegment _lastLineSegment;

    CALayer *curLayer;

    UIDeviceOrientation _previousOrientation;
    BOOL _orientationChange;

    BOOL _clearContext;
}

static const CGFloat lineWidth = 1.0;

- (void)initialize
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(clear)];
    longPressGesture.minimumPressDuration = 1.0;
    [self addGestureRecognizer:longPressGesture];

    _cacheBitmap = NULL;
    _cacheContext = NULL;
    [self setOpaque:YES];
    self.strokeColor = [UIColor blackColor];
    self.multipleTouchEnabled = YES;
    _clearContext = YES;
    [self initContext:self.frame.size];

    self.layer.geometryFlipped = YES;
    NSLog(@"initialized");
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = backgroundColor;
        [self initialize];
    }
    return self;

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:234./255 green:234./255 blue:234./255 alpha:1.];
        [self initialize];
    }
    return self;
}

//triggered by nib
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.backgroundColor = [UIColor colorWithRed:234./255 green:234./255 blue:234./255 alpha:1.];
        [self initialize];
    }
    return self;

}
- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    if (_cacheBitmap != NULL) {
        free(_cacheBitmap);
    }
}

- (void)clear
{
//    _clearContext = YES;
//    [self initContext:self.frame.size];
//    [self setNeedsDisplay];
}

- (void) initContext:(CGSize)size {

    CGContextRelease(_cacheContext);

	int bitmapByteCount;
	int	bitmapBytesPerRow;

	// Declare the number of bytes per row. Each pixel in the bitmap is
	// represented by 4 bytes; 8 bits each of red, green, blue, and alpha.
	bitmapBytesPerRow = (size.width * 4);
	bitmapByteCount = (bitmapBytesPerRow * size.height);

	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
    if (_cacheBitmap != NULL) {
        free(_cacheBitmap);
    }
	_cacheBitmap = malloc(bitmapByteCount);
	if (_cacheBitmap == NULL) {
        return;
	}

	_cacheContext = CGBitmapContextCreate (_cacheBitmap, size.width, size.height, 8, bitmapBytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);


    CGFloat r,g,b,a;
    [self.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    CGContextSetRGBFillColor(_cacheContext, r, g, b, a);
    CGContextSetStrokeColorWithColor(_cacheContext, [self.backgroundColor CGColor]);
    CGContextFillRect(_cacheContext, (CGRect){CGPointZero, size});
}


- (void)layoutSubviews
{
    if (_orientationChange) {
        _orientationChange = NO;
        [self initContext:self.frame.size];
        [self drawToCache];
    }
}
- (void)didRotate:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

    if (UIDeviceOrientationIsLandscape(orientation) || UIDeviceOrientationIsPortrait(orientation)) {
        if (orientation == _previousOrientation)
            return;
        _orientationChange = YES;
        _previousOrientation = orientation;
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count > 1) {
        return;
    }

    if (!curLayer.superlayer) {
        curLayer = [CALayer layer];
        curLayer.frame = self.frame;
        curLayer.delegate = self;

        [self.layer addSublayer:curLayer];
        [curLayer setNeedsDisplay];
//        [self setNeedsDisplay];
    }

    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];

    _lastLineSegment = (LineSegment){CGPointMake(-1, -1), CGPointMake(-1, -1)};
    _points = [NSMutableArray array];
    [_points addObject:[NSValue valueWithCGPoint:pt]];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (touches.count > 1) {
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];
    [_points addObject:[NSValue valueWithCGPoint:pt]];
    [self drawToCache];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count > 1) {
        return;
    }

    if (curLayer.superlayer) {
        [curLayer removeFromSuperlayer];
    }

    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self];

    [_points addObject:[NSValue valueWithCGPoint:pt]];
}

- (NSMutableArray *)calculateSmoothLinePoints
{
    if([_points count] > 2) //The number of points will always be 3, enough to make a bezier curve interpolation
    {
        NSMutableArray *smoothedPoints = [NSMutableArray array];

        for (unsigned int i=2; i < [_points count]; ++i) {
            //core line
            CGPoint prev2 = [[_points objectAtIndex:i - 2] CGPointValue];
            CGPoint prev1 = [[_points objectAtIndex:i - 1] CGPointValue];
            CGPoint cur = [[_points objectAtIndex:i] CGPointValue];
            CGPoint midPoint1 = CGPointMake((prev1.x + prev2.x)/2, (prev1.y + prev2.y)/2);
            CGPoint midPoint2 = CGPointMake((cur.x + prev1.x)/2, (cur.y + prev1.y)/2);

            int segmentDistance = 2;
            float distance = hypotf(midPoint1.x - midPoint2.x, midPoint1.y - midPoint2.y);
            int numberOfSegments = MIN(32, MAX(floorf(distance / segmentDistance), 32));

            float t = 0.0f;
            float step = 1.0f/numberOfSegments;
            for (NSUInteger j = 0; j < numberOfSegments; j++) {
                CGPoint newPoint;

                //use quad curve equation to add interpolated points
                newPoint.x = ((midPoint1.x * powf(1 - t, 2)) + (prev1.x * (2.0f * (1 - t) * t))) + (midPoint2.x * (t * t));
                newPoint.y = ((midPoint1.y * powf(1 - t, 2)) + (prev1.y * (2.0f * (1 - t) * t))) + (midPoint2.y * (t * t));

                [smoothedPoints addObject:[NSValue valueWithCGPoint:newPoint]];

                t += step;
            }

            CGPoint finalPoint = midPoint2;
            [smoothedPoints addObject:[NSValue valueWithCGPoint:finalPoint]];

            [_points removeObjectsInRange:NSMakeRange(0, [_points count] - 2)];
            
            
            return smoothedPoints;
        }
    }
    
    return nil;
}

- (void) drawToCache
{
    UIColor *color = self.strokeColor;//[UIColor colorWithHue:hue saturation:0.7 brightness:1.0 alpha:1.0];
    CGContextSetStrokeColorWithColor(_cacheContext, [color CGColor]);
    CGContextSetFillColorWithColor(_cacheContext, [color CGColor]);
    CGContextSetLineCap(_cacheContext, kCGLineCapRound);
    CGContextSetLineWidth(_cacheContext, lineWidth);

    NSMutableArray *smoothedPoints = [self calculateSmoothLinePoints];

    for (int i = 1; i < [smoothedPoints count]; i++) {

        LineSegment perp1 = [self lineSegmentPerpendicularTo:(LineSegment){[[smoothedPoints objectAtIndex:i-1] CGPointValue],
                                                                            [[smoothedPoints objectAtIndex:i] CGPointValue]}
                                                                                ofRelativeLength:1.f];

        if (i == 1) {
            CGPoint center = [[smoothedPoints objectAtIndex:0] CGPointValue];
            float radius = sqrtf(len_sq(perp1.firstPoint, perp1.secondPoint));
            if (radius < lineWidth) {
                radius = lineWidth;
            }
            CGRect target = CGRectMake(center.x - radius/2, center.y - radius/2, radius, radius);
            CGContextFillEllipseInRect(_cacheContext, target);
        }

        if ((_lastLineSegment.firstPoint.x == -1 && _lastLineSegment.firstPoint.y == -1) ||
            (_lastLineSegment.firstPoint.x == 0 && _lastLineSegment.firstPoint.y == 0)) {
            CGContextMoveToPoint(_cacheContext, perp1.firstPoint.x, perp1.firstPoint.y);
            CGContextAddLineToPoint(_cacheContext, perp1.secondPoint.x, perp1.secondPoint.y);
            CGContextStrokePath(_cacheContext);
        }
        else {
            CGContextMoveToPoint(_cacheContext, _lastLineSegment.firstPoint.x, _lastLineSegment.firstPoint.y);
            CGContextAddLineToPoint(_cacheContext, perp1.firstPoint.x, perp1.firstPoint.y);

            CGContextAddLineToPoint(_cacheContext, perp1.firstPoint.x, perp1.firstPoint.y);
            CGContextAddLineToPoint(_cacheContext, perp1.secondPoint.x, perp1.secondPoint.y);

            CGContextAddLineToPoint(_cacheContext, perp1.secondPoint.x, perp1.secondPoint.y);
            CGContextAddLineToPoint(_cacheContext, _lastLineSegment.secondPoint.x, _lastLineSegment.secondPoint.y);
            CGContextClosePath(_cacheContext);
            CGContextDrawPath(_cacheContext, kCGPathFillStroke);


        }
        
        _lastLineSegment = perp1;
    }

    [curLayer setNeedsDisplayInRect:CGRectMake([[smoothedPoints lastObject] CGPointValue].x - self.frame.size.width/4,
                                           [[smoothedPoints lastObject] CGPointValue].y - self.frame.size.height/4,
                                           self.frame.size.width/2,
                                           self.frame.size.height/2)];
}

//- (void) drawRect:(CGRect)rect {
////    CGContextRef context = UIGraphicsGetCurrentContext();
////    CGImageRef cacheImage = CGBitmapContextCreateImage(_cacheContext);
////    CGContextDrawImage(context, self.bounds, cacheImage);
////    CGImageRelease(cacheImage);
//}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {

//    CGImageRef cacheImage = CGBitmapContextCreateImage(_cacheContext);
//    UIImage *contentImage = [[UIImage alloc] initWithCGImage:cacheImage];
//
//    layer.contents = (id)contentImage.CGImage;
//    CGImageRelease(cacheImage);

//        CGContextRef context = UIGraphicsGetCurrentContext();
        CGImageRef cacheImage = CGBitmapContextCreateImage(_cacheContext);
        CGContextDrawImage(ctx, self.bounds, cacheImage);
        CGImageRelease(cacheImage);
}

-(LineSegment) lineSegmentPerpendicularTo: (LineSegment)pp ofRelativeLength:(float)fraction
{
    CGFloat x0 = pp.firstPoint.x, y0 = pp.firstPoint.y, x1 = pp.secondPoint.x, y1 = pp.secondPoint.y;

    CGFloat dx, dy;
    dx = x1 - x0;
    dy = y1 - y0;

    CGFloat xa, ya, xb, yb;
    xa = x1 + (.5f - sinf(dy)/2);
    ya = y1 - (.5f - sinf(dx)/2);
    xb = x1 - (.5f - sinf(dy)/2);
    yb = y1 + (.5f - sinf(dx)/2);

    return (LineSegment){ (CGPoint){xa, ya}, (CGPoint){xb, yb} };

}

#pragma mark - C Arguments
float len_sq(CGPoint p1, CGPoint p2)
{
    float dx = p2.x - p1.x;
    float dy = p2.y - p1.y;
    return dx * dx + dy * dy;
}

float clamp(float value, float lower, float higher)
{
    if (value < lower) return lower;
    if (value > higher) return higher;
    return value;
}


@end
