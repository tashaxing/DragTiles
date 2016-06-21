//
//  ViewController.m
//  DragTiles
//
//  Created by yxhe on 16/5/26.
//  Copyright © 2016年 yxhe. All rights reserved.
//

#import "UPViewController.h"
#import "TileButton.h"

/**************global variables and macros***********/
//conditional build to switch on two animations
#define ALIPAY_ANIMATION

//the space between tiles
const static int kTileSpace = 5;
//the inital max tile number in one line
const static int kTileInLine = 4;

//define the enum of tilte state
enum TouchState
{
    UNTOUCHED,
    SUSPEND,
    MOVE
};
/****************************************************/


@interface UPViewController ()<TileDeleteButtonDelegate>
{
    //the __block prefix can make it accessed in the block
    
    __block CGPoint startPos;    //the touch point
    __block CGPoint originPos;   //the tile original point
    
    enum TouchState touchState;  //the tile touch state
    NSInteger currentTileCount;  //the tile count up to now
    
    NSInteger preTouchID;        //the button ID pretouched
   
}

@property (nonatomic, strong) NSMutableArray *tileArray; //the titles array
@property (nonatomic, strong) UIScrollView *scrollview;  //the scrollview

@end

@implementation UPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    [self.view setBackgroundColor:[UIColor whiteColor]];
    CGRect screenRect = self.view.frame;
//    NSLog(@"%f %f", screenRect.size.width, screenRect.size.height);
    
    //the add button to add tiles
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [addButton setFrame:CGRectMake(0, 20, 30, 30)];
    [addButton addTarget:self action:@selector(addTile) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addButton];
    
    //add the scroll view
    self.scrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(screenRect.origin.x, screenRect.origin.y + 60, screenRect.size.width, screenRect.size.height - 60)];
    self.scrollview.backgroundColor = [UIColor lightGrayColor];
    self.scrollview.contentSize = self.scrollview.frame.size;
    NSLog(@"%f, %f", _scrollview.contentSize.width, _scrollview.contentSize.height);
    [self.view addSubview:_scrollview];
    
    //inital tile number
    currentTileCount = 0;
    
    //the tile untouched at first
    touchState = UNTOUCHED;
    
    //must init the mutablearray first!, can also use alloc/init
    _tileArray = [NSMutableArray array];
    
    //init the pretouchID
    preTouchID = -1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - gesture callbacks

- (void)onLongGresture:(UILongPressGestureRecognizer *)sender
{
#ifndef ALIPAY_ANIMATION
    [self handleFreeMove:sender];
#else
    [self handleSequenceMove:sender];
#endif
}

