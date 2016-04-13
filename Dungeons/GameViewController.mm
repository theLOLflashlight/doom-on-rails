//
//  GameViewController.m
//  Dungeons
//
//  Created by Andrew Meckling on 2016-03-22.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import "GameViewController.h"
#import "EndViewController.h"
#import <OpenGLES/ES3/glext.h>
#import <AVFoundation/AVFoundation.h>
#import "Game.h"
#import "BulletPhysics.h"
#import "GameCppVariables.hpp"
#import "EndViewController.h"
#include "ios_path.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define SFXINSTANCES 5
#define NSPoint CGPoint
#define NSUInteger UInt
#define MAX_CHANNELS 30

#define BULLET_MIN 1000
#define BULLET_MAX 3000

struct Enemy_Basic
{
    Game* gameptr;
    GameViewController *gvc;
    float velocity; //because glm uses floats apparently
    
    explicit Enemy_Basic( Game* game, GameViewController* gvc )
        : gameptr( game )
        , gvc( gvc )
    {
    }
    
    void operator()(BehavioralComponent* c, EntityCollection& entities, double time);
    
};


@interface GameViewController ()
{
    //__weak IBOutlet UIImageView *RedImageOverlay;
    bool SoundSwitch;
    
    int AmmoNumber;
    bool ReLoad;
    int Kills;
    AVAudioPlayer *ReloadSound;
    AVAudioPlayer *KillsSound;
    bool getkill;
    
    Game*       _game;
    uint16_t    _bulletId;
    uint16_t    _bfgId;
    Sprite*     _projectileSprite;
    Sprite*     _bfgProjectileSprite;
    
    //AVAudioPlayer *GunSoundEffects;
    AVAudioPlayer *GunSoundEffects[MAX_CHANNELS];
    int _CurrentChannel;
    
    //For swipe action.
    CGFloat _maxRadius;
    //var _maxTranslationY : CGFloat = 0;
    CGFloat _prevTranslationX; //for drawing lines
    CGFloat _prevTranslationY;
    NSMutableArray *_translationPoints;
    bool _noSwipe;
    bool _swipeHit;
    
    CGRect screenSize;// : CGRect = UIScreen.mainScreen().bounds;
    CGSize imageSize;// = CGSize(width: 200, height: 200); //arbitrary initialization
    UIImageView * _imageView;// = UIImageView();
    
    UIBezierPath* _myBezier;// = UIBezierPath();
    CGFloat bezierDuration;// = Float(1); //duration of bezier on screen (in seconds)
    
    //to track swipe running or not
    CGFloat _currBezierDuration;// = -0.00001; //hard-coded time below 0
    bool _currSwipeDrawn;// = false;
    
    
    //For camera, swipe
    //Camera stuff
    CGFloat _baseHorizontalAngle, _baseVerticalAngle;
    CGFloat currHorizontalAngle, currVerticalAngle;
    CGFloat rotationSpeed;
    /* //original swift code
     var modelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity
     var normalMatrix: GLKMatrix3 = GLKMatrix3Identity
     
     var modelViewMatrix: GLKMatrix4 = GLKMatrix4Identity
     
     //Accessible static var - position
     static var position: GLKVector3 = GLKVector3Make(0, 0.5, 5)
     var direction: GLKVector3 = GLKVector3Make(0,0,0)
     var up: GLKVector3 = GLKVector3Make(0, 1, 0)
     
     
     var currProjectileCoord: UILabel!;
     
     var horizontalMovement: GLKVector3 = GLKVector3Make(0, 0, 0)
     var _baseHorizontalAngle : Float = 0
     var _baseVerticalAngle : Float = 0
     var currhorizontalAngle: Float = 0
     var currverticalAngle: Float = 0
     
     var rotationSpeed: Float = 0.005
     
     var vertexArray: GLuint = 0
     var vertexBuffer: GLuint = 0
     
     var context: EAGLContext? = nil
     var effect: GLKBaseEffect? = nil
     
     var _myBezier = UIBezierPath();
     
     let bezierDuration = Float(1); //duration of bezier on screen (in seconds)
     
     //to track swipe running or not
     var _currBezierDuration = -0.00001; //hard-coded time below 0
     var _currSwipeDrawn = false;
     */
    //End of for camera, swipe
    
    //For sound - Apr 9
    //sound setup
    
    
    //NSDate *_lastDate[64];
    /* //Original swift code
     // Grab the path, make sure to add it to your project!
     let filePath = "footsteps_gravel";
     var sound : NSURL = NSBundle.mainBundle().URLForResource("footsteps_gravel", withExtension: "wav")!;
     //var audioPlayer = AVAudioPlayer()
     var mySound: SystemSoundID = 0;
     public var themePlayer : AVAudioPlayer!;
     var soundPlayer : AVAudioPlayer!;
     var soundPlayer2 : AVAudioPlayer!;
     
     //Make an arraylist keeping track of each audio played, and remove each AVPAudioPlayer from the arraylist as each of them has completed its track, is the plan - though, still have to figure out how to set delegate and such, as to-do.
     //
     var AVAudioPlayers : [AVAudioPlayer] = [];
     
     //For other iOS stuff.
     typealias NSPoint = CGPoint;
     typealias NSUInteger = UInt;
     
     var _lastDate = [NSDate?](count: 64, repeatedValue: nil);
     */
    //End of for sound - Apr 9
    
