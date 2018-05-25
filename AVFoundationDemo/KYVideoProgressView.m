//
//  KYVideoProgressView.m
//  KYVideoModule
//
//  Created by leoking870 on 2018/5/23.
//

#import "KYVideoProgressView.h"
#import "KYProgressView.h"
#import "Masonry.h"
#import "UIView+DimView.h"
#import "UIColor+YYAdd.h"
@interface KYVideoProgressView ()
@property (nonatomic, strong) KYProgressView *progressView;
@property (nonatomic, strong) UILabel *messageLabel;
@end

@implementation KYVideoProgressView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 9;
        [self addSubview:self.progressView];
        self.progressView.backgroundColor = [UIColor clearColor];
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_top).offset(28);
            make.centerX.equalTo(self.mas_centerX);
            make.size.mas_equalTo(CGSizeMake(50, 50));
        }];
        
        [self addSubview:self.messageLabel];
        [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.mas_leading).offset(10);
            make.centerX.equalTo(self.mas_centerX);
            make.top.equalTo(self.progressView.mas_bottom).offset(28);
            make.bottom.equalTo(self.mas_bottom).offset(-28);
        }];
        
    }
    return self;
}

+ (KYVideoProgressView *)showProgressViewWithMessage:(NSString *)message {
    KYVideoProgressView *view = [[KYVideoProgressView alloc]init];
    view.message = message;
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    [window addDimBackgroundViewForView:view tapToExecute:^(){
        
    }];
    [window addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(window.mas_centerX);
        make.width.mas_equalTo(window.bounds.size.width - 100);
        make.centerY.equalTo(window.mas_centerY);
    }];
    view.hidden = YES;
    [window layoutIfNeeded];
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [window setDimViewAlpha:.3 forView:view];
        view.hidden = NO;
        [window layoutIfNeeded];
    } completion:nil];
    return view;
}

- (void)setMessage:(NSString *)message {
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineSpacing = 8;
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedString = [[NSAttributedString alloc]initWithString:message attributes:@{NSParagraphStyleAttributeName:paragraph}];
    _messageLabel.attributedText = attributedString;
}

- (NSString *)message {
    return _messageLabel.attributedText.string;
}

- (void)dismiss {
    [self layoutIfNeeded];
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.3 options:UIViewAnimationOptionCurveLinear animations:^{
        self.hidden = YES;
        [self.superview setDimViewAlpha:.0 forView:self];
    } completion:^(BOOL finished) {
        [self.superview removeDimViewForView:self];
        [self removeFromSuperview];
    }];
}


- (void)setProgress:(CGFloat)progress {
    _progressView.progress = progress;
}

- (CGFloat)progress {
    return _progressView.progress;
}
- (KYProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[KYProgressView alloc] init];
        _progressView.progressColor = [UIColor colorWithHexString:@"#FC3B6C"];
        _progressView.progressTextColor = [UIColor colorWithHexString:@"#FC3B6C"];
        _progressView.trackColor = [UIColor whiteColor];
        _progressView.progressWidth = 4;
    }
    return _progressView;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.font = [UIFont systemFontOfSize:14];
        _messageLabel.textColor = [UIColor colorWithHexString:@"#26263A"];
        _messageLabel.numberOfLines = 0;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _messageLabel;
}

@end
