//
//  AFGridView.m
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFGridView.h"
#import "AFGridViewCell.h"

#define SIDE_OFFSET 1
#define CELL_OFFSET 2
#define FAKE_LENGTH 5000

#define MIN_DRAG_DISTANCE 5

#define AFScrollDirectionHorizontal(x) (x == moveRightDirection || x == moveLeftDirection)
#define AFScrollDirectionVertical(x) (x == moveUpDirection || x == moveDownDirection)

@interface AFGridView()<UIScrollViewDelegate>

@property (nonatomic, strong) UIView *cellContainerView;
@property (nonatomic, assign) eAFGridViewMoveDirection moveDirection;
@property (nonatomic, assign) CGPoint hitPoint;
@property (nonatomic, assign) CGPoint hitContentOffset;

@property (nonatomic, strong) NSMutableArray *fixedCells;
@property (nonatomic, strong) NSMutableArray *scrollingCells;
@property (nonatomic, strong) NSMutableSet *possibleCellsSet;

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
    self.fixedCells = [NSMutableArray new];
    self.recycledCells = [NSMutableArray new];
    
    self.moveDirection = moveNoneDirection;
    
    self.contentSize = CGSizeMake(FAKE_LENGTH, FAKE_LENGTH);
    self.cellContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
    [self addSubview:_cellContainerView];
    
    self.showsHorizontalScrollIndicator = YES;
    self.showsVerticalScrollIndicator = YES;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(tapAction:)];
    [self addGestureRecognizer:tapRecognizer];
    self.delegate = self;
}

- (void)tapAction:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self];
    AFGridViewCell *cell = [self cellWithPoint:point];
    [self.gridDelegate gridView:self
                  didSelectCell:cell];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *v = [super hitTest:point withEvent:event];
    
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
    
    return CGSizeMake((int)((self.bounds.size.width - SIDE_OFFSET * 2 - (CELL_OFFSET * (columnsCount - 1))) / columnsCount),
                      (int)((self.bounds.size.height - SIDE_OFFSET * 2 - (CELL_OFFSET * (rowsCount - 1))) / rowsCount));
}

- (CGRect)frameForCellWithRow:(NSInteger)row column:(NSInteger)column
{
    CGSize cellSize = [self sizeForCell];
    
    CGRect cellFrame = CGRectMake(SIDE_OFFSET + column * CELL_OFFSET + cellSize.width * column + self.contentOffset.x,
                                  SIDE_OFFSET + row * CELL_OFFSET + cellSize.height * row + self.contentOffset.y,
                                  cellSize.width,
                                  cellSize.height);
    
    return cellFrame;
}

- (AFGridViewCell *)dequeCell
{
    AFGridViewCell *cell = [self.recycledCells lastObject];
    if (!cell) {
        cell = [[AFGridViewCell alloc] init];
    } else {
        [self.recycledCells removeObject:cell];
    }
    return cell;
}

- (void)reloadGridView
{
    for (UIView *v in [self.cellContainerView subviews]) {
        [v removeFromSuperview];
    }
    
    NSInteger columns = [self.dataSource numberOfColumnsInGridView:self];
    NSInteger rows = [self.dataSource numberOfRowsInGridView:self];
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
            NSInteger index = i * columns + j;
            AFGridViewCell *cell = [self dequeCell];//[self.dataSource gridView:self viewForCellAtIndex:index];
            [self.dataSource gridView:self
                        configureCell:cell
                            withIndex:index];
            [self.fixedCells addObject:cell];
            cell.tag = index;
            cell.frame = [self frameForCellWithRow:i column:j];
            [self.cellContainerView addSubview:cell];
        }
    }
}

