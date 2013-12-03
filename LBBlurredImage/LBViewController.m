//
//  LBViewController.m
//  Blur
//
//  Created by Luca Bernardi on 11/11/12.
//  Copyright (c) 2012 Luca Bernardi. All rights reserved.
//

#import "LBViewController.h"
#import "UIImageView+LBBlurredImage.h"
#import "TRBlurGlassView.h"

@interface LBViewController ()

@end


@implementation LBViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageView.image = [UIImage imageNamed:@"example.png"];
    TRBlurGlassView *blurView = [[TRBlurGlassView alloc] initWithFrame:CGRectMake(120, 120, 80, 80)];
    blurView.maskImage = [UIImage imageNamed:@"mask.png"];
    [self.view addSubview:blurView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