    AVAudioPlayer *soundPlayer, *soundPlayer2;
    AVAudioPlayer *themePlayer;
    
    
    //Make an arraylist keeping track of each audio played, and remove each AVPAudioPlayer from the arraylist as each of them has completed its track, is the plan - though, still have to figure out how to set delegate and such, as to-do.
    //
    AVAudioPlayer *AVAudioPlayers[5];
    
    //For other iOS stuff.
    //typedef CGPoint NSPoint;
    //typedef UInt8 NSUInteger;
    
    //SystemSoundID *mySound = 0;
    //UILabel *currProjectileCoord; //Swift: var currProjectileCoord: UILabel!;
    
    NSDate *_lastDate[64];
    GameCppVariables GCV;
    
    UIImage *_image;
    UIImage *_anImage;
    //NSMutableArray *_toBeDeleted; //no longer used
    
    //For explosion
    //btSphereShape _explosionSphere; //Can ask Andrew how to do this later.
}

@property (strong, nonatomic) EAGLContext* context;

@end

@implementation GameViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"GameToEnd"])
    {
        // Get reference to the destination view controller
        EndViewController *vc = [segue destinationViewController];
      
        // Pass any objects to the view controller here, like...
        vc.KillSum.text = [NSString stringWithFormat:@"%d", Kills];
        //[vc setMyObjectHere:object];
    }
}

//Tap handling - spawn projectile
- (void) handleTapGesture:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized)
    {
        using namespace glm;
        const CGPoint mouse = [sender locationInView:self.view];
        
        const mat4 view = _game->viewMatrix();
        const mat4 proj = _game->projMatrix();
        const vec4 viewport = _game->viewport();
        
        vec3 touchPos0 = unProject( vec3( mouse.x, -mouse.y, 0 ), view, proj, viewport );
        vec3 touchPos1 = unProject( vec3( mouse.x, -mouse.y, 1 ), view, proj, viewport );
        
        if(AmmoNumber>0)
        {
            [self spawn_projectile: touchPos0 velocity: normalize( touchPos1 - touchPos0 ) * 50.0f homeInOnPlayer:false damage:100];
            AmmoNumber --;
        }
        
        //[self explosionAt: _game->_eyepos];
        
        if(AmmoNumber == 0)
        {
            ReLoad = true;
            [ReloadSound play];
        }
    }
}