//method 1: exchange the adjacent tiles,
//the sequence of the array elements will be disorderd
- (void)handleFreeMove:(UILongPressGestureRecognizer *)sender
{
    //get the dragged tilebutton
    TileButton *tileBtn = (TileButton *)sender.view;
    
    switch(sender.state)
    {
        case UIGestureRecognizerStateBegan:
            startPos = [sender locationInView:sender.view];
            originPos = tileBtn.center;
            
            //make the tile suspend
            [tileBtn tileSuspended];
            touchState = SUSPEND;
            
            //save the ID of pretouched title
            preTouchID = tileBtn.index;
            break;
        case UIGestureRecognizerStateChanged:
        {
            //tile long pressed
            [tileBtn tileLongPressed];
            //the tile will move
            touchState = MOVE;
            
            //comput the points
            CGPoint newPoint = [sender locationInView:sender.view];
            CGFloat offsetX = newPoint.x - startPos.x;
            CGFloat offsetY = newPoint.y - startPos.y;
            
            tileBtn.center = CGPointMake(tileBtn.center.x + offsetX, tileBtn.center.y + offsetY);
            
            //get the intersect tile ID
            int intersectID = -1;
            for(NSInteger i = 0; i < _tileArray.count; i++)
            {
                if(tileBtn != _tileArray[i] && CGRectContainsPoint([_tileArray[i] frame], tileBtn.center))
                {
                    intersectID = i;
                    break;
                }
            }
            
            if(intersectID != -1)
            {
                //swap every tile, the index remains unchanged
                __block TileButton *collisionButton = _tileArray[intersectID];
                __block CGPoint tempOriginPos = collisionButton.center; //the new origin point
                [UIView animateWithDuration:0.3 animations:^{
                    //move the other title to the moved tile's origin pos
                    collisionButton.center = originPos;
                    //save the temp origin point otherwise the block will shake
                    originPos = tempOriginPos;
                    
                }];
                
                //exchange the tile index of the array
                [_tileArray exchangeObjectAtIndex:tileBtn.index withObjectAtIndex:intersectID];
                
                //tile_btn still point to the moving tile, just swap the index
                int tempID = collisionButton.index;
                collisionButton.index = tileBtn.index;
                tileBtn.index = tempID;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [UIView animateWithDuration:0.3 animations:^{
                tileBtn.center = originPos;
            }];
            
            //only if the pre state is MOVE, then settle, otherwise leave it suspend
            if(touchState == MOVE)
            {
                touchState = UNTOUCHED;
                //settle the tile to the new position(no need to use delay operation here)
                [tileBtn tileSettled];
            }
        }
            break;
        default:
            break;
    }
}

//method 2: move the tiles inorder like Alipay,
//the order in array remains in sequence always
- (void)handleSequenceMove:(UILongPressGestureRecognizer *)sender
{
    TileButton *tileBtn = (TileButton *)sender.view;
    switch(sender.state)
    {
        case UIGestureRecognizerStateBegan:
            startPos = [sender locationInView:sender.view];
            originPos = tileBtn.center;
            
            [tileBtn tileSuspended];
            touchState = SUSPEND;
            
            preTouchID = tileBtn.index;
            break;
        case UIGestureRecognizerStateChanged:
        {
            [tileBtn tileLongPressed];
            touchState = MOVE;
            CGPoint newPoint = [sender locationInView:sender.view];
            CGFloat offsetX = newPoint.x - startPos.x;
            CGFloat offsetY = newPoint.y - startPos.y;
            
            tileBtn.center = CGPointMake(tileBtn.center.x + offsetX, tileBtn.center.y + offsetY);
            
            //get the intersect tile ID
            int intersectID = -1;
            for(NSInteger i = 0; i < _tileArray.count; i++)
            {
                if(tileBtn != _tileArray[i] && CGRectContainsPoint([_tileArray[i] frame], tileBtn.center))
                {
                    intersectID = i;
                    break;
                }
            }
            
            if(intersectID != -1)
            {
                
                if(abs(intersectID - tileBtn.index) == 1)
                {
                    //if the tiles are adjacent then move directly
                    
                    __block TileButton *collisionButton = _tileArray[intersectID];
                    __block CGPoint tempOriginPos = collisionButton.center;
                    [UIView animateWithDuration:0.3 animations:^{
                        
                        collisionButton.center = originPos;
                        originPos = tempOriginPos;
                        
                    }];
                    
                    //exchange the tile index of the array
                    [_tileArray exchangeObjectAtIndex:tileBtn.index withObjectAtIndex:intersectID];
                    
                    //tile_btn still point to the moving tile, just swap the index
                    int tempID = collisionButton.index;
                    collisionButton.index = tileBtn.index;
                    tileBtn.index = tempID;
                    
                    
                    NSLog(@"tilebtn index:%d, intersect index:%d", [_tileArray[tileBtn.index] index], [_tileArray[collisionButton.index] index]);
                    
                }
                else if(intersectID - tileBtn.index >1)
                {
                    // otherwise move the tiles to the left in order
                    
                    CGPoint preCenter = originPos;
                    CGPoint curCenter;
                    //exchange the pointer in array and swap the index,
                    //at last the tile_btn is at the new right place
                    for(int i = tileBtn.index + 1; i <= intersectID; i++)
                    {
                        __block TileButton *movedTileBtn = _tileArray[i];
                        curCenter = movedTileBtn.center;
                        
                        [UIView animateWithDuration:0.3 animations:^{
                            movedTileBtn.center = preCenter;
                        }];
                        //save the precenter
                        preCenter = curCenter;
                        //reduce the tile index
                        movedTileBtn.index--;
                        //move the pointer one by one
                        _tileArray[i-1] = movedTileBtn;
                        
                        
                    }
                    originPos = preCenter;
                    //exchange the ID
                    tileBtn.index = intersectID;
                    //now make the last pointer point to the tile_btn
                    _tileArray[intersectID] = tileBtn;
                    NSLog(@"new tile btn index: %d", [_tileArray[tileBtn.index] index]);
                }
                else
                {
                    // move the tile to right in order
                    
                    CGPoint preCenter = originPos;
                    CGPoint curCenter;
                    //exchange the pointer in array and swap the index,
                    //at last the tile_btn is at the new right place
                    for(int i = tileBtn.index - 1; i >= intersectID; i--)
                    {
                        __block TileButton *movedTileBtn = _tileArray[i];
                        curCenter = movedTileBtn.center;
                        
                        [UIView animateWithDuration:0.3 animations:^{
                            movedTileBtn.center = preCenter;
                        }];
                        preCenter = curCenter;
                        movedTileBtn.index++;
                        _tileArray[i+1] = movedTileBtn;
                        
                    }
                    originPos = preCenter;
                    tileBtn.index = intersectID;
                    _tileArray[intersectID] = tileBtn;
                    NSLog(@"new tile btn index: %d", [_tileArray[tileBtn.index] index]);
                }
                
                
                //test the display if the array is inorder
                for(TileButton *tile in _tileArray)
                {
                    NSLog(@"tile text: %@", tile.titleLabel.text);
                }
                
                
            }
            
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            [UIView animateWithDuration:0.3 animations:^{
                tileBtn.center = originPos;
            }];
            
            //only if the pre state is MOVE, then settle, otherwise leave it suspend
            if(touchState == MOVE)
            {
                [tileBtn tileSettled];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - button callbacks
- (void)tileClicked:(TileButton *)button
{
    if(touchState == SUSPEND)
    {
        //when not moving,click anywhere to settle the pretouched tile
        [_tileArray[preTouchID] tileSettled];
        NSLog(@"suspend canceld");
    }
    else if(touchState == UNTOUCHED)
    {
        //only when the tile is setted, can it be clicked to do sth
        NSLog(@"%@", button.titleLabel.text);
    }
}

//tile delete button clicked
- (void)tileDeleteButtonClicked:(TileButton *)tileBtn
{
    /* remove the button and adjust the tilearray */
    
    NSLog(@"deletebutton delegate responds");
    
    //remember the deleted tile's infomation
    int startIndex = tileBtn.index;
    CGPoint preCenter = tileBtn.center;
    CGPoint curCenter;
    
    //[_tileArray removeObject:tileBtn];
    //exchange the pointer in array and swap the index,
    //at last the tile_btn is at the new right place
    for(int i = startIndex + 1; i < _tileArray.count; i++)
    {
        __block TileButton *movedTileBtn = _tileArray[i];
        curCenter = movedTileBtn.center;
        
        [UIView animateWithDuration:0.3 animations:^{
            movedTileBtn.center = preCenter;
        }];
        
        //save the precenter
        preCenter = curCenter;
        
        //reduce the tile index
        movedTileBtn.index--;
        
        //move the pointer one by one
        _tileArray[i-1] = movedTileBtn;
    }
    
    //every time remove the last object
    [_tileArray removeLastObject];
    
    //must remove the tileBtn from the view
    //we can also use performselector so that button disappears with animation
    [tileBtn removeFromSuperview];
    
    //test the display if the array is inorder
    for(TileButton *tile in _tileArray)
    {
        NSLog(@"tile text: %@", tile.titleLabel.text);
    }
}

#pragma mark - self defined functions
//every time add a tile according to the coordinate,
//but when delete one tile , it will not show in the last (a bug unfixed)
- (void)addTile
{
    NSLog(@"add a tile");
    //add tile according the layout
    float tileSize = (_scrollview.frame.size.width - kTileSpace * kTileInLine) / kTileInLine;
    
    //add the tiles
    //tile id of column
    int xID = currentTileCount % kTileInLine;
    //tile id of row
    int yID = currentTileCount / kTileInLine;
    
    TileButton *tile = [[TileButton alloc] initWithFrame:CGRectMake(kTileSpace / 2 + xID * (kTileSpace + tileSize),
                                                                    kTileSpace / 2 + yID * (kTileSpace + tileSize),
                                                                    tileSize, tileSize)];
    
    [tile addTarget:self action:@selector(tileClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    //add gesture recognizer for tile button
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] init];
    [longGesture addTarget:self action:@selector(onLongGresture:)];
    [tile addGestureRecognizer:longGesture];
    
    //add the Click event
    [tile addTarget:self action:@selector(tileClicked:) forControlEvents:UIControlEventTouchUpInside];
    tile.delegate = self;
    
    //add tile
    [self.scrollview addSubview:tile];
    [self.tileArray addObject:tile];
    
    //set the tile index in the array
    tile.index = currentTileCount;
    [tile setTileText:[NSString stringWithFormat:@"%d", currentTileCount] clickText:@"clicked"];
    currentTileCount++;
    
    //make the scroll view contain the tile
    if(tile.frame.origin.y + tileSize > _scrollview.frame.size.height)
    {
        _scrollview.contentSize = CGSizeMake(_scrollview.contentSize.width, tile.frame.origin.y + tileSize + kTileSpace / 2);
        [_scrollview setContentOffset:CGPointMake(0, _scrollview.contentSize.height - _scrollview.frame.size.height)
                             animated:YES];
    }
}

@end
