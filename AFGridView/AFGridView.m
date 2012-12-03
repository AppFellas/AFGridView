//
//  AFGridView.m
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFGridView.h"
#import "AFGridViewCell.h"

#define FAKE_LENGTH 5000

#define MIN_DRAG_DISTANCE 10

#define AFScrollDirectionHorizontal(x) (x == moveRightDirection || x == moveLeftDirection)
#define AFScrollDirectionVertical(x) (x == moveUpDirection || x == moveDownDirection)

@interface AFGridView()<UIScrollViewDelegate>

@property (nonatomic, strong) UIView *cellContainerView;

//detecting scroll direction
@property (nonatomic, assign) eAFGridViewMoveDirection moveDirection;
@property (nonatomic, assign) CGPoint hitPoint;
@property (nonatomic, assign) CGPoint hitContentOffset;

//cell containers
@property (nonatomic, strong) NSMutableArray *fixedCells;
@property (nonatomic, strong) NSMutableArray *scrollingCells;

//container with possible cell indexes
@property (nonatomic, strong) NSMutableSet *possibleCellsSet;

//recycling cells container
@property (nonatomic, strong) NSMutableArray *recycledCells;

@end

@implementation AFGridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupGridView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupGridView];
    }
    return self;
}

- (void)setupGridView
{
    self.hitContentOffset = self.hitPoint = CGPointZero;
    
    self.fixedCells = [NSMutableArray new];
    self.recycledCells = [NSMutableArray new];
    
    self.moveDirection = moveNoneDirection;
    
    self.contentSize = CGSizeMake(FAKE_LENGTH, FAKE_LENGTH);
    self.cellContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
    [self addSubview:_cellContainerView];
    
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(tapAction:)];
    [self addGestureRecognizer:tapRecognizer];
    self.delegate = self;
}

- (void)tapAction:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self];
    AFGridViewCell *cell = [self cellWithPoint:point];
    
    if (cell &&
        self.gridDelegate &&
        [self.gridDelegate respondsToSelector:@selector(gridView:didSelectCell:)]) {
        [self.gridDelegate gridView:self
                      didSelectCell:cell];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *v = [super hitTest:point withEvent:event];
    
    //saving initial touch point and content offset
    self.hitContentOffset = self.contentOffset;
    self.hitPoint = point;
    
    return v;
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
    
    CGFloat sideOffset = [self.dataSource sideOffsetForGridView:self];
    CGFloat cellMargin = [self.dataSource cellMarginInGridView:self];
    
    return CGSizeMake((int)((self.bounds.size.width - sideOffset * 2 - (cellMargin * (columnsCount - 1))) / columnsCount),
                      (int)((self.bounds.size.height - sideOffset * 2 - (cellMargin * (rowsCount - 1))) / rowsCount));
}

- (CGRect)frameForCellWithRow:(NSInteger)row column:(NSInteger)column
{
    CGSize cellSize = [self sizeForCell];
    
    CGFloat sideOffset = [self.dataSource sideOffsetForGridView:self];
    CGFloat cellMargin = [self.dataSource cellMarginInGridView:self];
    
    CGRect cellFrame = CGRectMake(sideOffset + column * cellMargin + cellSize.width * column + self.contentOffset.x,
                                  sideOffset + row * cellMargin + cellSize.height * row + self.contentOffset.y,
                                  cellSize.width,
                                  cellSize.height);
    
    return cellFrame;
}

- (AFGridViewCell *)dequeCell
{
    AFGridViewCell *cell = [self.recycledCells lastObject];
    if (cell) [self.recycledCells removeObject:cell];
    return cell;
}

- (void)reloadGridView
{
    for (UIView *v in [self.cellContainerView subviews]) {
        [v removeFromSuperview];
    }
    
    //self.scrollingCells = [NSMutableArray new];
    self.fixedCells = [NSMutableArray new];
    self.possibleCellsSet = [NSMutableSet new];
    
    NSInteger columns = [self.dataSource numberOfColumnsInGridView:self];
    NSInteger rows = [self.dataSource numberOfRowsInGridView:self];
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
            NSInteger index = i * columns + j;
            AFGridViewCell *cell = [self.dataSource gridView:self
                                          viewForCellAtIndex:index];
            cell.index = index;
            [self.fixedCells addObject:cell];
            cell.index = index;
            cell.frame = [self frameForCellWithRow:i column:j];
            [self.cellContainerView addSubview:cell];
        }
    }
    
    [self layoutSubviews];
}

