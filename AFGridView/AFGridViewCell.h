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
    moveDownDirection
} eAFGridViewMoveDirection;

@protocol AFGridViewCellDelegate;
@interface AFGridViewCell : UIView
@property (assign, nonatomic) id<AFGridViewCellDelegate> delegate;
@property (strong, nonatomic) UILabel *textLabel;
@property (weak, nonatomic) UIScrollView *scrollView;
@end

@protocol AFGridViewCellDelegate <NSObject>
- (void)gridViewCell:(AFGridViewCell *)cell willMoveToDirection:(eAFGridViewMoveDirection)direction;
@end