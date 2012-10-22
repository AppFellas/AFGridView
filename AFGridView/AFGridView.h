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

@property (nonatomic, weak) id<AFGridViewDataSource> dataSource;
@property (nonatomic, weak) id<AFGridViewDelegate> gridDelegate;

- (void)reloadGridView;
@end


@protocol AFGridViewDataSource <NSObject>

- (NSInteger)numberOfRowsInGridView:(AFGridView *)gridView;
- (NSInteger)numberOfColumnsInGridView:(AFGridView *)gridView;
- (NSInteger)numberOfObjectsInGridView:(AFGridView *)gridView;

- (AFGridViewCell *)gridView:(AFGridView *)gridView
          viewForCellAtIndex:(NSInteger)index;

@optional
- (void)gridView:(AFGridView *)gridView
   configureCell:(AFGridViewCell *)cell
       withIndex:(NSInteger)index;

@end

@protocol AFGridViewDelegate <NSObject>
@optional
- (void)gridView:(AFGridView *)gridView didSelectCellAtIndex:(NSInteger)index;
@end