//detecting cells to scrol based on point and scroll direction

- (NSMutableArray *)cellsToScrollFromPoint:(CGPoint)fromPoint
                             moveDirection:(eAFGridViewMoveDirection)direction
{
    NSMutableArray *cellsToScroll = [NSMutableArray new];
    
    if (AFScrollDirectionVertical(direction)) {
        for (AFGridViewCell *gridCell in self.fixedCells) {
            if (gridCell.frame.origin.x <= fromPoint.x &&
                CGRectGetMaxX(gridCell.frame) >= fromPoint.x) {
                [cellsToScroll addObject:gridCell];
            }
        }
        
        [cellsToScroll sortUsingComparator:^NSComparisonResult(AFGridViewCell *cell1, AFGridViewCell *cell2) {
            if (cell1.frame.origin.y < cell2.frame.origin.y) return NSOrderedAscending;
            return NSOrderedDescending;
        }];
        
    } else {
        for (AFGridViewCell *gridCell in self.fixedCells) {
            if (gridCell.frame.origin.y <= fromPoint.y &&
                CGRectGetMaxY(gridCell.frame) > fromPoint.y) {
                [cellsToScroll addObject:gridCell];
            }
        }
        [cellsToScroll sortUsingComparator:^NSComparisonResult(AFGridViewCell *cell1, AFGridViewCell *cell2) {
            if (cell1.frame.origin.x < cell2.frame.origin.x) return NSOrderedAscending;
            return NSOrderedDescending;
        }];
    }
    
    return cellsToScroll;
}

- (AFGridViewCell *)cellWithPoint:(CGPoint)touchPoint
{
    for (AFGridViewCell *cell in self.fixedCells) {
        CGPoint point = [cell convertPoint:touchPoint fromView:self];
        BOOL isInside = [cell pointInside:point withEvent:nil];
        if (isInside) return cell;
    }
    
    return nil;
}

#pragma mark - Layout views

CGPoint prevPoint;

- (eAFGridViewMoveDirection)directionFromPoint:(CGPoint)fromPoint
                                       toPoint:(CGPoint)toPoint
{
    CGFloat dx = abs(fromPoint.x - toPoint.x);
    if (dx > MIN_DRAG_DISTANCE) {
        //horizontal movement
        if (toPoint.x < fromPoint.x) return moveRightDirection;
        else return moveLeftDirection;
    }
    
    CGFloat dy = abs(fromPoint.y - toPoint.y);
    if (dy > MIN_DRAG_DISTANCE) {
        //vertical movement
        if (toPoint.y < fromPoint.y) return moveDownDirection;
        else return moveUpDirection;
    }
    
    return moveNoneDirection;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.scrollingCells &&
        (self.hitContentOffset.x != 0 || self.hitContentOffset.y != 0)) {
        eAFGridViewMoveDirection direction = [self directionFromPoint:self.hitContentOffset
                                                              toPoint:self.contentOffset];
        if (direction != moveNoneDirection) {
            self.moveDirection = direction;
            self.scrollingCells = [self cellsToScrollFromPoint:self.hitPoint
                                                 moveDirection:direction];
            if (self.scrollingCells) {
                NSMutableSet *fixedCellsSet = [NSMutableSet set];
                self.possibleCellsSet = [NSMutableSet set];
                
                for (AFGridViewCell *cell in self.fixedCells) {
                    [fixedCellsSet addObject:[NSNumber numberWithInt:cell.index]];
                }
                
                NSInteger objectsCount = [self.dataSource numberOfObjectsInGridView:self];
                for (int i = 0; i < objectsCount; i++) {
                    [self.possibleCellsSet addObject:[NSNumber numberWithInt:i]];
                }
                
                for (AFGridViewCell *cell in self.scrollingCells) {
                    [self.fixedCells removeObject:cell];
                }
                
                [self.possibleCellsSet minusSet:fixedCellsSet];
            }
        }
    }
    
    [self recenterIfNecessary];
    
    CGFloat dx = self.contentOffset.x - prevPoint.x;
    CGFloat dy = self.contentOffset.y - prevPoint.y;
    
    for (AFGridViewCell *cell in self.fixedCells) {
        CGRect cellFrame = cell.frame;
        cellFrame.origin.x += dx;
        cellFrame.origin.y += dy;
        cell.frame = cellFrame;
    }
    
    prevPoint = self.contentOffset;
    
    if (self.moveDirection == moveNoneDirection || self.scrollingCells == nil) return;
    
    for (AFGridViewCell *cell in self.scrollingCells) {
        CGRect cellFrame = cell.frame;
        if (AFScrollDirectionHorizontal(self.moveDirection)) {
            cellFrame.origin.y += dy;
        } else {
            cellFrame.origin.x += dx;
        }
        cell.frame = cellFrame;
    }
    
    if (AFScrollDirectionHorizontal(self.moveDirection)) {
        [self tileCellsFromMinX:self.contentOffset.x
                         toMaxX:self.contentOffset.x + self.bounds.size.width];
    } else {
        [self tileCellsFromMinY:self.contentOffset.y
                         toMaxY:self.contentOffset.y + self.bounds.size.height];
    }
}

