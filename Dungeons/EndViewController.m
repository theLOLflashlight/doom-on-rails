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
#import <CoreData/CoreData.h>

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
        
        //Continue passing total score to the next gvc
        vc.GameTotalScore = [self.GameTotalScore.text intValue]; //Convert UILabel string of GameTotalScore to int
        
        vc.LevelIndex = _LevelIndex % 3;
        //[vc setMyObjectHere:object];
    }
}

-(void)viewDidLoad
{
    
    //self.KillSum.text =[[NSString alloc] initWithFormat: @"%d", 11];
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"AND HIS NAME IS JOHN CENA" ofType:@"mp3"]];
    BGSound = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
    
    _KillsScore.text = [NSString stringWithFormat: @"%d", _KillsScoreV];
    _ShotsScore.text = [NSString stringWithFormat: @"%d", _ShotsScoreV];
    _FBGsLeftScore.text = [NSString stringWithFormat: @"%d", _FBGsLeftScoreV];
    _HealthScore.text = [NSString stringWithFormat: @"%d", (100 - _HealthScoreV)]; //Actually damage taken, hard-coded from health score
    _LevelScore.text = [NSString stringWithFormat: @"%d", _LevelScoreV];
    //_LevelHighScore.text = [NSString stringWithFormat: @"%d", _LevelHighScoreV];
    _GameTotalScore.text = [NSString stringWithFormat: @"%d", _GameTotalScoreV];
    _KillsScoreCalc.text = [NSString stringWithFormat: @"%d", _KillsScoreV * 100]; //hard-coded multiplier value
    _ShotsScoreCalc.text = [NSString stringWithFormat: @"%d", _ShotsScoreV * -20]; //hard-coded multiplier value
    _FBGsScoreCAlc.text = [NSString stringWithFormat: @"%d", _FBGsLeftScoreV * 600]; //hard-coded multiplier value
    _HealthScoreCalc.text = [NSString stringWithFormat: @"%d", (100 - _HealthScoreV) * -60]; //hard-coded multiplier value
    
    [BGSound prepareToPlay];
    [BGSound play];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [BGSound stop];
}

@end

