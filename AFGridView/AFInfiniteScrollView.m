//
//  AFInfiniteScrollView.m
//  AFGridViewSample
//
//  Created by Alex on 10/10/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFInfiniteScrollView.h"

#define FAKE_LENGTH 5000

@interface AFInfiniteScrollView()<AFInfiniteScrollViewDataSource>
@property (nonatomic, strong) NSMutableArray *visibleCells;
@property (nonatomic, strong) UIView *cellContainerView;

- (void)tileCellsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX;

//delete after testing
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, assign) NSInteger currentIndex;

@end

@implementation AFInfiniteScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //testing
        self.array = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"].mutableCopy;
        self.currentIndex = -1;
        self.dataSource = self;
        
        // Initialization code
        self.contentSize = CGSizeMake(FAKE_LENGTH, frame.size.height);
        
        self.visibleCells = [NSMutableArray new];
        
        self.cellContainerView = [[UIView alloc] init];
        _cellContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height / 2);
        
        [self addSubview:_cellContainerView];
        [_cellContainerView setUserInteractionEnabled:NO];
        
        [self setShowsHorizontalScrollIndicator:NO];
        [self setShowsVerticalScrollIndicator:NO];
        
        self.delegate = self;
    }
    return self;
}

- (void)recenterIfNecessary {
    CGPoint currentOffset = [self contentOffset];
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
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self recenterIfNecessary];
    
    // tile content in visible bounds
    CGRect visibleBounds = [self convertRect:[self bounds] toView:_cellContainerView];
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds) - (int)([self.dataSource cellPaddingInScrollView:self] / 2);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    [self tileCellsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
}

#pragma mark - Cell Tiling

- (UIView *)getViewByIndex:(NSInteger)index
{
    CGRect labelRect;
    labelRect.origin.x = labelRect.origin.y = 0;
    labelRect.size = [self.dataSource sizeForCellInScrollView:self];
    UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
    label.tag = index;
    label.backgroundColor = [UIColor redColor];
    [label setNumberOfLines:3];
    [label setText:[NSString stringWithFormat:@"%@ Block Street\nShaffer, CA\n95014", _array[index]]];
    [_cellContainerView addSubview:label];
    
    return label;
}

- (UIView *)getNextCell {
    NSInteger nextCellIndex = 0;
    if (_visibleCells.count) {
        UIView *cellView = [_visibleCells lastObject];
        nextCellIndex = (cellView.tag + 1) % _array.count;
    }
    return [self getViewByIndex:nextCellIndex];
}

- (UIView *)getPreviousCell
{
    NSInteger currentCellIndex = ((UIView *)_visibleCells[0]).tag;
    NSInteger prevCellIndex = ((currentCellIndex - 1) >= 0) ? currentCellIndex - 1 : _array.count - 1;
    return [self getViewByIndex:prevCellIndex];
}

- (CGFloat)placeNewCellOnRight:(CGFloat)rightEdge {
    UIView *cellView = [self getNextCell];
    [_visibleCells addObject:cellView]; // add rightmost label at the end of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = rightEdge + [self.dataSource cellPaddingInScrollView:self];
    frame.origin.y = [_cellContainerView bounds].size.height - frame.size.height;
    [cellView setFrame:frame];
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewCellOnLeft:(CGFloat)leftEdge {
    UIView *cellView = [self getPreviousCell];
    [_visibleCells insertObject:cellView atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [cellView frame];
    frame.origin.x = leftEdge - frame.size.width - [self.dataSource cellPaddingInScrollView:self];
    frame.origin.y = [_cellContainerView bounds].size.height - frame.size.height;
    [cellView setFrame:frame];
    
    return CGRectGetMinX(frame);
}

static BOOL blockRemoving;

- (void)tileCellsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX {
    // the upcoming tiling logic depends on there already being at least one label in the visibleLabels array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([_visibleCells count] == 0) {
        [self placeNewCellOnRight:minimumVisibleX];
    }
    
    // add labels that are missing on right side
    UILabel *lastLabel = [_visibleCells lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastLabel frame]);
    while (rightEdge < maximumVisibleX) {
        rightEdge = [self placeNewCellOnRight:rightEdge];
    }
    
    // add labels that are missing on left side
    UILabel *firstLabel = [_visibleCells objectAtIndex:0];
    CGFloat leftEdge = CGRectGetMinX([firstLabel frame]);
    while (leftEdge > minimumVisibleX) {
        leftEdge = [self placeNewCellOnLeft:leftEdge];
    }
    
    if (!blockRemoving) {
        // remove labels that have fallen off right edge
        lastLabel = [_visibleCells lastObject];
        while ([lastLabel frame].origin.x > maximumVisibleX) {
            [lastLabel removeFromSuperview];
            [_visibleCells removeLastObject];
            lastLabel = [_visibleCells lastObject];
        }
        
        // remove labels that have fallen off left edge
        firstLabel = [_visibleCells objectAtIndex:0];
        while (CGRectGetMaxX([firstLabel frame]) < minimumVisibleX) {
            [firstLabel removeFromSuperview];
            [_visibleCells removeObjectAtIndex:0];
            firstLabel = [_visibleCells objectAtIndex:0];
        }
    }
}

#pragma mark - Centering cells after scrolling

- (void)recenterCells
{
    if ([_visibleCells count] > 2) {
        UIView *cell1 = [_visibleCells objectAtIndex:0];
        UIView *cell2 = [_visibleCells objectAtIndex:1];
        
        CGFloat xOffset;
        
        if (fabs(cell1.frame.origin.x - self.contentOffset.x) < fabs(cell2.frame.origin.x - self.contentOffset.x)) {
            xOffset = cell1.frame.origin.x - 1;
        } else {
            xOffset = cell2.frame.origin.x - 1;
        }
        
        blockRemoving = YES;
        
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.contentOffset =  CGPointMake(xOffset, self.contentOffset.y);
                         } completion:^(BOOL finished) {
                             blockRemoving = NO;
                             [self layoutSubviews];
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

#pragma mark - Delete this section

- (CGSize)sizeForCellInScrollView:(AFInfiniteScrollView *)infiniteScrollView
{
    return CGSizeMake(190, 80);
}

- (CGFloat)cellPaddingInScrollView:(AFInfiniteScrollView *)infiniteScrollView
{
    return 2;
}

@end