- (NSMutableArray *)cellsToScrollFromCell:(AFGridViewCell *)cell
                            moveDirection:(eAFGridViewMoveDirection)direction
{
    NSMutableArray *cellsToScroll = [NSMutableArray new];
    
    if (AFScrollDirectionVertical(direction)) {
        for (AFGridViewCell *gridCell in self.fixedCells) {
            if (gridCell.frame.origin.x < cell.center.x &&
                CGRectGetMaxX(gridCell.frame) > cell.center.x) {
                [cellsToScroll addObject:gridCell];
            }
        }
    } else {
        for (AFGridViewCell *gridCell in self.fixedCells) {
            if (gridCell.frame.origin.y < cell.center.y &&
                CGRectGetMaxY(gridCell.frame) > cell.center.y) {
                [cellsToScroll addObject:gridCell];
            }
        }
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

CGPoint prevPoint;

#pragma mark - Layout views

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
            AFGridViewCell *touchCell = [self cellWithPoint:self.hitPoint];
            self.scrollingCells = [self cellsToScrollFromCell:touchCell
                                                moveDirection:direction];
            
            NSMutableSet *fixedCellsSet = [NSMutableSet set];
            self.possibleCellsSet = [NSMutableSet set];
            
            for (AFGridViewCell *cell in self.fixedCells) {
                [fixedCellsSet addObject:[NSNumber numberWithInt:cell.tag]];
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
    
    if (self.moveDirection == moveNoneDirection) return;
    
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
    
    if (distanceFromCenter > (contentWidth / 4.0)) {
        self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
    }
    
    CGFloat contentHeight = [self contentSize].height;
    CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0;
    distanceFromCenter = fabs(currentOffset.y - centerOffsetY);
    
    if (distanceFromCenter > (contentHeight / 4.0)) {
        self.contentOffset = CGPointMake(self.contentOffset.x, centerOffsetY);
    }
}

#pragma mark - UIScrollView delegate methods

- (void)recenterCells
{
    if ([self.scrollingCells count] > 2) {
        CGPoint adjust = CGPointZero;
        UIView *cell1 = [self.scrollingCells objectAtIndex:0];
        UIView *cell2 = [self.scrollingCells objectAtIndex:1];
        
        CGFloat sideOffset = SIDE_OFFSET;
        
        if (AFScrollDirectionHorizontal(self.moveDirection)) {
            CGFloat xOffset;
            
            if (fabs(cell1.frame.origin.x - self.contentOffset.x) < fabs(cell2.frame.origin.x - self.contentOffset.x))
                xOffset = cell1.frame.origin.x - sideOffset;
            else
                xOffset = cell2.frame.origin.x - sideOffset;
            
            adjust.x = self.contentOffset.x - xOffset;
        } else {
            CGFloat yOffset;
            
            if (fabs(cell1.frame.origin.y - self.contentOffset.y) < fabs(cell2.frame.origin.y - self.contentOffset.y))
                yOffset = cell1.frame.origin.y - sideOffset;
            else
                yOffset = cell2.frame.origin.y - sideOffset;
            
            adjust.y = self.contentOffset.y - yOffset;
        }
        
        blockRemoving = YES;
        [UIView animateWithDuration:0.2
                         animations:^{
                             for (AFGridViewCell *cell in self.scrollingCells) {
                                 CGRect cellFrame = cell.frame;
                                 cellFrame.origin.x += adjust.x;
                                 cellFrame.origin.y += adjust.y;
                                 cell.frame = cellFrame;
                             }
                         } completion:^(BOOL finished) {
                             blockRemoving = NO;
                             [self layoutSubviews];
                         }];
    }
    
}

- (void)resetHitValues
{
    self.hitPoint = self.hitContentOffset = CGPointZero;
    [self.fixedCells addObjectsFromArray:self.scrollingCells];
    self.scrollingCells = nil;
    self.moveDirection = moveNoneDirection;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self recenterCells];
    [self resetHitValues];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self recenterCells];
        [self resetHitValues];
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
        [visibleIndexes addObject:[NSNumber numberWithInt:cell.tag]];
    }
    
    for (AFGridViewCell *cell in self.fixedCells) {
        [visibleIndexes addObject:[NSNumber numberWithInt:cell.tag]];
    }
    
    [allIndexes minusSet:visibleIndexes];
    
    return allIndexes;
}

- (AFGridViewCell *)getNextCell
{
    //    NSNumber *index = [self.possibleCellsSet anyObject];
    //    [self.possibleCellsSet removeObject:index];
    NSNumber *index = [[self detectPossibleCells] anyObject];
    
    AFGridViewCell *newCell = [self dequeCell];
    [self.dataSource gridView:self
                configureCell:newCell
                    withIndex:index.integerValue];
    [self addSubview:newCell];
    return newCell;
}

#pragma mark Horizontal tiling