- (void)recenterIfNecessary {
    CGPoint currentOffset = [self contentOffset];
    
    CGFloat contentWidth = [self contentSize].width;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);
    
    if (AFScrollDirectionHorizontal(self.moveDirection) && (distanceFromCenter > (contentWidth / 4.0))) {
        self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
        for (AFGridViewCell *cell in self.scrollingCells) {
            CGPoint center = cell.center;
            center.x += (centerOffsetX - currentOffset.x);
            cell.center = center;
        }
    }
    
    CGFloat contentHeight = [self contentSize].height;
    CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0;
    distanceFromCenter = fabs(currentOffset.y - centerOffsetY);
    
    if (AFScrollDirectionVertical(self.moveDirection) && (distanceFromCenter > (contentHeight / 4.0))) {
        self.contentOffset = CGPointMake(self.contentOffset.x, centerOffsetY);
        for (AFGridViewCell *cell in self.scrollingCells) {
            CGPoint center = cell.center;
            center.y += (centerOffsetY - currentOffset.y);
            cell.center = center;
        }
    }
}

#pragma mark - UIScrollView delegate methods

- (void)recenterCells
{
    if ([self.scrollingCells count] > 2) {
        CGPoint adjust = CGPointZero;
        UIView *cell1 = [self.scrollingCells objectAtIndex:0];
        UIView *cell2 = [self.scrollingCells objectAtIndex:1];
        
        CGFloat sideOffset = [self.dataSource sideOffsetForGridView:self];
        
        if (AFScrollDirectionHorizontal(self.moveDirection)) {
            CGFloat xOffset;
            if (self.moveDirection == moveLeftDirection)
                xOffset = cell2.frame.origin.x - sideOffset;
            else
                xOffset = cell1.frame.origin.x - sideOffset;
            adjust.x = self.contentOffset.x - xOffset;
        } else {
            CGFloat yOffset;
            if (self.moveDirection == moveUpDirection)
                yOffset = cell2.frame.origin.y - sideOffset;
            else
                yOffset = cell1.frame.origin.y - sideOffset;
            adjust.y = self.contentOffset.y - yOffset;
        }
        
        blockRemoving = YES;
        
        __weak AFGridView *weakSelf = self;
        
        [UIView animateWithDuration:0.2
                         animations:^{
                             for (AFGridViewCell *cell in weakSelf.scrollingCells) {
                                 CGRect cellFrame = cell.frame;
                                 cellFrame.origin.x += adjust.x;
                                 cellFrame.origin.y += adjust.y;
                                 cell.frame = cellFrame;
                             }
                         } completion:^(BOOL finished) {
                             blockRemoving = NO;
                             [weakSelf resetHitValues];
                         }];
    }
    
}

