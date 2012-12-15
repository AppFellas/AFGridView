//
//  AFGridView.h
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

@class AFGridViewCell;
@protocol AFGridViewDataSource;
@protocol AFGridViewDelegate;

@interface AFGridView : UIScrollView

@property (nonatomic, strong, readonly) NSMutableArray *fixedCells;

@property (nonatomic, weak) id<AFGridViewDataSource> dataSource;
@property (nonatomic, weak) id<AFGridViewDelegate> gridDelegate;

- (void)reloadGridView;
- (AFGridViewCell *)dequeCell;

@end


@protocol AFGridViewDataSource <NSObject>

- (NSInteger)numberOfRowsInGridView:(AFGridView *)gridView;
- (NSInteger)numberOfColumnsInGridView:(AFGridView *)gridView;
- (NSInteger)numberOfObjectsInGridView:(AFGridView *)gridView;
- (CGFloat)sideOffsetForGridView:(AFGridView *)gridView;
- (CGFloat)cellMarginInGridView:(AFGridView *)gridView;
- (CGSize)sizeForCellInGridView:(AFGridView *)gridView;

- (AFGridViewCell *)gridView:(AFGridView *)gridView
          viewForCellAtIndex:(NSInteger)index;

@optional
- (void)gridView:(AFGridView *)gridView
   configureCell:(AFGridViewCell *)cell
       withIndex:(NSInteger)index;

@end

@protocol AFGridViewDelegate <NSObject>
@optional
- (void)gridView:(AFGridView *)gridView didSelectCell:(AFGridViewCell *)cell;
- (void)gridView:(AFGridView *)gridView cellWillDissappear:(AFGridViewCell *)cell;
@end