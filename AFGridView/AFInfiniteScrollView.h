//
//  AFInfiniteScrollView.h
//  AFGridViewSample
//
//  Created by Alex on 10/10/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    AFScrollViewDirectionVertical,
    AFScrollViewDirectionHorizontal
} AFScrollViewDirection;

@protocol AFInfiniteScrollViewDataSource;
@protocol AFInfiniteScrollViewDelegate;

@interface AFInfiniteScrollView : UIScrollView<UIScrollViewDelegate>

@property (nonatomic, weak) id<AFInfiniteScrollViewDataSource> dataSource;
@property (nonatomic, weak) id<AFInfiniteScrollViewDelegate> actionDelegate;

@property (nonatomic, assign) AFScrollViewDirection scrollDirection;

@end


@protocol AFInfiniteScrollViewDataSource <NSObject>
- (UIView *)infiniteScrollView:(AFInfiniteScrollView *)infiniteScrollView viewWithIndex:(NSInteger)index;
- (CGSize)sizeForCellInScrollView:(AFInfiniteScrollView *)infiniteScrollView;
- (CGFloat)cellPaddingInScrollView:(AFInfiniteScrollView *)infiniteScrollView;
- (NSInteger)numberOfCellsInScrollView:(AFInfiniteScrollView *)infiniteScrollView;
@end

@protocol AFInfiniteScrollViewDelegate <NSObject>
//TODO: describe delegate
@end