//
//  AFGridView.h
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AFGridViewDataSource;
@protocol AFGridViewDelegate;

@interface AFGridView : UIView

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, weak) id<AFGridViewDataSource> dataSource;
@property (nonatomic, weak) id<AFGridViewDelegate> delegate;

- (void)reloadGridView;

@end


@protocol AFGridViewDataSource <NSObject>

- (NSInteger)numberOfRowsInGridView:(AFGridView *)gridView;
- (NSInteger)numberOfColumnsInGridView:(AFGridView *)gridView;
- (UIView *)gridView:(AFGridView *)gridView viewForCellAtIndex:(NSInteger)index;
- (NSInteger)numberOfObjectsInGridView:(AFGridView *)gridView;

@end

@protocol AFGridViewDelegate <NSObject>
@optional
- (void)gridView:(AFGridView *)gridView didSelectCellAtIndex:(NSInteger)index;
@end