- (void)viewDidLoad
{
    SoundSwitch = true;
    ReLoad = false;
    
    _MusicOn = true;
    
    AmmoNumber = 10;
    Kills = 0;

    getkill = true;
    
    
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES3];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    //auto groundShape = new btStaticPlaneShape( btVector3( 0, 1, 0 ), 0 );
    //auto groundMotionState = new btDefaultMotionState();
    //btRigidBody::btRigidBodyConstructionInfo groundRigidBodyCI( 0, groundMotionState, groundShape, btVector3(0,0,0) );
    //auto groundRigidBody = new btRigidBody(groundRigidBodyCI);
    //[_physics addRigidBody: groundRigidBody];
    //RedImageOverlay.alpha = 0;
    //RedImageOverlay.hidden = YES;
    CGRect newFrame = CGRectMake(2000, 2000, 200, 200);
    //RedImageOverlay.frame = newFrame;
    //RedImageOverlay.;
    
    //Using apple's tutorial, ie. https://developer.apple.com/library/ios/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/HandlingImages/Images.html
    /*NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"RedDamageOverlay" ofType:@"png"];
    UIImage *myImageObj = [[UIImage alloc] initWithContentsOfFile:imagePath];
    _anImage = myImageObj;
    */
    
    //tap
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    //Swipe
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [panGesture setMinimumNumberOfTouches:1];
    [panGesture setMaximumNumberOfTouches:1];
    [self.view addGestureRecognizer:panGesture];
    
    //play looping sound
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];
    
    switch ( _LevelIndex )
    {
        case 0:
            _game = new Game( (GLKView*) self.view, "Level0Layout.obj", "Level0EnemyAPos.obj", "Level0EnemyBPos.obj", "Level0Rail.obj", "mar", glm::vec3( 0.766, 0.259, 0.643 ), glm::vec4( 1, 1, 0, 0.5 ), 2 );
            break;
        case 1:
            _game = new Game( (GLKView*) self.view, "Level1Layout.obj", "Level1EnemyAPos.obj", "Level1EnemyBPos.obj", "Level1Rail.obj", "cp", glm::vec3( 0.342, 0.866, -0.940 ), glm::vec4( 0, 0.5, 1, 0.5 ), 3 );
            break;
            
        case 2:
            _game = new Game( (GLKView*) self.view, "Level2Layout.obj", "Level2EnemyAPos.obj", "Level2EnemyBPos.obj", "Level2Rail.obj", "mercury", glm::vec3( 0, 1, 0 ), glm::vec4( 1, 0.2, 0, 0.5 ), 4 );
            break;
        case 3:
            //game over
            break;
    }
    
    BehavioralComponent endGame( "endGame" );
    endGame.functor = [self](BehavioralComponent*, EntityCollection&, double time)
    {
        if ( time > 64 )
        {
            EndViewController* endController = [self.storyboard instantiateViewControllerWithIdentifier: @"EndViewController"];
            
            endController.kills = Kills;
            endController.LevelIndex = _LevelIndex + 1;
            [self presentViewController: endController animated: YES completion: nil];
        }
    };
    _game->addComponent( endGame );
    
    _game->killCountPtr = &Kills;
    
    _projectileSprite = new Sprite( ios_path( "fireball/fireball.png" ), &_game->_fireProgram );
    _bfgProjectileSprite = new Sprite( ios_path( "fireball/fireball.png" ), &_game->_fireProgram );
    _bfgProjectileSprite->width = 4;
    _bfgProjectileSprite->height = 4;
    
    _bulletId = 0;
    _bfgId = 0;
    
    _CurrentChannel = 0;
    
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"GunSoundEffect_1" ofType:@"wav"]];
    
    for(int i = 0; i < MAX_CHANNELS; i++) {
        
        GunSoundEffects[i] = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
        
        [GunSoundEffects[i] prepareToPlay];
        
        
    }
    if (_MusicOn)
    {
        UIImage *SoundButtonImage = [UIImage imageNamed:@"SoundOn.png"];
        [self.SoundButtonEffects setImage:SoundButtonImage forState:(UIControlStateNormal)];
    }
    else
    {
        UIImage *SoundButtonImage = [UIImage imageNamed:@"SoundOff.png"];
        [self.SoundButtonEffects setImage:SoundButtonImage forState:(UIControlStateNormal)];
    }
    
    //Initialization of variables
    screenSize = [[UIScreen mainScreen] bounds];// : CGRect = UIScreen.mainScreen().bounds;
    imageSize = CGSizeMake(200, 200);// = CGSize(width: 200, height: 200); //arbitrary initialization
    _myBezier = [[UIBezierPath alloc] init];// = UIBezierPath();
    bezierDuration = 1;// = Float(1); //duration of bezier on screen (in seconds)
    //to track swipe running or not
    _currBezierDuration= -0.00001;// = -0.00001; //hard-coded time below 0
    _currSwipeDrawn = false;// = false;
    //_imageView.image = [UIImage imageNamed:@"RedDamageOverlay.jpeg"]; //image
    BehavioralComponent enemy("enemy");
    
    //[NSDate?](count: 64, repeatedValue: nil)
    
    self.KillNumber.text =[[NSString alloc] initWithFormat: @"%d", Kills];
    self.Health.text =[[NSString alloc] initWithFormat: @"%d", 100];
    self.Ammo.text =[[NSString alloc] initWithFormat: @"%d", AmmoNumber];
    
    NSData *RlSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"reload" ofType:@"mp3"]];
    ReloadSound = [[AVAudioPlayer alloc]initWithData:RlSoundPath error:nil];
    
    [ReloadSound setVolume:10];
    [ReloadSound prepareToPlay];
    
    //Indexing is disabled;
    
     //BehavioralComponent enemy( "enemy1" ); //basic enemy - shoots projectiles periodically every 3 seconds
     enemy.timeInCycle = 0;
     enemy.endTimeInCycle = 180;
    
    //_explosionSphere = btSphereShape(5.0); //Can ask Andrew how to do this later.
}



