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

@interface AFViewController ()

@property (strong, nonatomic) AFGridView *gridView;

@end

@implementation AFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.gridView = [AFGridView new];
    _gridView.frame = self.view.bounds;
    
    [self.view addSubview:_gridView];
    
    [self.view addSubview:[[AFInfiniteScrollView alloc] initWithFrame:self.view.bounds]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