- (void)resetHitValues
{
    self.hitPoint = self.hitContentOffset = CGPointZero;
    
    NSMutableArray *cellsToRemove = [NSMutableArray new];
    
    if (AFScrollDirectionHorizontal(self.moveDirection)) {
        CGFloat leftEdge = self.contentOffset.x;
        CGFloat rightEdge = self.contentOffset.x + self.bounds.size.width;
        
        for (AFGridViewCell *cell in self.scrollingCells) {
            if ((CGRectGetMaxX(cell.frame) <= leftEdge) ||
                (CGRectGetMinX(cell.frame) >= rightEdge)) {
                [cellsToRemove addObject:cell];
            }
        }
    } else {
        CGFloat topEdge = self.contentOffset.y;
        CGFloat bottomEdge = self.contentOffset.y + self.bounds.size.height;
        
        for (AFGridViewCell *cell in self.scrollingCells) {
            if ((CGRectGetMaxY(cell.frame) <= topEdge) ||
                (CGRectGetMinY(cell.frame) >= bottomEdge)) {
                [cellsToRemove addObject:cell];
            }
        }
    }

    for (AFGridViewCell *cell in cellsToRemove) {
        [cell removeFromSuperview];
        [self.scrollingCells removeObject:cell];
    }
    
    [self.fixedCells addObjectsFromArray:self.scrollingCells];
    self.scrollingCells = nil;
    self.moveDirection = moveNoneDirection;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self recenterCells];
}

- (void)killScroll
{
    CGPoint offset = self.contentOffset;
    [self setContentOffset:offset animated:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self recenterCells];
        //[self resetHitValues];
    }
    else {
        __weak AFGridView *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [weakSelf killScroll];
        });
    }
}

#pragma mark - Tiling methods

- (NSMutableSet *)detectPossibleCells
{
    NSMutableSet *allIndexes = [NSMutableSet set];
    NSInteger count = [self.dataSource numberOfObjectsInGridView:self];
    for (int i = 0; i < count; i++) {
        [allIndexes addObject:[NSNumber numberWithInt:i]];
    }
    
    NSMutableSet *visibleIndexes = [NSMutableSet set];
    
    for (AFGridViewCell *cell in self.scrollingCells) {
        [visibleIndexes addObject:[NSNumber numberWithInt:cell.index]];
    }
    
    for (AFGridViewCell *cell in self.fixedCells) {
        [visibleIndexes addObject:[NSNumber numberWithInt:cell.index]];
    }
    
    [allIndexes minusSet:visibleIndexes];
    
    return allIndexes;
}

- (AFGridViewCell *)getNextCell
{
    NSArray *possibleIndexes = [[self detectPossibleCells] allObjects];
    NSInteger index = [possibleIndexes[arc4random() % possibleIndexes.count] intValue];
        
    AFGridViewCell *newCell = [self.dataSource gridView:self
                                     viewForCellAtIndex:index];
    newCell.index = index;
    
    [self.cellContainerView addSubview:newCell];
    return newCell;
}

#pragma mark Horizontal tiling

