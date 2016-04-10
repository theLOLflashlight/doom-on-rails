//
//  GameViewController.h
//  Dungeons
//
//  Created by Andrew Meckling on 2016-03-22.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface GameViewController : GLKViewController
{
    
}

@property (weak, nonatomic) IBOutlet UIView *HUD;
@property (nonatomic, retain) bool MusicOn;

@end
