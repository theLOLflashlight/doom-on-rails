//
//  EndViewController.m
//  Dungeons
//
//  Created by Ji Li on 2016-04-10.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EndViewController.h"
#import "GameViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface EndViewController()
{
    AVAudioPlayer *BGSound;
}

@end

@implementation EndViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"GameToEnd"])
    {
        // Get reference to the destination view controller
        GameViewController *vc = [segue destinationViewController];
        
        vc.LevelIndex = _LevelIndex;
        //[vc setMyObjectHere:object];
    }
}

-(void)viewDidLoad
{
    
    //self.KillSum.text =[[NSString alloc] initWithFormat: @"%d", 11];
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"AND HIS NAME IS JOHN CENA" ofType:@"mp3"]];
    BGSound = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
    
    _KillSum.text = [NSString stringWithFormat: @"%d", _kills];
    
    [BGSound prepareToPlay];
    [BGSound play];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [BGSound stop];
}

@end

