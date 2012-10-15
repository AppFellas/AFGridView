//
//  AFInfiniteScrollView.m
//  AFGridViewSample
//
//  Created by Alex on 10/10/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFInfiniteScrollView.h"

#define FAKE_LENGTH 5000

@interface AFInfiniteScrollView()
@property (nonatomic, strong) NSMutableArray *visibleCells;
@property (nonatomic, strong) UIView *cellContainerView;
@end

@implementation AFInfiniteScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.scrollDirection = AFScrollViewDirectionVertical;
        
        self.visibleCells = [NSMutableArray new];
        
        self.cellContainerView = [[UIView alloc] init];
        _cellContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
        
        [self addSubview:_cellContainerView];
        [_cellContainerView setUserInteractionEnabled:NO];
        
        [self setShowsHorizontalScrollIndicator:NO];
        [self setShowsVerticalScrollIndicator:NO];
        
        self.delegate = self;
    }
    return self;
}

- (void)setScrollDirection:(AFScrollViewDirection)scrollDirection
{
    _scrollDirection = scrollDirection;
    
    if (_scrollDirection == AFScrollViewDirectionHorizontal) {
        self.contentSize = CGSizeMake(FAKE_LENGTH, self.frame.size.height);
    } else {
        self.contentSize = CGSizeMake(self.frame.size.width, FAKE_LENGTH);
    }
}

