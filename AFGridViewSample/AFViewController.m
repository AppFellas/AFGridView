//
//  AFViewController.m
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFViewController.h"
#import "AFGridView.h"
#import "AFInfiniteScrollView.h"

@interface AFViewController()<AFInfiniteScrollViewDataSource>

@property (strong, nonatomic) AFGridView *gridView;
//delete after testing
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, assign) NSInteger currentIndex;

@end

@implementation AFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.gridView = [AFGridView new];
    _gridView.frame = self.view.bounds;
    
    [self.view addSubview:_gridView];
    
    self.array = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"].mutableCopy;
    
    AFInfiniteScrollView *infiniteScrollView = [[AFInfiniteScrollView alloc] initWithFrame:self.view.bounds];
    infiniteScrollView.dataSource = self;
    infiniteScrollView.scrollDirection = AFScrollViewDirectionHorizontal;
    [self.view addSubview:infiniteScrollView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AFInfiniteScrollViewDataSource methods

- (UIView *)infiniteScrollView:(AFInfiniteScrollView *)infiniteScrollView viewWithIndex:(NSInteger)index
{
    UILabel *label = [[UILabel alloc] init];
    label.tag = index;
    label.backgroundColor = [UIColor redColor];
    [label setNumberOfLines:3];
    [label setText:[NSString stringWithFormat:@"%@ Block Street\nShaffer, CA\n95014", _array[index]]];
    return label;
}

- (CGSize)sizeForCellInScrollView:(AFInfiniteScrollView *)infiniteScrollView
{
    return CGSizeMake(190, 80);
}

- (CGFloat)cellPaddingInScrollView:(AFInfiniteScrollView *)infiniteScrollView
{
    return 2;
}

- (NSInteger)numberOfCellsInScrollView:(AFInfiniteScrollView *)infiniteScrollView
{
    return _array.count;
}

@end