//Starts upon appear
- (void)viewDidAppear:(BOOL)animated
{
    //play looping sound
    if(_MusicOn) {
        [self ThemeSound];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    if(_MusicOn) {
        [themePlayer stop];
    }
}

- (void)viewDidLayoutSubviews
{
    
    //        UIBlurEffect *blurEffect = [UIBlurEffect s];
    //        UIVisualEffectView *blurEffectView = UIVisualEffectView( effect: blurEffect );
    //        UIVisualEffectView *vibeEffectView = UIVisualEffectView( effect: UIVibrancyEffect( forBlurEffect: blurEffect ) );
    //
    //        blurEffectView.frame = Hud.bounds
    //        vibeEffectView.frame = Hud.bounds
    //
    //        blurEffectView.addSubview( vibeEffectView )
    //        Hud.insertSubview( blurEffectView, atIndex: 0 )
    
    //Update image for (originally lines, but then now) image
    
}

- (void)handlePanGesture: (UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    CGPoint location = [recognizer locationInView:self.view];
    
    //Actually, just get furthest radius from the origin.
    GLKVector2 radiusVec = GLKVector2Make(translation.x, translation.y);
    CGFloat radLength = GLKVector2Length(radiusVec);
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        _maxRadius = 0;
        _noSwipe = false;
        [_translationPoints removeAllObjects];
    }
    
    
    if(radLength > _maxRadius) {
        _maxRadius = radLength;
    }
    
    //cancel gesture if moving backwards from the furthest radius from the origin (as opposed to total translation) by 6px.
    //So yes, you can zigzag a lot if you wanted to.
    if(radLength < _maxRadius - 6) {
        if(!_noSwipe) {
            using namespace glm;
            const CGPoint mouse = [recognizer locationInView:self.view];
            
            const mat4 view = _game->viewMatrix();
            const mat4 proj = _game->projMatrix();
            const vec4 viewport = _game->viewport();
            
            vec3 touchPos0 = unProject( vec3( mouse.x, -mouse.y, 0 ), view, proj, viewport );
            vec3 touchPos1 = unProject( vec3( mouse.x, -mouse.y, 1 ), view, proj, viewport );
            
            [self spawn_projectile: touchPos0 velocity: normalize( touchPos1 - touchPos0 ) * 50.0f homeInOnPlayer:false damage:100];
        }
        _noSwipe = true;
        //[self explosionAt: _game->_eyepos];
    }
    
    //On lift finger
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        if(radLength >= 80) { //valid swipe
            NSString *swipeSound;
            NSString *swipeSoundExt = @"mp3";
            if(_swipeHit) {
                swipeSound = @"sword-clash1";
            }
            else {
                swipeSound = @"swipe_whiff";
            }
            
            if(NSString *path = [[NSBundle mainBundle] pathForResource:swipeSound ofType: swipeSoundExt]) { //J: Not sure about this conversion from swift
                NSURL *soundURL = [NSURL fileURLWithPath:path]; //Can check this code later ...
                
                NSError *error;
                try { //J: Not sure about this conversion from Swift
                    soundPlayer2 = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)soundURL error:nil];
                    [soundPlayer2 prepareToPlay];
                    [soundPlayer2 play];
                }
                catch(NSException *exception) {
                }
            }
            _currBezierDuration = bezierDuration;
            _currSwipeDrawn = true;
            
            /*
            //
            //   apply a force on all objects
            //
            for (int i = 0; i < m_phantom->getOverlappingCollidables().getSize(); i++ )
            {
                hkpCollidable* c = m_phantom->getOverlappingCollidables()[i];
                if ( c->getType() == hkpWorldObject::BROAD_PHASE_ENTITY )
                {
                    // Apply linear impulse on rigid bodies
                }
            }
             */
            using namespace glm;
            const CGPoint mouse = [self midpointEnds:_translationPoints];
            
            const mat4 view = _game->viewMatrix();
            const mat4 proj = _game->projMatrix();
            const vec4 viewport = _game->viewport();
            
            vec3 touchPos0 = unProject( vec3( mouse.x, -mouse.y, 0 ), view, proj, viewport );
            vec3 touchPos1 = unProject( vec3( mouse.x, -mouse.y, 1 ), view, proj, viewport );
            
            glm::vec3 createPos = touchPos0 /*+ normalize( touchPos1 - touchPos0 )*/; //position to create the explosion
            glm::vec3 velocity = normalize( touchPos1 - touchPos0 ) * 100.0f;
            
            //glm::vec3 fwdDisplacement = glm::normalize(_game->_eyelook - _game->_eyepos) *1.0f;
            //glm::vec3 oPos =_game->_eyepos + fwdDisplacement;
            //[self explosionImpact:createPos velocity:velocity radius:2.0f];
            
            //[self spawn_projectile: touchPos0 velocity: normalize( touchPos1 - touchPos0 ) * 50.0f homeInOnPlayer:false damage:100];
            
            //bullet.body->setLinearVelocity( { vel.x, vel.y, vel.z } );
        }
        else {
            //If having lifted, but not having done a swipe cancel in the current 'swipe attempt'
            if (!_noSwipe) {
                using namespace glm;
                const CGPoint mouse = [recognizer locationInView:self.view];
                
                const mat4 view = _game->viewMatrix();
                const mat4 proj = _game->projMatrix();
                const vec4 viewport = _game->viewport();
                
                vec3 touchPos0 = unProject( vec3( mouse.x, -mouse.y, 0 ), view, proj, viewport );
                vec3 touchPos1 = unProject( vec3( mouse.x, -mouse.y, 1 ), view, proj, viewport );
                
                [self spawn_projectile: touchPos0 velocity: normalize( touchPos1 - touchPos0 ) * 50.0f homeInOnPlayer:false damage:100];
                
                //[self explosionAt: _game->_eyepos];
            }
        }
        _noSwipe = false;
    }
    
    //draw line
    //ie. create the _translationPoints
    if(!_noSwipe) {
        //From stackoverflow ...
        [_translationPoints addObject:[NSValue valueWithCGPoint:CGPointMake(location.x, location.y)]];
    }
    //print("radLength: \(radLength); _maxRadius: \(_maxRadius)");
    
    
    
    //let point: CGPoint = recognizer.translationInView(self.view)
    
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        //_prevHorizontalAngle
        _baseHorizontalAngle += currHorizontalAngle; //had missed the + increment over the previous ...
        _baseVerticalAngle += currVerticalAngle;
        //currhorizontalAngle = 0;
        //currverticalAngle = 0;
    }
    currHorizontalAngle = -translation.x * rotationSpeed;
    currVerticalAngle = translation.y * rotationSpeed;
}

//Iterate thru translationPoints or any otherwise pointArray, get the midpoint of them
-(CGPoint) midpoint: (NSMutableArray *)pointArray {
    CGPoint midPoint;
    for(int i=0; i<pointArray.count; i++) {
        
        //get each CGPoint
        NSValue *locationValue = [pointArray objectAtIndex:i];
        CGPoint location = locationValue.CGPointValue;
        midPoint.x += location.x;
        midPoint.y += location.y;
    }
    
    midPoint.x /= pointArray.count;
    midPoint.y /= pointArray.count;
    
    return midPoint;
}
-(CGPoint) midpointEnds: (NSMutableArray *)pointArray {
    CGPoint midPoint;
    int i = 0;
    //add start and end points and average only those
    NSValue *locationValue = [pointArray objectAtIndex:i];
    CGPoint location = locationValue.CGPointValue;
    midPoint.x += location.x;
    midPoint.y += location.y;
    
    i = pointArray.count - 1;
    
    locationValue = [pointArray objectAtIndex:i];
    location = locationValue.CGPointValue;
    midPoint.x += location.x;
    midPoint.y += location.y;
    
    
    midPoint.x /= 2;
    midPoint.y /= 2;
    
    return midPoint;
}

