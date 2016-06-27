//
//  TileView.m
//  DragTiles
//
//  Created by yxhe on 16/5/26.
//  Copyright © 2016年 yxhe. All rights reserved.
//

#import "TileButton.h"

@interface TileButton ()

@property (nonatomic, strong) UIButton *deleteButton; //the little del button

@end

@implementation TileButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        //set the main button style，in the tile button we can add many things
        self.backgroundColor = [UIColor yellowColor];
        [self setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//        [self setTitleColor:[UIColor greenColor] forState:UIControlEventTouchDown];
        
        //add the delete button
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        _deleteButton.frame = CGRectMake(self.bounds.size.width*6/7.0, 0, self.frame.size.width/7.0, self.frame.size.height/7.0); //use the relative coordinates
        _deleteButton.backgroundColor = [UIColor redColor];
        _deleteButton.transform = CGAffineTransformMakeScale(0.1, 0.1); //set the deletebutton small at the beginning
        _deleteButton.hidden = YES; //hide it at the beginning
        [_deleteButton addTarget:self action:@selector(deleteButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_deleteButton];

        
    }
    
    return self;
}


#pragma mark - called outside
- (void)setTileText:(NSString *)text clickText:(NSString *)clickText
{
    [self setTitle:text forState:UIControlStateNormal];
//    [self setTitle:clickText forState:UIControlEventTouchDown];
    
}

- (void)tileLongPressed
{
    //make the tile half transparent and show the deletebutton
    //show the deletebutton
    [_deleteButton setHidden:NO];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.6;
        self.transform = CGAffineTransformMakeScale(1.1, 1.1);
        _deleteButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
    
}

- (void)tileSuspended
{
    [_deleteButton setHidden:NO];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.6;
        self.transform = CGAffineTransformMakeScale(1.0, 1.0);
        _deleteButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
}

- (void)tileSettled
{
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
        self.transform = CGAffineTransformMakeScale(1.0, 1.0);
        _deleteButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
    }];
    [self performSelector:@selector(delayHide) withObject:nil afterDelay:0.3];
}

- (void)delayHide
{
    //the main button removed then the deletebutton automatically removed
    [_deleteButton setHidden:YES]; }

#pragma button callback
- (void)deleteButtonClicked
{
    NSLog(@"delete button clicked");
    if([self.delegate respondsToSelector:@selector(tileDeleteButtonClicked:)])
    {
        [self.delegate tileDeleteButtonClicked:self];
    }
}

@end
