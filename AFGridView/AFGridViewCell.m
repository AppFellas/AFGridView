//
//  AFGridViewCell.m
//  AFGridViewSample
//
//  Created by Sergii Kliuiev on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFGridViewCell.h"

#define MIN_DISTANCE 10

@interface AFGridViewCell ()
@property (nonatomic, assign) CGPoint initialPosition;
@end

@implementation AFGridViewCell

#pragma mark - Initializing

- (id)init
{
    self = [super init];
    if (self) {
        [self setupCell];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupCell];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)setupCell
{
    self.clipsToBounds = YES;
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:_imageView];
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.textLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:_textLabel];
}

#pragma mark - Layouting subviews

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.frame = self.bounds;
    self.imageView.frame = self.bounds;
}


@end
