//
//  ViewController.m
//  DragTiles
//
//  Created by yxhe on 16/5/26.
//  Copyright © 2016年 yxhe. All rights reserved.
//

#import "ViewController.h"
#import "TileButton.h"

#define ALIPAY_ANIMATION


const int tile_space = 5; //the space between tiles

const int tile_in_line = 4; //the inital max tile number in one line

//define the enum of tilte state
enum TouchState
{
    UNTOUCHED,
    SUSPEND,
    MOVE
};

@interface ViewController ()<TileButtonDelegate>
{
    //the __block prefix can make it accessed in the block
    __block CGPoint startPos; //the touch point
    __block CGPoint originPos; //the tile original point
    
    enum TouchState touchState; //the tile touch state
    NSInteger currentTileCount; //the tile count up to now
    
    NSInteger preTouchID; //the button ID pretouched
   
}

@property (nonatomic, strong) NSMutableArray *tileArray; //the titles array
@property (nonatomic, strong) UIScrollView *scrollview; //the scrollview

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
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
    
    
    currentTileCount = 0; //inital tile number
    touchState = UNTOUCHED; //the tile untouched at first
    _tileArray = [NSMutableArray array]; //must init the mutablearray!!!, can also use alloc/init
    
    preTouchID = -1; //init the pretouchID
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - add tile