/*
 @IBAction func MoveCamera(sender: UIButton) {
 GameViewController.position = GLKVector3Subtract(GameViewController.position, direction)
 }
 */

//J: Start of Swift code/functions to be converted as of Apr 9



//Time since the last iteration of calling this method. Original intention is for running the code, and tracking time independently of frame rate.
//Each place in code calling this is to use a different Int for 'closest-to-accurate' results (though it would not include the time after retrieving the time and updating the time, so the value would be less, or not include the time spent in retrieving the NSDate before retrieving timeDiff, ie. timeDiff would not include such time).
- (double)timeSinceLastIter: (int)timePointIndex {
    NSDate *newTime = [[NSDate alloc] init];
    double timeDiff = 0; //this would be the first time; there would be no time before this one occurred.
    int lastDateCount = (sizeof(_lastDate) / sizeof(_lastDate[0]));
    if(timePointIndex < lastDateCount) {
        if(_lastDate[timePointIndex] != nil) { //if an NSDate exists, then do the following
            timeDiff = [newTime timeIntervalSinceDate:_lastDate[timePointIndex]]; //Had a "!" in the Swift version, but this is pretty much what Objective-C already does - ie. assume the existence of the object //provided misleading error info - where I declared timeDiff resolved an error of 'not matching array type' apparently
        }
    }
    //if let timeDiff = newTime.timeIntervalSinceDate(_lastDate[timePointIndex]);
    
    /* //Not doing this in Objective-C. Simply make a precondition restricting to 64 elements instead.
     //append array elements such that this array would be long enough to store the element at timePointIndex
     if(!(timePointIndex < _lastDate.count)) {
     _lastDate = _lastDate + [NSDate?](count: timePointIndex - (_lastDate.count - 1), repeatedValue: nil);
     }
     */
    _lastDate[timePointIndex] = newTime;
    return timeDiff;
}

//For drawing lines - from http://stackoverflow.com/questions/25229916/how-to-procedurally-draw-rectangle-lines-in-swift-using-cgcontext

/*
 - (UIImage *) drawSwipeLine : (CGSize) size {
 // Setup our context
 let bounds = CGRect(origin: CGPoint.zero, size: size)
 let opaque = false
 let scale: CGFloat = 0
 UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
 let context = UIGraphicsGetCurrentContext()
 
 // Setup complete, do drawing here
 CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
 CGContextSetLineWidth(context, 4.0)
 
 CGContextStrokeRect(context, bounds)
 
 CGContextBeginPath(context)
 
 
 let timesinceLast = timeSinceLastIter(0);
 if(!_noSwipe) { //condition to erase line if swipe ended
 //Draw bezier
 //Maybe a cubic bezier curve?
 _myBezier = UIBezierPath()
 let myMicroBezier = UIBezierPath();
 
 //Set control points c0, c1, c2, and c3 for the path myBezierPath()
 var c0, c1, c2, c3 : CGPoint;
 let bezierInterval = 3; //have to make sure this is divisible by 3.
 //myBezier.moveToPoint(CGPoint(x: 0,y: 0));
 if(!(_translationPoints.count < 1)) {
 //initialization
 //c0 = _translationPoints[0]; //adding this because xcode is stupid
 c1 = _translationPoints[0];
 c2 = _translationPoints[0];
 c3 = _translationPoints[0]; //set origin point
 //var currCurvePos = 1;
 
 //draw each line, as evident from _translationPoints
 for(var i=1; i < _translationPoints.count; i++) {
 //CGContextMoveToPoint(context, _translationPoints[i-1].x, _translationPoints[i-1].y);
 
 //build bezier curve
 if(i%(bezierInterval/3) == 0) { //every point, add a new control point to bezier curve
 //shift all of the control points by one
 c0 = c1;
 c1 = c2;
 c2 = c3;
 c3 = _translationPoints[i];
 
 //draw the c0,c1,c2,c3 bezier curve every 3 additional control points.
 if(i%(bezierInterval) == 0) { //becomes 0 ... making sometimes a straight line ... maybe the 'last line' being different in how Bezier might handle it? Oh, it's because of the closePath, and that apparently applying to addCurveToPoint ...
 _myBezier.moveToPoint(c0);
 _myBezier.addCurveToPoint(c3, controlPoint1: c1, controlPoint2: c2);
 }
 }
 
 //get values greater than those truncated from dividing by bezierInterval, ie. values greater than the highest value quantized by bezierInterval, and draw normally according to that
 let highestQuantizedVal = (_translationPoints.count / bezierInterval) * bezierInterval;
 if(i > highestQuantizedVal) {
 myMicroBezier.moveToPoint(_translationPoints[i-1]);
 myMicroBezier.addLineToPoint(_translationPoints[i]);
 }
 //CGContextAddLineToPoint(context, _translationPoints[i].x, _translationPoints[i].y);
 }
 
 //draw bezier curve from those control points
 _myBezier.lineWidth = 5;
 //Maybe error occurs when trying to access c0 when c0 would no longer exist, ie. be out of scope?
 //myBezier.addClip();
 //myBezier.closePath() //may be the cause
 UIColor.redColor().setStroke();
 
 //myMicroBezier.lineWidth = 5;
 //UIColor.greenColor().setStroke();
 //myMicroBezier.stroke();
 }
 }
 //Fading swipe effect
 if(_currBezierDuration >= 0 && _currSwipeDrawn) {
 _currBezierDuration -= timesinceLast; //reserving 0 for this
 
 //fade only halfway through the swipe
 let alpha = min(1, Float(_currBezierDuration)/Float(bezierDuration * 0.66));
 UIColor(red: 1,green: 0, blue: 0, alpha:CGFloat(alpha)).setStroke();
 _myBezier.stroke();
 
 if(_currBezierDuration <= 0) {
 _translationPoints.removeAll();
 _currSwipeDrawn = false;
 }
 }
 //draw min to max - so, diagonally
 //        CGContextMoveToPoint(context, CGRectGetMaxX(bounds), CGRectGetMinY(bounds))
 //        CGContextAddLineToPoint(context, CGRectGetMinX(bounds), CGRectGetMaxY(bounds))
 //CGContextStrokePath(context)
 
 // Drawing complete, retrieve the finished image and cleanup
 let image = UIGraphicsGetImageFromCurrentImageContext()
 UIGraphicsEndImageContext()
 return image
 }
 */