- (void)recenterIfNecessary {
    CGPoint currentOffset = [self contentOffset];

    if (_scrollDirection == AFScrollViewDirectionHorizontal) {
        CGFloat contentWidth = [self contentSize].width;
        CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
        CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);
        
        if (distanceFromCenter > (contentWidth / 4.0)) {
            self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
            
            // move content by the same amount so it appears to stay still
            for (UIView *cell in _visibleCells) {
                CGPoint center = [_cellContainerView convertPoint:cell.center toView:self];
                center.x += (centerOffsetX - currentOffset.x);
                cell.center = [self convertPoint:center toView:_cellContainerView];
            }
        }
    } else {
        CGFloat contentHeight = [self contentSize].height;
        CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0;
        CGFloat distanceFromCenter = fabs(currentOffset.y - centerOffsetY);
        
        if (distanceFromCenter > (contentHeight / 4.0)) {
            self.contentOffset = CGPointMake(currentOffset.x, centerOffsetY);
            // move content by the same amount so it appears to stay still
            for (UIView *cell in _visibleCells) {
                CGPoint center = [_cellContainerView convertPoint:cell.center toView:self];
                center.y += (centerOffsetY - currentOffset.y);
                cell.center = [self convertPoint:center toView:_cellContainerView];
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self recenterIfNecessary];
    
    // tile content in visible bounds
    CGRect visibleBounds = [self convertRect:[self bounds] toView:_cellContainerView];

    
    if (_scrollDirection == AFScrollViewDirectionHorizontal) {
        CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds) - (int)([self.dataSource cellPaddingInScrollView:self] / 2);
        CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
        [self tileCellsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
    } else {
        CGFloat minimumVisibleY = CGRectGetMinY(visibleBounds) - (int)([self.dataSource cellPaddingInScrollView:self] / 2);
        CGFloat maximumVisibleY = CGRectGetMaxY(visibleBounds);
        [self tileCellsFromMinY:minimumVisibleY toMaxY:maximumVisibleY];
    }
}

#pragma mark - Cell Tiling

#pragma mark Common tiling methods

- (UIView *)getViewByIndex:(NSInteger)index
{
    UIView *cellView = [self.dataSource infiniteScrollView:self viewWithIndex:index];
    cellView.tag = index;
    CGRect viewRect;
    viewRect.origin.x = viewRect.origin.y = 0;
    viewRect.size = [self.dataSource sizeForCellInScrollView:self];
    cellView.frame = viewRect;
    [_cellContainerView addSubview:cellView];
    return cellView;
}

- (UIView *)getNextCell {
    NSInteger nextCellIndex = 0;
    if (_visibleCells.count) {
        UIView *cellView = [_visibleCells lastObject];
        nextCellIndex = (cellView.tag + 1) % [self.dataSource numberOfCellsInScrollView:self];
    }
    return [self getViewByIndex:nextCellIndex];
}

- (UIView *)getPreviousCell
{
    NSInteger currentCellIndex = ((UIView *)_visibleCells[0]).tag;
    NSInteger prevCellIndex = ((currentCellIndex - 1) >= 0) ? currentCellIndex - 1 : [self.dataSource numberOfCellsInScrollView:self] - 1;
    return [self getViewByIndex:prevCellIndex];
}

#pragma mark Horizontal tiling methods

- (CGFloat)placeNewCellOnRight:(CGFloat)rightEdge {
    UIView *cellView = [self getNextCell];
    [_visibleCells addObject:cellView]; // add rightmost label at the end of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = rightEdge + [self.dataSource cellPaddingInScrollView:self];
    frame.origin.y = 0;
    [cellView setFrame:frame];
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewCellOnLeft:(CGFloat)leftEdge {
    UIView *cellView = [self getPreviousCell];
    [_visibleCells insertObject:cellView atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = leftEdge - frame.size.width - [self.dataSource cellPaddingInScrollView:self];
    frame.origin.y = 0;
    [cellView setFrame:frame];
    
    return CGRectGetMinX(frame);
}

static BOOL blockRemoving;

- (void)tileCellsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX
{
    // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([_visibleCells count] == 0) {
        [self placeNewCellOnRight:minimumVisibleX];
    }
    
    // add labels that are missing on right side
    UIView *lastCell = [_visibleCells lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastCell frame]);
    while (rightEdge < maximumVisibleX) {
        rightEdge = [self placeNewCellOnRight:rightEdge];
    }
    
    // add labels that are missing on left side
    UIView *firstCell = [_visibleCells objectAtIndex:0];
    CGFloat leftEdge = CGRectGetMinX([firstCell frame]);
    while (leftEdge > minimumVisibleX) {
        leftEdge = [self placeNewCellOnLeft:leftEdge];
    }
    
    if (!blockRemoving) {
        // remove labels that have fallen off right edge
        lastCell = [_visibleCells lastObject];
        while ([lastCell frame].origin.x > maximumVisibleX) {
            [lastCell removeFromSuperview];
            [_visibleCells removeLastObject];
            lastCell = [_visibleCells lastObject];
        }
        
        // remove labels that have fallen off left edge
        firstCell = [_visibleCells objectAtIndex:0];
        while (CGRectGetMaxX([firstCell frame]) < minimumVisibleX) {
            [firstCell removeFromSuperview];
            [_visibleCells removeObjectAtIndex:0];
            firstCell = [_visibleCells objectAtIndex:0];
        }
    }
}

#pragma mark Vertical tiling methods

- (CGFloat)placeNewCellOnBottom:(CGFloat)bottomEdge
{
    UIView *cellView = [self getNextCell];
    [_visibleCells addObject:cellView]; // add rightmost label at the end of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = 0;
    frame.origin.y = bottomEdge + [self.dataSource cellPaddingInScrollView:self];
    [cellView setFrame:frame];
    
    return CGRectGetMaxY(frame);
}

- (CGFloat)placeNewCellOnTop:(CGFloat)topEdge
{
    UIView *cellView = [self getPreviousCell];
    [_visibleCells insertObject:cellView atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = 0;//leftEdge - frame.size.width - [self.dataSource cellPaddingInScrollView:self];
    frame.origin.y = topEdge - frame.size.height - [self.dataSource cellPaddingInScrollView:self];
    [cellView setFrame:frame];
    
    return CGRectGetMinY(frame);
}

- (void)tileCellsFromMinY:(CGFloat)minimumVisibleY toMaxY:(CGFloat)maximumVisibleY
{
    // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([_visibleCells count] == 0) {
        [self placeNewCellOnBottom:minimumVisibleY];
    }
    
    // add labels that are missing on right side
    UIView *lastCell = [_visibleCells lastObject];
    CGFloat bottomEdge = CGRectGetMaxY([lastCell frame]);
    while (bottomEdge < maximumVisibleY) {
        bottomEdge = [self placeNewCellOnBottom:bottomEdge];
    }
    
    // add labels that are missing on left side
    UIView *firstCell = [_visibleCells objectAtIndex:0];
    CGFloat topEdge = CGRectGetMinY([firstCell frame]);
    while (topEdge > minimumVisibleY) {
        topEdge = [self placeNewCellOnTop:topEdge];
    }
    
    if (!blockRemoving) {
        // remove labels that have fallen off right edge
        lastCell = [_visibleCells lastObject];
        while ([lastCell frame].origin.y > maximumVisibleY) {
            [lastCell removeFromSuperview];
            [_visibleCells removeLastObject];
            lastCell = [_visibleCells lastObject];
        }
        
        // remove labels that have fallen off left edge
        firstCell = [_visibleCells objectAtIndex:0];
        while (CGRectGetMaxY([firstCell frame]) < minimumVisibleY) {
            [firstCell removeFromSuperview];
            [_visibleCells removeObjectAtIndex:0];
            firstCell = [_visibleCells objectAtIndex:0];
        }
    }

}

#pragma mark - Centering cells after scrolling

- (void)recenterCells
{
    if ([_visibleCells count] > 2) {
        CGPoint scrollPoint;
        UIView *cell1 = [_visibleCells objectAtIndex:0];
        UIView *cell2 = [_visibleCells objectAtIndex:1];
        
        CGFloat sideOffset = (int)([self.dataSource cellPaddingInScrollView:self] / 2);
        
        if (_scrollDirection == AFScrollViewDirectionHorizontal) {
            CGFloat xOffset;
            
            if (fabs(cell1.frame.origin.x - self.contentOffset.x) < fabs(cell2.frame.origin.x - self.contentOffset.x))
                xOffset = cell1.frame.origin.x - sideOffset;
            else
                xOffset = cell2.frame.origin.x - sideOffset;
            
            scrollPoint = CGPointMake(xOffset, self.contentOffset.y);
        } else {
            CGFloat yOffset;
            
            if (fabs(cell1.frame.origin.y - self.contentOffset.y) < fabs(cell2.frame.origin.y - self.contentOffset.y))
                yOffset = cell1.frame.origin.y - sideOffset;
            else
                yOffset = cell2.frame.origin.y - sideOffset;
            
            scrollPoint = CGPointMake(self.contentOffset.x, yOffset);
        }
    
        blockRemoving = YES;
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.contentOffset = scrollPoint;
                         } completion:^(BOOL finished) {
                             blockRemoving = NO;
                             [self layoutSubviews];
                             [self.actionDelegate infiniteScrollView:self
                                           didStopScrollingWithCells:self.visibleCells];
                         }];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self recenterCells];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) [self recenterCells];
}

@end
