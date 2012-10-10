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

- (void)tileCellsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX;

@end

@implementation AFInfiniteScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    [self tileCellsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
}

#pragma mark - Cell Tiling

- (UILabel *)insertCell {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 80)];
    [label setNumberOfLines:3];
    [label setText:@"1024 Block Street\nShaffer, CA\n95014"];
    [_cellContainerView addSubview:label];
    
    return label;
}

- (CGFloat)placeNewCellOnRight:(CGFloat)rightEdge {
    UILabel *label = [self insertCell];
    [_visibleCells addObject:label]; // add rightmost label at the end of the array
    
    CGRect frame = [label frame];
    frame.origin.x = rightEdge;
    frame.origin.y = [_cellContainerView bounds].size.height - frame.size.height;
    [label setFrame:frame];
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewCellOnLeft:(CGFloat)leftEdge {
    UILabel *label = [self insertCell];
    [_visibleCells insertObject:label atIndex:0]; // add leftmost label at the beginning of the array
    
    CGRect frame = [label frame];
    frame.origin.x = leftEdge - frame.size.width;
    frame.origin.y = [_cellContainerView bounds].size.height - frame.size.height;
    [label setFrame:frame];
    
    return CGRectGetMinX(frame);
}

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

#pragma mark - Centering cells after scrolling

- (void)recenterCells
{
    if ([_visibleCells count] > 2) {
        UIView *cell1 = [_visibleCells objectAtIndex:0];
        UIView *cell2 = [_visibleCells objectAtIndex:1];
        
        CGFloat xOffset;
        
        if (fabs(cell1.frame.origin.x - self.contentOffset.x) < fabs(cell2.frame.origin.x - self.contentOffset.x)) {
            xOffset = cell1.frame.origin.x;
        } else {
            xOffset = cell2.frame.origin.x;
        }
        
        [UIView animateWithDuration:0.5
                         animations:^{
                             self.contentOffset =  CGPointMake(xOffset, self.contentOffset.y);
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
