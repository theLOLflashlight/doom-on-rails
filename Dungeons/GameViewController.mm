//
//  GameViewController.m
//  Dungeons
//
//  Created by Andrew Meckling on 2016-03-22.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES3/glext.h>
#import <AVFoundation/AVFoundation.h>
#import "Game.h"
#import "BulletPhysics.h"
#import "GameCppVariables.hpp"
#include "ios_path.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define SFXINSTANCES 5
#define NSPoint CGPoint
#define NSUInteger UInt
#define MAX_CHANNELS 30

#define BULLET_MIN 1000
#define BULLET_MAX 4000

@interface GameViewController ()
{
    bool SoundSwitch;
    
    bool ReLoad;
    int AmmoNumber;
    AVAudioPlayer *ReloadSound;
    
    Game*       _game;
    int         _bulletId;
    Sprite*     _projectileSprite;
    
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
}

@property (strong, nonatomic) EAGLContext* context;
@property (strong, nonatomic) BulletPhysics* physics;

@end

@implementation GameViewController

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
            [self spawn_projectile: touchPos0 velocity: normalize( touchPos1 - touchPos0 ) * 50.0f];
            
            AmmoNumber --;
        }
        
        //[self explosionAt: _game->_eyepos];
      
        if(AmmoNumber == 0)
        {
            ReLoad = true;
            
            [ReloadSound setVolume:10];
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
    
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES3];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    _physics = [[BulletPhysics alloc] init];
    
    
    auto groundShape = new btStaticPlaneShape( btVector3( 0, 1, 0 ), 0 );
    
    
    auto groundMotionState = new btDefaultMotionState();
    
    btRigidBody::btRigidBodyConstructionInfo groundRigidBodyCI( 0, groundMotionState, groundShape, btVector3(0,0,0) );
    
    auto groundRigidBody = new btRigidBody(groundRigidBodyCI);
    [_physics addRigidBody: groundRigidBody];
    
    
    //Q2 - double tap
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    //Handle pan: Swipe
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [panGesture setMinimumNumberOfTouches:1];
    [panGesture setMaximumNumberOfTouches:1];
    [self.view addGestureRecognizer:panGesture];
    
    //play looping sound
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];
    
    _game = new Game( (GLKView*) self.view, _physics, "Level0Layout.obj", "Level0EnemyPosRail.obj", "Level0EnemyPosRail.obj", "DemoRail.obj" );
    
    _projectileSprite = new Sprite( ios_path( "fireball/fireball.png" ), &_game->_spriteProgram );
    
    
    _bulletId = BULLET_MIN;
    
    _CurrentChannel = 0;
    
    NSData *GBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"GunSoundEffect_1" ofType:@"wav"]];
    
    for(int i = 0; i < MAX_CHANNELS; i++) {
        
    GunSoundEffects[i] = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
        
    [GunSoundEffects[i] prepareToPlay];
       
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

    }
    
    //Initialization of variables
    screenSize = [[UIScreen mainScreen] bounds];// : CGRect = UIScreen.mainScreen().bounds;
    imageSize = CGSizeMake(200, 200);// = CGSize(width: 200, height: 200); //arbitrary initialization
    _myBezier = [[UIBezierPath alloc] init];// = UIBezierPath();
    bezierDuration = 1;// = Float(1); //duration of bezier on screen (in seconds)
    //to track swipe running or not
    _currBezierDuration= -0.00001;// = -0.00001; //hard-coded time below 0
    _currSwipeDrawn = false;// = false;
    BehavioralComponent enemy("enemy");
    
    
    self.KillNumber.text =[[NSString alloc] initWithFormat: @"%d", 0];
    self.Health.text =[[NSString alloc] initWithFormat: @"%d", 100];
    self.Ammo.text =[[NSString alloc] initWithFormat: @"%d", AmmoNumber];
    
    NSData *RlSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"reload" ofType:@"mp3"]];
    ReloadSound = [[AVAudioPlayer alloc]initWithData:RlSoundPath error:nil];
    
    [ReloadSound prepareToPlay];
    
    
    
    //[NSDate?](count: 64, repeatedValue: nil)
}

//Starts upon appear
- (void)viewDidAppear:(BOOL)animated
{
    //play looping sound
    if(_MusicOn) {
        [self ThemeSound];
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
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        _noSwipe = false;
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
        }
    }
    
    
    if(radLength > _maxRadius) {
        _maxRadius = radLength;
    }
    
    //cancel gesture if moving backwards from the furthest radius from the origin (as opposed to total translation) by 6px.
    //So yes, you can zigzag a lot if you wanted to.
    if(radLength < _maxRadius - 6) {
        //_noSwipe = true;
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

-(void) ThemeSound {
    if(NSString *path = [[NSBundle mainBundle] pathForResource:@"DOOM" ofType: @"mp3"]) { //J: Not sure about this conversion from swift
        NSURL *soundURL = [NSURL fileURLWithPath:path]; //Can check this code later ...
        
        NSError *error;
        try { //J: Not sure about this conversion from Swift
            themePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)soundURL error:nil];
            [themePlayer prepareToPlay];
            [themePlayer play];
        }
        catch(NSException *exception) {
        }
    }
}


//Jacob: Shake input handler
-(void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) { //just having earthquake for now
        //shake method here
        //Cast spell
        
        GCV.animationProgress = 0; //begins the animation of earthquake
        
        
        if(NSString *path = [[NSBundle mainBundle] pathForResource:@"magic-quake2" ofType: @"mp3"]) { //J: Not sure about this conversion from swift
            NSURL *soundURL = [NSURL fileURLWithPath:path]; //Can check this code later ...
            
            NSError *error;
            try { //J: Not sure about this conversion from Swift
                soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)soundURL error:nil];
                [soundPlayer prepareToPlay];
                [soundPlayer play];
            }
            catch(NSException *exception) {
            }
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

-(void) explosionAt:(glm::vec3) pos
             radius:(float)     radius
{
    for ( auto& ntt : _game->_entities )
    {
        if ( glm::distance( ntt.second.position, pos ) < radius )
        {
            GraphicalComponent* gfx = _game->findGraphicalComponent( ntt.first );
            if ( gfx )
                gfx->color = glm::vec4( 1, 0, 0, 1 );
        }
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void) spawn_projectile:( glm::vec3 )pos velocity:( glm::vec3 ) vel
{
    const EntityId bulletId = _bulletId++;
    {
        GraphicalComponent bullet( bulletId, GraphicalComponent::TRANSLUCENT );
        bullet.program = &_game->_spriteProgram;
        bullet.sprite = _projectileSprite;
        //bullet.spriteAxis = glm::vec3( 0, 1, 0 );
        
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
    [_physics update: self.timeSinceLastUpdate];
    _game->update( self.timeSinceLastUpdate );
    [self cameraMovement];
    
    //update line
    /* //Not yet implemented
    UIImage image = [drawSwipeLine size:imageSize]
    _imageView.image = image
     */
    
    if(ReLoad)
    {
        if(![ReloadSound isPlaying])
        {
            AmmoNumber = 10;
             ReLoad = false;
        }
        
    }
    
    self.KillNumber.text =[[NSString alloc] initWithFormat: @"%d", 0];
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
@end
