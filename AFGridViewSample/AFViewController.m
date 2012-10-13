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
#import <QuartzCore/QuartzCore.h>

@interface AFViewController()<AFInfiniteScrollViewDataSource, AFGridViewDataSource>

@property (strong, nonatomic) AFGridView *gridView;
//delete after testing
@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation AFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.array = [NSMutableArray array];
    
    for (int i = 0; i < 30; i++) {
        [self.array addObject:[NSString stringWithFormat:@"%d", i + 1]];
    }
    
    self.gridView = [AFGridView new];
    _gridView.frame = self.view.bounds;
    _gridView.dataSource = self;
    [self.view addSubview:_gridView];
    [_gridView reloadGridView];
    
    /*
    AFInfiniteScrollView *infiniteScrollView = [[AFInfiniteScrollView alloc] initWithFrame:self.view.bounds];
    infiniteScrollView.dataSource = self;
    infiniteScrollView.scrollDirection = AFScrollViewDirectionHorizontal;
    [self.view addSubview:infiniteScrollView];
     */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark - AFInfiniteScrollViewDataSource methods

- (UIView *)infiniteScrollView:(AFInfiniteScrollView *)infiniteScrollView viewWithIndex:(NSInteger)index
{
    UILabel *label = [[UILabel alloc] init];
    label.tag = index;
    label.backgroundColor = [UIColor redColor];
    [label setNumberOfLines:3];
    [label setText:[NSString stringWithFormat:@"%@", _array[index]]];
    [label setFont:[UIFont boldSystemFontOfSize:30]];
    
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

#pragma mark - AFGridViewDataSource methods

- (NSInteger)numberOfRowsInGridView:(AFGridView *)gridView
{
    return 3;
}

- (NSInteger)numberOfColumnsInGridView:(AFGridView *)gridView
{
    return 4;
}

- (NSInteger)numberOfObjectsInGridView:(AFGridView *)gridView
{
    return _array.count;
}

- (UIView *)gridView:(AFGridView *)gridView viewForCellAtIndex:(NSInteger)index
{
    UILabel *label = [[UILabel alloc] init];
    label.tag = index;
    label.backgroundColor = [UIColor redColor];
    [label setText:[NSString stringWithFormat:@"%@", _array[index]]];
    [label setFont:[UIFont boldSystemFontOfSize:30]];
    label.textAlignment = UITextAlignmentCenter;
    label.layer.cornerRadius = 10;
    return label;
}

@end
