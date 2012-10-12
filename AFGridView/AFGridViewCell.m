//
//  AFGridViewCell.m
//  AFGridViewSample
//
//  Created by Sergii Kliuiev on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFGridViewCell.h"

@interface AFGridViewCell ()
@end

@implementation AFGridViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{   
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    CGPoint prevLocation = [touch previousLocationInView:self];
    if (location.x < 0 ||
        location.y < 0 ||
        location.x > self.bounds.size.width ||
        location.y > self.bounds.size.height) {
        return;
    }
    CGFloat dx = abs(location.x - prevLocation.x);
    CGFloat dy = abs(location.y - prevLocation.y);
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

@end
