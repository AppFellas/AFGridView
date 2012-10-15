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
    }
    return self;
}

- (void)setupCell
{
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self addSubview:_textLabel];
}

#pragma mark - Handling touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_delegate) return;
    
    if (touches.count == 1) {
        self.initialPosition = [((UITouch *)touches.anyObject) locationInView:self];
    } else {
        self.initialPosition = CGPointZero;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_delegate) return;
    
    UITouch *touch = [touches anyObject];
    
    CGPoint location = [touch locationInView:self];
    CGPoint prevLocation = self.initialPosition;
    if (location.x < 0 ||
        location.y < 0 ||
        location.x > self.bounds.size.width ||
        location.y > self.bounds.size.height) {
        return;
    }
    CGFloat dx = abs(location.x - prevLocation.x);
    CGFloat dy = abs(location.y - prevLocation.y);
        
    if ((dx < MIN_DISTANCE) && (dy < MIN_DISTANCE)) return;
    
    self.initialPosition = location;
    
    if (dx > dy) {
        if (location.x - prevLocation.x > 0) {
            if (self.delegate != nil) {
                [self.delegate gridVIewCell:self willMoveToDirection:moveRightDirection];
            }
        } else {
            if (self.delegate != nil) {
                [self.delegate gridVIewCell:self willMoveToDirection:moveLeftDirection];
            }
        }
    } else {
        
        if (location.y - prevLocation.y > 0) {
            if (self.delegate != nil) {
                [self.delegate gridVIewCell:self willMoveToDirection:moveDownDirection];
            }
        } else {
            if (self.delegate != nil) {
                [self.delegate gridVIewCell:self willMoveToDirection:moveUpDirection];
            }
        }
    }
}

#pragma mark - Layouting subviews

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.frame = self.bounds;
}

@end
