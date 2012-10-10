//
//  AFGridView.m
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFGridView.h"

#define SIDE_OFFSET 1
#define CELL_OFFSET 1

@interface AFGridView()<AFGridViewDelegate, AFGridViewDataSource>

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
        
        //done for testing
        self.delegate = self;
        self.dataSource = self;
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
    return CGSizeMake((int)((self.bounds.size.width - SIDE_OFFSET * 2) / columnsCount),
                      (int)((self.bounds.size.height - SIDE_OFFSET * 2) / rowsCount));
    
}

- (CGRect)frameForCellWithRow:(NSInteger)row column:(NSInteger)column
{
    CGSize cellSize = [self sizeForCell];
    
    CGRect cellFrame = CGRectMake(SIDE_OFFSET * (1 + row) + cellSize.width * row,
                                  SIDE_OFFSET * (1 + column) + cellSize.height * column,
                                  cellSize.width,
                                  cellSize.height);
    
    return cellFrame;
}

- (void)reloadViews
{
    
    for (int i = 0; i < [self.dataSource numberOfColumnsInGridView:self]; i++) {
        
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

//testing stuff
//AFGridViewDataSource methods

- (NSInteger)numberOfColumnsInGridView:(AFGridView *)gridView
{
    return 4;
}

- (NSInteger)numberOfRowsInGridView:(AFGridView *)gridView
{
    return 1;
}

- (UIView *)gridView:(AFGridView *)gridView viewForCellAtIndex:(NSInteger)index
{
    UIView *cellView = [self dequeueRecycledCell];
    if (!cellView) {
        //cellView = [UIView alloc] initWithFrame:<#(CGRect)#>
    }
    
    return cellView;
}

@end
