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

@property (nonatomic, weak) id<AFGridViewDataSource> dateSource;
@property (nonatomic, weak) id<AFGridViewDelegate> delegate;

@end


@protocol AFGridViewDataSource <NSObject>

- (NSInteger)numberOfRowsInGridView:(AFGridView *)gridView;
- (NSInteger)numberOfColumnsInGridView:(AFGridView *)gridView;
- (UIView *)nextViewForGridView:(AFGridView *)gridView;

@end

@protocol AFGridViewDelegate <NSObject>

- (void)gridView:(AFGridView *)gridView didSelectCellAtIndex:(NSInteger)index;

@end