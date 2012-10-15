//
//  AFGridView.m
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFGridView.h"
#import "AFGridViewCell.h"
#import "AFInfiniteScrollView.h"

#define SIDE_OFFSET 1
#define CELL_OFFSET 2

@interface AFGridView()<AFGridViewCellDelegate, AFInfiniteScrollViewDataSource, AFInfiniteScrollViewDelegate>

@property (nonatomic, strong) AFInfiniteScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *visibleCells;
@property (nonatomic, strong) NSMutableArray *recycledCells;
@property (nonatomic, assign) NSInteger firstVisibleCellIndex;
@property (nonatomic, strong) NSMutableArray *visibleCellIndexes;

@property (nonatomic, strong) NSMutableArray *testDataSource;

#pragma mark - ScrollView stuff

@property (nonatomic, strong) NSMutableArray *scrollViewCellIndexes;
@property (nonatomic, strong) NSMutableArray *possibleScrollCellIndexes;

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
        
        self.scrollView = [[AFInfiniteScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.actionDelegate = self;
        _scrollView.dataSource = self;
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
            AFGridViewCell *cell = [self.dataSource gridView:self viewForCellAtIndex:index];
            [self.visibleCells addObject:cell];
            cell.delegate = self;
            cell.tag = index;
            cell.frame = [self frameForCellWithRow:i column:j];
            [self addSubview:cell];
        }
    }
}

- (UIView *)dequeueRecycledCell
{
    UIView *recycledCell = [self.recycledCells lastObject];
    [_recycledCells removeObject:recycledCell];
    return recycledCell;
}

#pragma mark - AFGridViewCellDelegate methods

- (void)gridVIewCell:(AFGridViewCell *)cell willMoveToDirection:(eAFGridViewMoveDirection)direction
{
    CGRect scrollFrame = [self frameForScrollViewFromCell:cell moveDirection:direction];
    self.scrollView.frame = scrollFrame;
    self.scrollViewCellIndexes = [self scrollViewCellIndexesFromCell:cell
                                                       moveDirection:direction];
    
    _scrollView.backgroundColor = [UIColor yellowColor];
    
    if (direction == moveDownDirection || direction == moveUpDirection) {
        _scrollView.scrollDirection = AFScrollViewDirectionVertical;
    } else {
        _scrollView.scrollDirection = AFScrollViewDirectionHorizontal;
    }
    
    [self addSubview:_scrollView];
    
    cell.scrollView = self.scrollView;
}

- (CGRect)frameForScrollViewFromCell:(AFGridViewCell *)cell
                       moveDirection:(eAFGridViewMoveDirection)direction
{
    CGRect cellFrame = cell.frame;
    
    CGRect scrollFrame;
    
    if (direction == moveDownDirection || direction == moveUpDirection) {
        scrollFrame.origin.x = cellFrame.origin.x;
        scrollFrame.origin.y = 0;
        scrollFrame.size.width = cellFrame.size.width;
        scrollFrame.size.height = self.frame.size.height;
    } else {
        scrollFrame.origin.x = 0;
        scrollFrame.origin.y = cellFrame.origin.y;
        scrollFrame.size.width = self.frame.size.width;
        scrollFrame.size.height = cellFrame.size.height;
    }
    
    return scrollFrame;
}

NSInteger startedCellRow;
NSInteger startedCellColumn;