- (CGFloat)placeNewCellOnRight:(CGFloat)rightEdge {
    AFGridViewCell *cellView = [self getNextCell];
    AFGridViewCell *otherCell = [self.scrollingCells lastObject];
    [self.scrollingCells addObject:cellView]; // add rightmost label at the end of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = rightEdge + CELL_OFFSET;
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
    frame.origin.x = leftEdge - otherCell.frame.size.width - CELL_OFFSET;
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
    
    if ([self.scrollingCells count] == 0) {
        [self placeNewCellOnRight:minimumVisibleX];
    }
    
    lastCell = [self.scrollingCells lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastCell frame]);
    while (rightEdge + CELL_OFFSET < maximumVisibleX) {
        rightEdge = [self placeNewCellOnRight:rightEdge];
    }
    
    firstCell = [self.scrollingCells objectAtIndex:0];
    CGFloat leftEdge = CGRectGetMinX([firstCell frame]);
    while (leftEdge - CELL_OFFSET > minimumVisibleX) {
        leftEdge = [self placeNewCellOnLeft:leftEdge];
    }
    
    if (!blockRemoving) {
        NSMutableArray *cellsToRemove = [NSMutableArray new];
        for (AFGridViewCell *cell in self.scrollingCells) {
            CGRect visibleRect;
            visibleRect.origin = self.contentOffset;
            visibleRect.size = self.bounds.size;
            if (!CGRectIntersectsRect(visibleRect, cell.frame)) {
                [cellsToRemove addObject:cell];
            }
        }
        
        for (AFGridViewCell *cell in cellsToRemove) {
            [self.scrollingCells removeObject:cell];
            if (_delegate && [_delegate respondsToSelector:@selector(gridView:cellWillDissappear:)]) {
                [_delegate gridView:self
                 cellWillDissappear:cell];
            }
            [cell removeFromSuperview];
            [self.recycledCells addObject:cell];
        }
        
        /*
         lastCell = [self.scrollingCells lastObject];
         while ([lastCell frame].origin.x > maximumVisibleX) {
         [self.possibleCellsSet addObject:[NSNumber numberWithInt:lastCell.tag]];
         [lastCell removeFromSuperview];
         [self.scrollingCells removeLastObject];
         lastCell = [self.scrollingCells lastObject];
         }
         
         firstCell =  (self.scrollingCells.count) ? [self.scrollingCells objectAtIndex:0] : nil;
         while (firstCell && (CGRectGetMaxX([firstCell frame]) < minimumVisibleX)) {
         [self.possibleCellsSet addObject:[NSNumber numberWithInt:firstCell.tag]];
         [firstCell removeFromSuperview];
         [self.scrollingCells removeObjectAtIndex:0];
         firstCell = [self.scrollingCells objectAtIndex:0];
         }
         */
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
    frame.origin.y = bottomEdge + CELL_OFFSET;
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
    frame.origin.y = topEdge - frame.size.height - CELL_OFFSET;
    [cellView setFrame:frame];
    
    return CGRectGetMinY(frame);
}

- (void)tileCellsFromMinY:(CGFloat)minimumVisibleY toMaxY:(CGFloat)maximumVisibleY
{
    if ([self.scrollingCells count] == 0) {
        [self placeNewCellOnBottom:minimumVisibleY];
    }
    
    UIView *lastCell = [self.scrollingCells lastObject];
    CGFloat bottomEdge = CGRectGetMaxY([lastCell frame]);
    while (bottomEdge + CELL_OFFSET < maximumVisibleY) {
        bottomEdge = [self placeNewCellOnBottom:bottomEdge];
    }
    
    UIView *firstCell = [self.scrollingCells objectAtIndex:0];
    CGFloat topEdge = CGRectGetMinY([firstCell frame]);
    while (topEdge - CELL_OFFSET > minimumVisibleY) {
        topEdge = [self placeNewCellOnTop:topEdge];
    }
    
    if (!blockRemoving) {
        NSMutableArray *cellsToRemove = [NSMutableArray new];
        for (AFGridViewCell *cell in self.scrollingCells) {
            CGRect visibleRect;
            visibleRect.origin = self.contentOffset;
            visibleRect.size = self.bounds.size;
            if (!CGRectIntersectsRect(visibleRect, cell.frame)) {
                [cellsToRemove addObject:cell];
            }
        }
        
        for (AFGridViewCell *cell in cellsToRemove) {
            [self.scrollingCells removeObject:cell];
            if (_delegate && [_delegate respondsToSelector:@selector(gridView:cellWillDissappear:)]) {
                [_delegate gridView:self
                 cellWillDissappear:cell];
            }
            [cell removeFromSuperview];
            [self.recycledCells addObject:cell];
        }
        
        /*
         lastCell = [self.scrollingCells lastObject];
         while ([lastCell frame].origin.y > maximumVisibleY) {
         [self.possibleCellsSet addObject:[NSNumber numberWithInt:lastCell.tag]];
         [lastCell removeFromSuperview];
         [self.scrollingCells removeLastObject];
         lastCell = [self.scrollingCells lastObject];
         }
         
         firstCell = [self.scrollingCells objectAtIndex:0];
         while (CGRectGetMaxY([firstCell frame]) < minimumVisibleY) {
         [self.possibleCellsSet addObject:[NSNumber numberWithInt:firstCell.tag]];
         [firstCell removeFromSuperview];
         [self.scrollingCells removeObjectAtIndex:0];
         firstCell = [self.scrollingCells objectAtIndex:0];
         }
         */
    }
}

@end
