//
//  EndViewController.m
//  Dungeons
//
//  Created by Ji Li on 2016-04-10.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EndViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface EndViewController()
{
    AVAudioPlayer *BGSound;
}

@end

@implementation EndViewController

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