- (NSMutableArray *)scrollViewCellIndexesFromCell:(AFGridViewCell *)cell
                                    moveDirection:(eAFGridViewMoveDirection)direction
{
    NSMutableArray *scrollIndexes = [NSMutableArray new];
    
    NSInteger cellIndex = [self.visibleCells indexOfObject:cell];
    NSInteger rowsCount = [self.dataSource numberOfRowsInGridView:self];
    NSInteger columnsCount = [self.dataSource numberOfColumnsInGridView:self];
    
    startedCellRow = cellIndex / columnsCount;
    startedCellColumn = cellIndex % columnsCount;
    
    NSInteger currentIndex;
    AFGridViewCell *currentCell;
    
    if (direction == moveDownDirection || direction == moveUpDirection) {
        for (int i = 0; i < rowsCount; i++) {
            currentIndex = i * columnsCount + startedCellColumn;
            currentCell = [self.visibleCells objectAtIndex:currentIndex];
            [scrollIndexes addObject:[NSNumber numberWithInt:currentCell.tag]];
        }
    } else {
        for (int i = 0; i < columnsCount; i++) {
            currentIndex = startedCellRow * columnsCount + i;
            currentCell = [self.visibleCells objectAtIndex:currentIndex];
            [scrollIndexes addObject:[NSNumber numberWithInt:currentCell.tag]];
        }
    }
    
    NSMutableSet *gridCellIndexes = [NSMutableSet set];
    NSMutableSet *allCellIndexes = [NSMutableSet set];
    
    for (AFGridViewCell *c in self.visibleCells) {
        [gridCellIndexes addObject:[NSNumber numberWithInt:c.tag]];
    }
    
    NSInteger objectsCount = [self.dataSource numberOfObjectsInGridView:self];
    
    for (int i = 0; i < objectsCount; i++) {
        [allCellIndexes addObject:[NSNumber numberWithInt:i]];
    }
    
    [allCellIndexes minusSet:gridCellIndexes];

    [scrollIndexes addObjectsFromArray:[allCellIndexes allObjects]];
    
    return scrollIndexes;
}

#pragma mark - AFInfiniteScrollViewDataSource methods

- (UIView *)infiniteScrollView:(AFInfiniteScrollView *)infiniteScrollView
                 viewWithIndex:(NSInteger)index
{
    NSInteger convertIndex = [[self.scrollViewCellIndexes objectAtIndex:index] intValue];
    
    return [self.dataSource gridView:self viewForCellAtIndex:convertIndex];
}

- (CGSize)sizeForCellInScrollView:(AFInfiniteScrollView *)infiniteScrollView
{
    return [self sizeForCell];
}

- (CGFloat)cellPaddingInScrollView:(AFInfiniteScrollView *)infiniteScrollView
{
    return CELL_OFFSET;
}

- (NSInteger)numberOfCellsInScrollView:(AFInfiniteScrollView *)infiniteScrollView
{
    return _scrollViewCellIndexes.count;
}

#pragma mark - AFInfiniteScrollViewDelegate methods

- (void)infiniteScrollView:(AFInfiniteScrollView *)infiniteScrollView
 didStopScrollingWithCells:(NSArray *)cells
{
    NSInteger rowsCount = [self.dataSource numberOfRowsInGridView:self];
    NSInteger columnsCount = [self.dataSource numberOfColumnsInGridView:self];
    
    AFGridViewCell *currentCell;
    NSInteger currentIndex;
    
    if (infiniteScrollView.scrollDirection == moveDownDirection ||
        infiniteScrollView.scrollDirection == moveUpDirection) {
        for (int i = 0; i < rowsCount; i++) {
            currentIndex = i * columnsCount + startedCellColumn;
            currentCell = [self.visibleCells objectAtIndex:currentIndex];
            AFGridViewCell *scrollCell = [cells objectAtIndex:i];
            [self.dataSource gridView:self
                        configureCell:currentCell
                            withIndex:scrollCell.tag];
        }
    } else {
        for (int i = 0; i < columnsCount; i++) {
            currentIndex = startedCellRow * columnsCount + i;
            currentCell = [self.visibleCells objectAtIndex:currentIndex];
            AFGridViewCell *scrollCell = [cells objectAtIndex:i];
            [self.dataSource gridView:self
                        configureCell:currentCell
                            withIndex:scrollCell.tag];
        }
    }
    
    [infiniteScrollView removeFromSuperview];
}

@end
