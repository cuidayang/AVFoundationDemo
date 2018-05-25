//
//  KYProgressView.m
//  KYVideoModule
//
//  Created by leoking870 on 2018/3/2.
//

#import "KYProgressView.h"

#define PI        3.141592655357989
#define TWOPI    (2 * PI)


@implementation KYProgressView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _trackColor = [UIColor colorWithRed:.5 green:.5 blue:.5 alpha:1];
    _trackWidth = 2;
    _progress = 0;
    _progressColor = [UIColor whiteColor];
    _progressWidth = 4;
    _progressTextFont = [UIFont systemFontOfSize:12];
    _progressTextColor = [UIColor whiteColor];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.bounds);
    CGContextSetStrokeColorWithColor(context, self.trackColor.CGColor);
    CGContextSetLineWidth(context, self.trackWidth);
    CGFloat centerX = CGRectGetWidth(self.frame) / 2;
    CGFloat width = centerX - MAX(self.progressWidth, self.trackWidth) / 2;
    CGContextAddArc(context, centerX, centerX, width, 0, TWOPI, 0);
    CGContextDrawPath(context, kCGPathStroke);


    CGContextSetStrokeColorWithColor(context, self.progressColor.CGColor);
    CGContextSetLineWidth(context, self.progressWidth);
    CGContextAddArc(context, centerX, centerX, width, -PI / 2, -PI / 2 + TWOPI * self.progress, 0);
    CGContextDrawPath(context, kCGPathStroke);

    CGContextSetTextDrawingMode(context, kCGTextFillStroke);//设置绘制方式
    NSString *string = [NSString stringWithFormat:@"%d%%", (int) (self.progress * 100)];
    CGSize size = [string boundingRectWithSize:self.bounds.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.progressTextFont} context:nil].size;
    CGContextSetFillColorWithColor(context, self.progressTextColor.CGColor);//填充色设置成蓝色，即文字颜色
    CGContextSetLineWidth(context, 0);//我们采用的是FillStroke的方式，所以要把边线去掉，否则文字会很粗
    [string drawAtPoint:CGPointMake(centerX - size.width / 2, centerX - size.height / 2) withAttributes:@{NSFontAttributeName: self.progressTextFont, NSForegroundColorAttributeName: self.progressTextColor}];
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;

    [self setNeedsDisplay];
}

@end