-(void) ThemeSound {
    NSString *path;
    switch ( _LevelIndex )
    {
        case 0:
            path = [[NSBundle mainBundle] pathForResource:@"Doom3 Level 1" ofType: @"mp3"];;
            break;
        case 1:
            path = [[NSBundle mainBundle] pathForResource:@"Doom3 Level 2" ofType: @"mp3"];;
            break;
        case 2:
            path = [[NSBundle mainBundle] pathForResource:@"Doom3 Level 3" ofType: @"mp3"];;
            break;
    }
    
        NSURL *soundURL = [NSURL fileURLWithPath:path]; //Can check this code later ...
        
  
            themePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)soundURL error:nil];
            [themePlayer prepareToPlay];
            themePlayer.numberOfLoops = -1;
            [themePlayer play];
  
    
}


//Jacob: Shake input handler
-(void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) { //just having earthquake for now
        //shake method here
        //Cast spell
        
        GCV.animationProgress = 0; //begins the animation of earthquake
        
        if(AmmoNumber != 10)
        {
            ReLoad= true;
            [ReloadSound play];
        }
        
        //Right now, it simply shakes the camera, but maybe shaking the world instead could be considered?
    }
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    delete _game;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil))
    {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
    
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
}

- (void) damagePlayer: (int)damage {
    int healthInt = [self.Health.text intValue]; //string to int
    //_anImage = 0.7;
    self.Health.text = [NSString stringWithFormat:@"%d", healthInt - damage]; //int to string to update health
    //implement flickering of health
}

- (void)drawRect:(CGRect)rect {
    CGContextRef myContext = UIGraphicsGetCurrentContext();
    // Do your drawing in myContext
    // draw anImage - using Apple's tutorial
    [_anImage drawAtPoint:CGPointMake(0, 500)];
}


- (void) spawn_projectile:( glm::vec3 )pos velocity:( glm::vec3 ) vel homeInOnPlayer: (bool)targetPlayer damage: (int)damage
{
    const EntityId bulletId( "bullet", _bulletId++ );
    {
        GraphicalComponent bullet( bulletId, GraphicalComponent::TRANSLUCENT );
        bullet.asset = _projectileSprite;
        
        _game->addComponent( bullet );
    }
    {
        
        PhysicalComponent bullet( bulletId );
        
        auto motionState = new btDefaultMotionState(
                                                    btTransform( btQuaternion( 0,0,0,1 ), btVector3( pos.x, pos.y, pos.z ) ) );
        
        static btSphereShape SPHERE_SHAPE( 0.5 );
        bullet.body = new btRigidBody( 1, motionState, &SPHERE_SHAPE );
        
        bullet.body->setLinearVelocity( { vel.x, vel.y, vel.z } );
         
        
        //[_physics addRigidBody: bullet.body];
        _game->addComponent( bullet );
        //_game->findPhysicalComponent( bulletId )->active = false;
        
        BehavioralComponent bulletBc(bulletId);
        
        
        //For projectiles targeting the player, have specific behaviour for the bullet
        if(false) {
            
            bulletBc.functor = [targetPlayer, damage, bulletId, vel, self](BehavioralComponent *bc, EntityCollection& entities, double time) {
                //operator() of the function
                Entity *ntt = &(entities[ bc->entityId ]);
                
                //if distance between projectile and camera <= velocity + player velocity (ie. if it is at most the max amount that it could be from a player, perhaps, though considering player movement at the same time
                //though, can just hardcode it as 2.5 * velocity, with the precondition that player velocity is at most 1.5x the projectile's velocity for this to work 100% of the time
                //Actually, hardcoding projectile max distance entirely.
                if(glm::length(ntt->position - _game->_eyepos) <= 1) {
                    //do damage, eliminate projectile and damage player
                    [self damagePlayer:damage];
                }
                
                //after a positional physics update
                glm::vec3 vecDir = _game->_eyepos - ntt->position; //target player
                glm::normalize(vecDir);
                glm::vec3 projVelocity = vecDir * glm::length(vel); //scale according to magnitude of vel
                
                
                glm::vec3 oPos =_game->_eyepos + (_game->_eyelook - _game->_eyepos)/3.0f;
                ntt->position = oPos;
                NSLog(@"code is being run through, for bulletID: %d", bulletId);
                
                PhysicalComponent *pc = _game->findPhysicalComponent(bulletId);
                pc->body->setLinearVelocity(btVector3(projVelocity.x, projVelocity.y, projVelocity.z));
            };
        }
        else {
            /*
            //Default functor, used for debug purposes of understanding how this works
            //Looks like this functor isn't working either.
            bulletBc.functor =[self, bulletId](BehavioralComponent *bc, EntityCollection& entities, double time) {
                //NSLog(@"BulletID %d posn: ", bulletId);
                glm::vec3 oPos =_game->_eyepos + (_game->_eyelook - _game->_eyepos)/3.0f;
                Entity *ntt = &(entities[bc->entityId]);
                ntt->position = oPos;
                NSLog(@"code is being run through, for bulletID: %d", bulletId);
            };
             */
        }
        //_game->addComponent(bulletBc);
        
    }
    {
        BehavioralComponent bullet( bulletId );
        
        double startTime = -1;
        bullet.functor = [self, startTime](BehavioralComponent* bc, EntityCollection& entities, double time)
        mutable {
            const double MAX_LIFETIME = 3;
            const EntityId entityId = bc->entityId;
            
            if ( startTime < 0 )
                startTime = time;
            
            const double lifetime = time - startTime;
            
            if ( lifetime > MAX_LIFETIME - 1 )
            {
                float size = MAX_LIFETIME - lifetime;
                entities[ entityId ].scale = glm::vec3( size, size, size );
            }
            
            if ( lifetime > MAX_LIFETIME )
                _game->markEntityForDestruction( entityId );
        };
        _game->addComponent( bullet );
    }
    
    [GunSoundEffects[_CurrentChannel] play];
    
    _CurrentChannel ++;
    
    if(_CurrentChannel == MAX_CHANNELS)
    {
        _CurrentChannel = 0;
    }
}

