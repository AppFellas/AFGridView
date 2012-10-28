//
//  AFGridViewCell.h
//  AFGridViewSample
//
//  Created by Sergii Kliuiev on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    moveRightDirection = 0,
    moveLeftDirection,
    moveUpDirection,
    moveDownDirection,
    moveNoneDirection
} eAFGridViewMoveDirection;

@protocol AFGridViewCellTapDelegate;

@interface AFGridViewCell : UIView
@property (assign, nonatomic) id<AFGridViewCellTapDelegate> tapDelegate;
@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) UIScrollView *scrollView;
@end