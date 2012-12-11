//
//  AFGridViewCell.m
//  AFGridViewSample
//
//  Created by Sergii Kliuiev on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFGridViewCell.h"

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
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_imageView];
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_textLabel];
}

@end