- (void) spawn_bfg_projectile:( glm::vec3 )pos velocity:( glm::vec3 ) vel
{
    const EntityId bfgId( "bfg", _bfgId++ );
    {
        GraphicalComponent bfg( bfgId, GraphicalComponent::TRANSLUCENT );
        bfg.asset = _bfgProjectileSprite;
        bfg.color = glm::vec4( 0, 1, 0, 0.5 );
        
        _game->addComponent( bfg );
    }
    {
        BehavioralComponent bfg( bfgId );
        
        _game->_entities[ bfgId ].position = pos;
        
        double startTime = -1;
        bfg.functor = [self, startTime, vel](BehavioralComponent* bc, EntityCollection& entities, double time)
        mutable {
            const double MAX_LIFETIME = 4;
            if ( startTime < 0 )
                startTime = time;
            
            const double lifetime = time - startTime;
            Entity& ntt = entities[ bc->entityId ];
            
            if ( lifetime > MAX_LIFETIME - 1 )
            {
                float size = MAX_LIFETIME - lifetime;
                ntt.scale = glm::vec3( size, size, size );
            }
            
            ntt.position += vel * 0.01f;
            
            for ( auto pair : entities )
                if ( EntityId::matchesTag( "enemy", pair.first ) )
                    if ( glm::distance( ntt.position, pair.second.position ) < 2 * (ntt.scale.x) )
                        _game->markEntityForDestruction( pair.first );
            
            if ( lifetime > MAX_LIFETIME )
            {
                _game->markEntityForDestruction( bc->entityId );
            }
        };
        _game->addComponent( bfg );
    }
    
    [GunSoundEffects[_CurrentChannel] play];
    
    _CurrentChannel ++;
    
    if(_CurrentChannel == MAX_CHANNELS)
    {
        _CurrentChannel = 0;
    }
    
}


//No longer usable due to horizontalAngle and verticalAngle no longer existing in the _eyeLook variable
- (void) cameraMovement
{
    float horizontalAngle = _baseHorizontalAngle + currHorizontalAngle;
    float verticalAngle = _baseVerticalAngle + currVerticalAngle;
    
    //for animationProgress of shake
    if(GCV.animationProgress > 1) {
        GCV.animationProgress = 1;
    }
    if(GCV.animationProgress < 1) {
        GCV.animationProgress += 1.0 / 45.0;
        float shakeMag;
        if(GCV.animationProgress < 0.70) {
            shakeMag = 0.9 * 0.4;
        }
        else {
            shakeMag = (0.9 - (GCV.animationProgress - 0.7) * 0.9 / 0.3) * 0.4; //after reaching 0.7 progress (when sound starts to dwindle), linearly decrease max magnitude to 0
        }
        //modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, Float(arc4random())*shakeMag, Float(arc4random())*shakeMag, 0);
        //GLKVector3Make(position.x + Float(arc4random())*shakeMag, position.y + Float(arc4random())*shakeMag, position.z + Float(arc4random())*shakeMag);
        horizontalAngle += (arc4random() / UINT32_MAX) * shakeMag;
        verticalAngle += (arc4random() / UINT32_MAX) * shakeMag;
    }
    
    GCV.direction = {cosf(verticalAngle) * sinf(horizontalAngle),
        sinf(verticalAngle),
        cosf(verticalAngle) * cosf(horizontalAngle)};
    //_eyelook = GCV.direction;
    //GCV.horizontalMovement = GLKVector3Make(sinf(horizontalAngle - M_PI_2), 0, cosf(horizontalAngle - M_PI_2));
    //print("horizontalAngle: \(horizontalAngle); verticalAngle: \(verticalAngle)");
}

