//
//  TileView.h
//  DragTiles
//
//  Created by yxhe on 16/5/26.
//  Copyright © 2016年 yxhe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TileButton;

//the delte button delegate
@protocol TileDeleteButtonDelegate<NSObject>

@optional

- (void)tileDeleteButtonClicked:(TileButton *)tileBtn;

@end


@interface TileButton : UIButton

@property (nonatomic, assign) id<TileDeleteButtonDelegate> delegate;
//index in the tile array
@property (nonatomic, assign) NSInteger index;

//set the tile text outside the class
- (void)setTileText:(NSString *)text clickText:(NSString *)clickText;
//tile longpressed and begin to move, called outside
- (void)tileLongPressed;
//the tile touched pressed but not moved, called outside
- (void)tileSuspended;
//cancel press or settle the tile to new place, called outside
- (void)tileSettled;

@end
