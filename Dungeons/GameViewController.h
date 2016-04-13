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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;

@property (nonatomic) bool MusicOn;

@property (weak, nonatomic) IBOutlet UILabel *KillNumber;
@property (weak, nonatomic) IBOutlet UILabel *Health;
@property (weak, nonatomic) IBOutlet UILabel *Ammo;

- (IBAction)SoundButton:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UIButton *SoundButtonEffects;
- (IBAction)Reload:(UIButton *)sender;

@end