- (void) update
{
    _game->update( self.timeSinceLastUpdate );
    [self cameraMovement];
    
    //update line
    //Not yet implemented
    //UIImage *image = [UIImage imageNamed:@"RedDamageOverlay.png"];//[drawSwipeLine size:imageSize]
    //_imageView.image = image;
    
    
    if(ReLoad)
    {
        if(![ReloadSound isPlaying])
        {
            AmmoNumber = 10;
            ReLoad = false;
        }
        
    }
    /*
     if(RedImageOverlay.alpha > 0) {
     RedImageOverlay.alpha -= 0.7f / 60.0f;
     }*/
    
    if(Kills == 1 && getkill)
    {
        NSData *RlSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"First Blood" ofType:@"mp3"]];
        KillsSound = [[AVAudioPlayer alloc]initWithData:RlSoundPath error:nil];
        [KillsSound prepareToPlay];
        [KillsSound play];
        
        getkill = false;
    }
    //update overlay and position each update
    
    glm::vec3 oPos =_game->_eyepos + (_game->_eyelook - _game->_eyepos)/3.0f;
    
    //Jacob's attempt at updating the position of an entity. Can ask Andrew about this later.
    //Entity ntt = _game->_entities["overlay1"];
    //ntt.position = oPos;/*_game->_eyelook;*///_game->_eyepos + (_game->_eyelook - _game->_eyepos); //put it very, very close in front such that anything in between the overlay and the camera would really not matter anyway
    
    //Jacob's attempt at updating the position of an entity. Can ask Andrew about this later.
    //Entity *ntt2 = &(_game->_entities[_bulletId]); //bullet ID 1
    //ntt2->position = oPos;
    
    //From looking up Bullet3D for that, just trying to use that - ie. to update position - using from http://gamedev.stackexchange.com/questions/58689/how-to-set-the-objects-world-position-in-bullet
    /*
    
    //testing sprite to check if update were calling this at all; doesn't look like it works at all.
    GraphicalComponent *gc2 = _game->findGraphicalComponent(_bulletId);
    if(gc2) {
        gc2->sprite = new Sprite(ios_path("RedDamageOverlay.png"), &_game->_program);
    }
    PhysicalComponent *pc2 = _game->findPhysicalComponent(_bulletId); //bullet ID 1
    if(pc2) {
        auto motionState = new btDefaultMotionState(
                                                btTransform( btQuaternion( 0,0,0,1 ), btVector3( oPos.x, oPos.y, oPos.z ) ) );
        static btSphereShape SPHERE_SHAPE( 0.5 );
        pc2->body = new btRigidBody( 1, motionState, &SPHERE_SHAPE );
    }*/
    
    //if()
    //BehavioralComponent bc2(_bulletId);
    //pc2 = oPos;
    
    self.KillNumber.text =[[NSString alloc] initWithFormat: @"%d", Kills];
    self.Health.text =[[NSString alloc] initWithFormat: @"%d", 100];
    self.Ammo.text =[[NSString alloc] initWithFormat: @"%d", AmmoNumber];
}

- (void) glkView:(GLKView *)view
      drawInRect:(CGRect)rect
{
    _game->render();
}

- (IBAction)SoundButton:(UIButton *)sender {
    
    if (_MusicOn) {
        
        UIImage *SoundButtonImage = [UIImage imageNamed:@"SoundOff.png"];
        [self.SoundButtonEffects setImage:SoundButtonImage forState:(UIControlStateNormal)];
        _MusicOn = false;
        [themePlayer pause];
    }
    else
    {
        UIImage *SoundButtonImage = [UIImage imageNamed:@"SoundOn.png"];
        [self.SoundButtonEffects setImage:SoundButtonImage forState:(UIControlStateNormal)];
        _MusicOn = true;
        [themePlayer play];
    }
}
- (IBAction)Reload:(UIButton *)sender {
   if(AmmoNumber<10)
   {
    ReLoad = true;
    [ReloadSound play];
   }
}
@end

void Enemy_Basic::operator()(BehavioralComponent* c, EntityCollection& entities, double)
{
    if(c->timeInCycle >= c->endTimeInCycle) {
        c->timeInCycle = 0;
    }
    c->timeInCycle++; //how to get specific enemy's ...
    PhysicalComponent* pc = gameptr->findPhysicalComponent(c->entityId);
    
    
    Entity ntt = entities[ c->entityId ];
    //on the 2nd 'second' worth of update calls, shoot projectile
    if(c->timeInCycle == 60) {
        //set up projectile
        glm::vec3 vecDir = gameptr->_eyepos - ntt.position; //target player
        glm::normalize(vecDir);
        glm::vec3 projVelocity = vecDir * velocity;
        [gvc spawn_projectile:ntt.position velocity:projVelocity homeInOnPlayer:true damage:20];
    }
    //pc->body->setLinearVelocity(glm::)
    
    
    //ntt.position;
    //_game->_eyepos;
    
    //PhysicalComponent* phy = gameptr->findPhysicalComponent( c->entityId );
    //phy->body->getLinearVelocity();
}