//every time add a tile according to the coordinate, but when delete one tile , it will not show in the last (a bug unfixed)
- (void)addTile
{
    NSLog(@"add a tile");
    //add tile according the layout
    float tileSize = (_scrollview.frame.size.width - tile_space * tile_in_line) / tile_in_line;
    
    //add the tiles
    int xID = currentTileCount % tile_in_line; //tile id of column
    int yID = currentTileCount / tile_in_line; //tile id of row
    
    TileButton *tile = [[TileButton alloc] initWithFrame:CGRectMake(tile_space/2 + xID * (tile_space + tileSize),
                                                                    tile_space/2 + yID * (tile_space + tileSize),
                                                                    tileSize, tileSize)];
    
    [tile addTarget:self action:@selector(tileClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    //add gesture recognizer for tile button
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] init];
    [longGesture addTarget:self action:@selector(onLongGresture:)];
    [tile addGestureRecognizer:longGesture];
    
    //add the Click event
    [tile addTarget:self action:@selector(tileClicked:) forControlEvents:UIControlEventTouchUpInside];
    tile.delegate = self; //make the main view can respond to the deletebutton
    
    [self.scrollview addSubview:tile];
    
    [self.tileArray addObject:tile]; //add tile to array
    
    tile.index = currentTileCount; //set the tile index in the array
    [tile setTileText:[NSString stringWithFormat:@"%d", currentTileCount] clickText:@"clicked"]; //set the button text
    currentTileCount++; //increase the tile count
    
    //make the scroll view contain the tile
    if(tile.frame.origin.y + tileSize > _scrollview.frame.size.height)
    {
        _scrollview.contentSize = CGSizeMake(_scrollview.contentSize.width, tile.frame.origin.y + tileSize + tile_space/2);
        [_scrollview setContentOffset:CGPointMake(0, _scrollview.contentSize.height - _scrollview.frame.size.height)
                             animated:YES];
        
    }
    
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

- (void)handleFreeMove:(UILongPressGestureRecognizer *)sender
{
    TileButton *tile_btn = sender.view; //get the dragged tilebutton
    
    //method 1: exchange the adjacent tiles, the sequence of the array elements will be disorderd
    switch(sender.state)
    {
        case UIGestureRecognizerStateBegan:
            startPos = [sender locationInView:sender.view];
            originPos = tile_btn.center;
            [tile_btn tileSuspended];
            touchState = SUSPEND;
            preTouchID = tile_btn.index; //save the ID of pretouched title
            break;
        case UIGestureRecognizerStateChanged:
        {
            [tile_btn tileLongPressed];
            touchState = MOVE; //the tile will move
            CGPoint newPoint = [sender locationInView:sender.view];
            CGFloat offsetX = newPoint.x - startPos.x;
            CGFloat offsetY = newPoint.y - startPos.y;
            
            tile_btn.center = CGPointMake(tile_btn.center.x + offsetX, tile_btn.center.y + offsetY);
            
            //get the intersect tile ID
            int intersectID = -1;
            for(NSInteger i = 0; i < _tileArray.count; i++)
                if(tile_btn != _tileArray[i] && CGRectContainsPoint([_tileArray[i] frame], tile_btn.center))
                {
                    intersectID = i;
                    break;
                }
            
            if(intersectID != -1)
            {
                //swap every tile, the index remains unchanged
                __block TileButton *collisionButton = _tileArray[intersectID];
                __block CGPoint tempOriginPos = collisionButton.center; //the new origin point
                [UIView animateWithDuration:0.3 animations:^{
                    
                    collisionButton.center = originPos; //move the other title to the moved tile's origin pos
                    originPos = tempOriginPos; //save the temp origin point in case the block shake
                    
                }];
                
                //exchange the tile index of the array
                [_tileArray exchangeObjectAtIndex:tile_btn.index withObjectAtIndex:intersectID];
                
                //tile_btn still point to the moving tile, just swap the index
                int tempID = collisionButton.index;
                collisionButton.index = tile_btn.index;
                tile_btn.index = tempID;

            }
            
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            //   [tile_btn tileSuspended];
            [UIView animateWithDuration:0.3 animations:^{
                tile_btn.center = originPos;
            }];
            if(touchState == MOVE) //only if the pre state is MOVE, then settle, otherwise leave it suspend
            {
                touchState = UNTOUCHED;
                [tile_btn tileSettled]; //settle the tile to the new position(no need to use delay operation here)
            }
        }
            
            break;
        default:
            break;
    }
}

- (void)handleSequenceMove:(UILongPressGestureRecognizer *)sender
{
    TileButton *tile_btn = sender.view; //get the dragged tilebutton

    
    //method 2: move the tiles inorder like Alipay, the order in array remains in sequence always
    switch(sender.state)
    {
        case UIGestureRecognizerStateBegan:
            startPos = [sender locationInView:sender.view];
            originPos = tile_btn.center;
            [tile_btn tileSuspended];
            touchState = SUSPEND;
            preTouchID = tile_btn.index; //save the ID of pretouched title
            break;
        case UIGestureRecognizerStateChanged:
        {
            [tile_btn tileLongPressed];
            touchState = MOVE; //the tile will move
            CGPoint newPoint = [sender locationInView:sender.view];
            CGFloat offsetX = newPoint.x - startPos.x;
            CGFloat offsetY = newPoint.y - startPos.y;
            
            tile_btn.center = CGPointMake(tile_btn.center.x + offsetX, tile_btn.center.y + offsetY);
            
            //get the intersect tile ID
            int intersectID = -1;
            for(NSInteger i = 0; i < _tileArray.count; i++)
                if(tile_btn != _tileArray[i] && CGRectContainsPoint([_tileArray[i] frame], tile_btn.center))
                {
                    intersectID = i;
                    break;
                }
            
            if(intersectID != -1)
            {
                if(abs(intersectID - tile_btn.index) == 1) //if the tiles are adjacent then move directly
                {
                    __block TileButton *collisionButton = _tileArray[intersectID];
                    __block CGPoint tempOriginPos = collisionButton.center; //the new origin point
                    [UIView animateWithDuration:0.3 animations:^{
                        
                        collisionButton.center = originPos; //move the other title to the moved tile's origin pos
                        originPos = tempOriginPos; //save the temp origin point in case the block shake
                        
                    }];
                    
                    //exchange the tile index of the array
                    [_tileArray exchangeObjectAtIndex:tile_btn.index withObjectAtIndex:intersectID];
                    
                    //tile_btn still point to the moving tile, just swap the index
                    int tempID = collisionButton.index;
                    collisionButton.index = tile_btn.index;
                    tile_btn.index = tempID;
                    
                    
                    NSLog(@"tilebtn index:%d, intersect index:%d", [_tileArray[tile_btn.index] index], [_tileArray[collisionButton.index] index]);
                    
                }
                else if(intersectID - tile_btn.index >1) //move the tiles to the left in order
                {
                    CGPoint preCenter = originPos;
                    CGPoint curCenter;
                    //exchange the pointer in array and swap the index,at last the tile_btn is at the new right place
                    for(int i = tile_btn.index + 1; i <= intersectID; i++)
                    {
                        __block TileButton *movedTileBtn = _tileArray[i];
                        curCenter = movedTileBtn.center;
                        
                        [UIView animateWithDuration:0.3 animations:^{
                            movedTileBtn.center = preCenter;
                        }];
                        preCenter = curCenter; //save the precenter
                        
                        movedTileBtn.index--; //reduce the tile index
                        _tileArray[i-1] = movedTileBtn; //move the pointer one by one
                        
                        
                    }
                    originPos = preCenter;
                    tile_btn.index = intersectID; //exchange the ID
                    _tileArray[intersectID] = tile_btn; //now make the last pointer point to the tile_btn
                    NSLog(@"new tile btn index: %d", [_tileArray[tile_btn.index] index]);
                }
                else //move the tile to right in order
                {
                    CGPoint preCenter = originPos;
                    CGPoint curCenter;
                    //exchange the pointer in array and swap the index,at last the tile_btn is at the new right place
                    for(int i = tile_btn.index - 1; i >= intersectID; i--)
                    {
                        __block TileButton *movedTileBtn = _tileArray[i];
                        curCenter = movedTileBtn.center;
                        
                        [UIView animateWithDuration:0.3 animations:^{
                            movedTileBtn.center = preCenter;
                        }];
                        preCenter = curCenter; //save the precenter
                        
                        movedTileBtn.index++; //reduce the tile index
                        _tileArray[i+1] = movedTileBtn; //move the pointer one by one
                        
                    }
                    originPos = preCenter;
                    tile_btn.index = intersectID; //exchange the ID
                    _tileArray[intersectID] = tile_btn; //now make the last pointer point to the tile_btn
                    NSLog(@"new tile btn index: %d", [_tileArray[tile_btn.index] index]);
                }
                
                
                //test the display if the array is inorder
                for(TileButton *tile in _tileArray)
                    NSLog(@"tile text: %@", tile.titleLabel.text);
                
            }
            
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            //   [tile_btn tileSuspended];
            [UIView animateWithDuration:0.3 animations:^{
                tile_btn.center = originPos;
            }];
            if(touchState == MOVE) //only if the pre state is MOVE, then settle, otherwise leave it suspend
                [tile_btn tileSettled]; //settle the tile to the new position(no need to use delay operation here)
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
        [_tileArray[preTouchID] tileSettled]; //when don't move,clicke anywhere to settle the pretouched tile
        NSLog(@"suspend canceld");
    }
    else if(touchState == UNTOUCHED)
        NSLog(@"%@", button.titleLabel.text); //only when the tile is setted, can it be clicked to do sth

}

- (void)tileButtonClicked:(TileButton *)tileBtn
{
    //remove the button and adjust the tilearray
    
    NSLog(@"deletebutton delegate responds");
    
    //remember the deleted tile's infomation
    int startIndex = tileBtn.index;
    CGPoint preCenter = tileBtn.center;
    CGPoint curCenter;
    
    //[_tileArray removeObject:tileBtn]; //delete the tile
    //exchange the pointer in array and swap the index,at last the tile_btn is at the new right place
    for(int i = startIndex + 1; i < _tileArray.count; i++)
    {
        __block TileButton *movedTileBtn = _tileArray[i];
        curCenter = movedTileBtn.center;
        
        [UIView animateWithDuration:0.3 animations:^{
            movedTileBtn.center = preCenter;
        }];
        preCenter = curCenter; //save the precenter
        
        movedTileBtn.index--; //reduce the tile index
        _tileArray[i-1] = movedTileBtn; //move the pointer one by one
        
    }
    
    [_tileArray removeLastObject]; //every time remove the last object
    
    //must remove the tileBtn from the view
    [tileBtn removeFromSuperview]; //we can also use performselector so that button disappears with animation
    //test the display if the array is inorder
    for(TileButton *tile in _tileArray)
        NSLog(@"tile text: %@", tile.titleLabel.text);


}



@end
