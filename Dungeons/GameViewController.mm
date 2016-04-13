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
    AVAudioPlayer *BGunSoundEffects[MAX_CHANNELS];
    int _CurrentChannel;
    int _BCurrentChannel;
    
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
    
    
    NSDate *_lastDate[64];
    GameCppVariables GCV;
    
    UIImage *_image;
    UIImage *_anImage;
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
            [self spawn_projectile: touchPos0 velocity: normalize( touchPos1 - touchPos0 ) * 50.0f];
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

- (void) handleTap2Gesture:(UITapGestureRecognizer *)sender
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
            [self spawn_bfg_projectile: touchPos0 velocity: normalize( touchPos1 - touchPos0 ) * 50.0f];
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
    
    //tap
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer *tap2Gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap2Gesture:)];
    tap2Gesture.numberOfTapsRequired = 1;
    tap2Gesture.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:tap2Gesture];
    
    //play looping sound
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];
    
    double expireTime = 0;
    
    switch ( _LevelIndex )
    {
        case 0:
            _game = new Game( (GLKView*) self.view, "Level0Layout.obj", "Level0EnemyPos.obj", "Level0Rail.obj", "mar", glm::vec3( 0.766, 0.259, 0.643 ), glm::vec4( 1, 1, 0, 0.5 ), 2 );
            expireTime = 65;
            break;
        case 1:
            _game = new Game( (GLKView*) self.view, "Level1Layout.obj", "Level1EnemyPos.obj", "Level1Rail.obj", "cp", glm::vec3( 0.342, 0.866, -0.940 ), glm::vec4( 0, 0.5, 1, 0.5 ), 3 );
            expireTime = 64;
            break;
            
        case 2:
            _game = new Game( (GLKView*) self.view, "Level2Layout.obj", "Level2EnemyPos.obj", "Level2Rail.obj", "mercury", glm::vec3( 0, 1, 0 ), glm::vec4( 1, 0.2, 0, 0.5 ), 4 );
            expireTime = 64;
            break;
        case 3:
            //game over
            break;
    }
    
    BehavioralComponent endGame( "endGame" );
    endGame.functor = [self, expireTime](BehavioralComponent*, EntityCollection&, double time)
    {
        if ( time > expireTime )
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
    
     NSData *BGBSoundPath = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"BigGun" ofType:@"mp3"]];
    
    for(int i = 0; i < MAX_CHANNELS; i++) {
        
        GunSoundEffects[i] = [[AVAudioPlayer alloc]initWithData:GBSoundPath error:nil];
        
        [GunSoundEffects[i] prepareToPlay];
        
        BGunSoundEffects[i] = [[AVAudioPlayer alloc]initWithData:BGBSoundPath error:nil];
        
        [BGunSoundEffects[i] prepareToPlay];
        
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


- (void) spawn_projectile:( glm::vec3 )pos velocity:( glm::vec3 ) vel
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
        
        _game->addComponent( bullet );
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
    
    [BGunSoundEffects[_BCurrentChannel] play];
    
    _BCurrentChannel ++;
    
    if(_BCurrentChannel == MAX_CHANNELS)
    {
        _BCurrentChannel = 0;
    }
    
}

- (void) update
{
    _game->update( self.timeSinceLastUpdate );
    
    if(ReLoad)
    {
        if(![ReloadSound isPlaying])
        {
            AmmoNumber = 10;
            ReLoad = false;
        }
        
    }
    
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
        //[gvc spawn_projectile:ntt.position velocity:projVelocity homeInOnPlayer:true damage:20];
    }
    //pc->body->setLinearVelocity(glm::)
    
    
    //ntt.position;
    //_game->_eyepos;
    
    //PhysicalComponent* phy = gameptr->findPhysicalComponent( c->entityId );
    //phy->body->getLinearVelocity();
}