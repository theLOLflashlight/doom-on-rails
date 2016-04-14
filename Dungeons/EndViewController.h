//
//  EndViewController.h
//  Dungeons
//
//  Created by Ji Li on 2016-04-10.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#ifndef EndViewController_h
#define EndViewController_h

#import <UIKit/UIKit.h>

@interface EndViewController : UIViewController
{
    
}

@property (nonatomic) int KillsScoreV;
@property (nonatomic) int ShotsScoreV;
@property (nonatomic) int FBGsLeftScoreV;
@property (nonatomic) int HealthScoreV;
@property (nonatomic) int LevelScoreV;
@property (nonatomic) int LevelHighScoreV;
@property (nonatomic) int GameTotalScoreV; //Jacob: error with this, having been passed to the label or vice versa, perhaps when this were not initialized or when some function were missing and it were trying to access a function to a label, or trying to use this as a UILabel but it not having the UILabel functions in passing to the storyboard
@property (weak, nonatomic) IBOutlet UILabel *GameTotalScore;
@property (weak, nonatomic) IBOutlet UILabel *KillsScore;
@property (weak, nonatomic) IBOutlet UILabel *ShotsScore;
@property (weak, nonatomic) IBOutlet UILabel *FBGsLeftScore;
@property (weak, nonatomic) IBOutlet UILabel *HealthScore;
@property (weak, nonatomic) IBOutlet UILabel *LevelScore;
@property (weak, nonatomic) IBOutlet UILabel *LevelHighScore;
@property (weak, nonatomic) IBOutlet UILabel *KillsScoreCalc;
@property (weak, nonatomic) IBOutlet UILabel *ShotsScoreCalc;
@property (weak, nonatomic) IBOutlet UILabel *FBGsScoreCAlc;
@property (weak, nonatomic) IBOutlet UILabel *HealthScoreCalc;
@property (nonatomic) int LevelIndex;

@end
#endif /* EndViewController_h */
