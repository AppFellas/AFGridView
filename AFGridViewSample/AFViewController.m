//
//  AFViewController.m
//  AFGridViewSample
//
//  Created by Alex on 10/9/12.
//  Copyright (c) 2012 AppFellas. All rights reserved.
//

#import "AFViewController.h"
#import "AFGridView.h"
#import "AFGridViewCell.h"
#import <QuartzCore/QuartzCore.h>

@interface AFViewController()<AFGridViewDataSource, AFGridViewDelegate>

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
    _gridView.gridDelegate = self;
    [self.view addSubview:_gridView];
    [_gridView reloadGridView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
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

- (void)gridView:(AFGridView *)gridView
   configureCell:(AFGridViewCell *)cell
       withIndex:(NSInteger)index
{
    cell.tag = index;
    cell.backgroundColor = [UIColor redColor];
    [cell.textLabel setText:[NSString stringWithFormat:@"%@", _array[index]]];
    [cell.textLabel setFont:[UIFont boldSystemFontOfSize:30]];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.layer.cornerRadius = 10;
}

- (AFGridViewCell *)gridView:(AFGridView *)gridView
          viewForCellAtIndex:(NSInteger)index
{
    AFGridViewCell *cell = [[AFGridViewCell alloc] init];
    [self gridView:gridView configureCell:cell withIndex:index];
    return cell;
}

#pragma mark - AFGridViewDelegate methods

- (void)gridView:(AFGridView *)gridView didSelectCell:(AFGridViewCell *)cell
{
    [[[UIAlertView alloc] initWithTitle:@"Message"
                                message:[NSString stringWithFormat:@"%d tapped.", cell.tag + 1]
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end
