//
//  AFGridView.m
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFGridView.h"

#define SIDE_OFFSET 1
#define CELL_OFFSET 2

@interface AFGridView()

@property (nonatomic, strong) NSMutableArray *visibleCells;
@property (nonatomic, strong) NSMutableArray *recycledCells;
@property (nonatomic, assign) NSInteger firstVisibleCellIndex;

@property (nonatomic, strong) NSMutableArray *testDataSource;

@end

@implementation AFGridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        //init properties
        self.visibleCells = [NSMutableArray new];
        self.recycledCells = [NSMutableArray new];
        _firstVisibleCellIndex = 0;
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        [self addSubview:_scrollView];
    }
    return self;
}

- (CGRect)frameForCellWithIndex:(NSInteger)index
{
    NSInteger rowsCount = [self.dataSource numberOfRowsInGridView:self];
    NSInteger columnsCount = [self.dataSource numberOfColumnsInGridView:self];
    
    NSInteger column = index / columnsCount;
    NSInteger row = index % rowsCount;
    
    return [self frameForCellWithRow:row column:column];
}

- (CGSize)sizeForCell
{
    NSInteger rowsCount = [self.dataSource numberOfRowsInGridView:self];
    NSInteger columnsCount = [self.dataSource numberOfColumnsInGridView:self];

    return CGSizeMake((int)((self.bounds.size.width - SIDE_OFFSET * 2 - (CELL_OFFSET * (columnsCount - 1))) / columnsCount),
                      (int)((self.bounds.size.height - SIDE_OFFSET * 2 - (CELL_OFFSET * (rowsCount - 1))) / rowsCount));
}

- (CGRect)frameForCellWithRow:(NSInteger)row column:(NSInteger)column
{
    CGSize cellSize = [self sizeForCell];

    CGRect cellFrame = CGRectMake(SIDE_OFFSET + column * CELL_OFFSET + cellSize.width * column,
                                  SIDE_OFFSET + row * CELL_OFFSET + cellSize.height * row,
                                  cellSize.width,
                                  cellSize.height);
    
    return cellFrame;
}

- (void)reloadGridView
{
    for (UIView *v in [self subviews]) {
        [v removeFromSuperview];
    }
    
    NSInteger columns = [self.dataSource numberOfColumnsInGridView:self];
    NSInteger rows = [self.dataSource numberOfRowsInGridView:self];
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
            NSInteger index = i * columns + j;
            UIView *cell = [self.dataSource gridView:self viewForCellAtIndex:index];
            cell.frame = [self frameForCellWithRow:i column:j];
            [self addSubview:cell];
        }
    }
    
    self.scrollView.frame = [self frameForScrollView];
}

- (CGRect)frameForScrollView
{
    return self.bounds;
}

- (UIView *)dequeueRecycledCell
{
    UIView *recycledCell = [self.recycledCells lastObject];
    [_recycledCells removeObject:recycledCell];
    return recycledCell;
}

@end