- (CGFloat)placeNewCellOnRight:(CGFloat)rightEdge {
    AFGridViewCell *cellView = [self getNextCell];
    AFGridViewCell *otherCell = [self.scrollingCells lastObject];
    [self.scrollingCells addObject:cellView]; // add rightmost label at the end of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = rightEdge + [self.dataSource cellMarginInGridView:self];
    frame.origin.y = otherCell.frame.origin.y;
    frame.size = otherCell.frame.size;
    [cellView setFrame:frame];
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewCellOnLeft:(CGFloat)leftEdge {
    UIView *cellView = [self getNextCell];
    AFGridViewCell *otherCell = [self.scrollingCells lastObject];
    [self.scrollingCells insertObject:cellView atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = leftEdge - otherCell.frame.size.width - [self.dataSource cellMarginInGridView:self];
    frame.origin.y = otherCell.frame.origin.y;
    frame.size = otherCell.frame.size;
    [cellView setFrame:frame];
    
    return CGRectGetMinX(frame);
}

static BOOL blockRemoving;

- (void)tileCellsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX
{
    UIView *lastCell;
    UIView *firstCell;
    
    CGFloat cellMargin = [self.dataSource cellMarginInGridView:self];
    
    if ([self.scrollingCells count] == 0) {
        [self placeNewCellOnRight:minimumVisibleX];
    }
    
    lastCell = [self.scrollingCells lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastCell frame]);
    while (rightEdge + cellMargin < maximumVisibleX) {
        rightEdge = [self placeNewCellOnRight:rightEdge];
    }
    
    firstCell = [self.scrollingCells objectAtIndex:0];
    CGFloat leftEdge = CGRectGetMinX([firstCell frame]);
    while (leftEdge - cellMargin > minimumVisibleX) {
        leftEdge = [self placeNewCellOnLeft:leftEdge];
    }
    
    if (!blockRemoving) {
        NSMutableArray *cellsToRemove = [NSMutableArray new];
        for (AFGridViewCell *cell in self.scrollingCells) {
            if ((CGRectGetMaxX(cell.frame) < minimumVisibleX) ||
                (CGRectGetMinX(cell.frame) > maximumVisibleX)) {
                [cellsToRemove addObject:cell];
            }
        }
        
        for (AFGridViewCell *cell in cellsToRemove) {
            [self.scrollingCells removeObject:cell];
            if (_gridDelegate && [_gridDelegate respondsToSelector:@selector(gridView:cellWillDissappear:)]) {
                [_gridDelegate gridView:self
                     cellWillDissappear:cell];
            }
            [cell removeFromSuperview];
        }
    }
    
}

#pragma mark Vertical scrolling

- (CGFloat)placeNewCellOnBottom:(CGFloat)bottomEdge
{
    UIView *cellView = [self getNextCell];
    AFGridViewCell *otherCell = [self.scrollingCells objectAtIndex:0];
    
    [self.scrollingCells addObject:cellView]; // add rightmost label at the end of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = otherCell.frame.origin.x;
    frame.origin.y = bottomEdge + [self.dataSource cellMarginInGridView:self];
    frame.size = otherCell.frame.size;
    [cellView setFrame:frame];
    
    return CGRectGetMaxY(frame);
}

- (CGFloat)placeNewCellOnTop:(CGFloat)topEdge
{
    UIView *cellView = [self getNextCell];
    AFGridViewCell *otherCell = [self.scrollingCells objectAtIndex:0];
    
    [self.scrollingCells insertObject:cellView atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [cellView frame];
    frame.size = otherCell.frame.size;
    frame.origin.x = otherCell.frame.origin.x;
    frame.origin.y = topEdge - frame.size.height - [self.dataSource cellMarginInGridView:self];
    [cellView setFrame:frame];
    
    return CGRectGetMinY(frame);
}

- (void)tileCellsFromMinY:(CGFloat)minimumVisibleY toMaxY:(CGFloat)maximumVisibleY
{
    if ([self.scrollingCells count] == 0) {
        [self placeNewCellOnBottom:minimumVisibleY];
    }
    
    CGFloat cellMargin = [self.dataSource cellMarginInGridView:self];
    
    UIView *lastCell = [self.scrollingCells lastObject];
    CGFloat bottomEdge = CGRectGetMaxY([lastCell frame]);
    while (bottomEdge + cellMargin < maximumVisibleY) {
        bottomEdge = [self placeNewCellOnBottom:bottomEdge];
    }
    
    UIView *firstCell = [self.scrollingCells objectAtIndex:0];
    CGFloat topEdge = CGRectGetMinY([firstCell frame]);
    while (topEdge - cellMargin > minimumVisibleY) {
        topEdge = [self placeNewCellOnTop:topEdge];
    }
    
    if (!blockRemoving) {
        NSMutableArray *cellsToRemove = [NSMutableArray new];
        
        for (AFGridViewCell *cell in self.scrollingCells) {
            if ((CGRectGetMaxY(cell.frame) < minimumVisibleY) ||
                (CGRectGetMinY(cell.frame) > maximumVisibleY)) {
                [cellsToRemove addObject:cell];
            }
        }
        
        for (AFGridViewCell *cell in cellsToRemove) {
            [self.scrollingCells removeObject:cell];
            if (_gridDelegate && [_gridDelegate respondsToSelector:@selector(gridView:cellWillDissappear:)]) {
                [_gridDelegate gridView:self
                     cellWillDissappear:cell];
            }
            [cell removeFromSuperview];
        }
    }
}

@end
