#include "Game.h"
#include "ios_path.h"
#include <algorithm>

using namespace glm;
using std::shared_ptr;
using std::make_shared;
using std::string;
using std::vector;

#define VECTOR3( vec ) { vec[0], vec[1], vec[2] }
#define VECTOR4( vec ) { vec[0], vec[1], vec[2], vec[3] }

btVector3 btVector( glm::vec3 vec )
{
    return VECTOR3( vec );
}

btVector4 btVector( glm::vec4 vec )
{
    return VECTOR4( vec );
}

namespace glm
{
    glm::vec3 vec( btVector3 vec )
    {
        return VECTOR3( vec );
    }
    
    glm::vec4 vec( btVector4 vec )
    {
        return VECTOR4( vec );
    }
}

Game::Game( GLKView* view, std::string levelName, std::string redEnemies, std::string greenEnemies, std::string railName )
    // we need to bind the view drawable before our shaders load
    : _view( ([view bindDrawable], view) )
    , _world( [[BulletPhysics alloc] init] )

    // why does this need to be doubled?
    , _width( _view.bounds.size.width * 2 )
    // why does this need to be doubled?
    , _height( _view.bounds.size.height * 2 )

    , _startTime( 0 )
    , _currTime( _startTime )

    , _program( ios_path( "ModelShader.vs" ), ios_path( "ModelShader.fs" ), "aPosition", "aNormal", "aTexCoord" )
    , _spriteProgram( ios_path( "SpriteShader.vs" ), ios_path( "SpriteShader.fs" ), "aPosition", "aTexCoord" )
    , _fireProgram( ios_path( "SpriteShader.vs" ), ios_path( "FireShader.fs" ), "aPosition", "aTexCoord" )

    , _level( ObjMesh( ios_path( levelName ) ), &_program )
    //, _enemies( ObjMesh( ios_path( "Level0EnemyPos.obj" ) ), &_program )

    , _rail( ObjMesh( ios_path( railName ) ).rail )
    , _raillook( _rail.data, 1 )

    //, _skybox( "goldrush", vec3( 0.342, 0.866, -0.940 ), vec4( 1, 1, 0.8, 0.5 ) )
    , _skybox( "mar", vec3( 0.766, 0.259, 0.643 ), vec4( 1, 1, 0, 0.5 ) )
    //, _skybox( "cp", vec3( 0.342, 0.866, -0.940 ), vec4( 0, 0.5, 1, 0.5 ) )
    //, _skybox( "mercury", vec3( 0, 1, 0 ), vec4( 1, 0.2, 0, 0.5 ) )

    , _water( vec4( 0, 0.3, 0.5, 1 ), _width, _height )
{
    _water.setSun( _skybox.sunPosition, _skybox.sunColor );
    
    // Set up view
    [_view bindDrawable];
    glClearColor( 0, 0, 0, 1 );
    glViewport( 0, 0, _width, _height );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    
    // Set up main shader
    {
        vec4    ambientComponent( 0.5, 0.5, 0.5, 1.0 );
        float   shininess = 10.0;
        
        _program.bind();
        glUniform3fv( _program.find_uniform( "uSunPosition" ), 1, &_skybox.sunPosition[0] );
        glUniform4fv( _program.find_uniform( "uAmbientColor" ), 1, &ambientComponent[0] );
        glUniform4fv( _program.find_uniform( "uDiffuseColor" ), 1, &_skybox.sunColor[0] );
        glUniform4fv( _program.find_uniform( "uSpecularColor" ), 1, &_skybox.sunColor[0] );
        glUniform1f( _program.find_uniform( "uShininess" ), shininess );
        glUseProgram( 0 );
    }
    
    // Set up sprite shaders
    {
        vec4    ambientComponent( 0.5, 0.5, 0.5, 1.0 );
        
        _spriteProgram.bind();
        glUniform4fv( _spriteProgram.find_uniform( "uAmbientColor" ), 1, &ambientComponent[0] );
        glUniform4fv( _spriteProgram.find_uniform( "uDiffuseColor" ), 1, &_skybox.sunColor[0] );
        
        _fireProgram.bind();
        glUniform1i( _fireProgram.find_uniform( "uMapDuDv" ), 3 ); // same as water DuDv
        glUseProgram( 0 );
    }

    
    // Set up level
    {
        GraphicalComponent level( "level" );
        level.model = &_level;
        level.program = &_program;
        
        _graphics.push_back( level );
        _entities[ "level" ].position = vec3( 0, -0.1, 0 );
    }
    {
        //PhysicalComponent level( "level" );
        //_physics.push_back( level );
        
        btTriangleMesh* tMesh = new btTriangleMesh();
        
        for ( int i = 0; i < _level._mesh.size(); i += 3 )
        {
            vec3 v0 = _level._mesh[ i + 0 ].aPosition;
            vec3 v1 = _level._mesh[ i + 1 ].aPosition;
            vec3 v2 = _level._mesh[ i + 2 ].aPosition;
            
            tMesh->addTriangle( btVector( v0 ), btVector( v1 ), btVector( v2 ) );
        }
        
        btBvhTriangleMeshShape* levelShape = new btBvhTriangleMeshShape( tMesh, true );
        
        auto levelObj = new btCollisionObject();
        levelObj->setCollisionShape( levelShape );
        levelObj->setWorldTransform( btTransform( btQuaternion( 0,0,0,1 ), btVector3( 0, -0.1, 0 ) ) );
        
        [_world addCollisionObject: levelObj];
    }

    {
        auto enemiesRail = ObjMesh( ios_path( redEnemies ) ).rail;
        
        Sprite* redSprite = new Sprite( ios_path( "Level0All/enemy2.png" ), &_spriteProgram );
        redSprite->height = 2;
        redSprite->width = 2;
        redSprite->spriteAxis = vec3( 0, 1, 0 );
        
        for ( int i = 0; i < enemiesRail.size(); i += 2 )
        {
            const EntityId enemyId( "redemy", i );
            
            GraphicalComponent enemyG( enemyId, GraphicalComponent::TRANSLUCENT );
            enemyG.sprite = redSprite;
            enemyG.program = &_spriteProgram;
            
            addComponent( enemyG );
            
            PhysicalComponent enemyP( enemyId );
            
            vec3 pos = enemiesRail[ i ];
            
            auto motionState = new btDefaultMotionState(
                btTransform( btQuaternion( 0,0,0,1 ), btVector3( pos.x, pos.y + 1, pos.z ) ) );
            
            static btSphereShape SPHERE_SHAPE( 1 );
            enemyP.body = new btRigidBody( 1, motionState, &SPHERE_SHAPE );
            enemyP.body->setUserPointer( (void*) enemyId.bitPattern );
            
            addComponent( enemyP );
        }

    }
    
    {
        auto enemiesRail = ObjMesh( ios_path( greenEnemies ) ).rail;
        
        Sprite* greenSprite = new Sprite( ios_path( "Level0All/enemy0.png" ), &_spriteProgram );
        greenSprite->height = 2;
        greenSprite->width = 1.25;
        greenSprite->spriteAxis = vec3( 0, 1, 0 );
        
        for ( int i = 0; i < enemiesRail.size(); i += 2 )
        {
            const EntityId enemyId( "grnemy", i );
            
            GraphicalComponent enemyG( enemyId, GraphicalComponent::TRANSLUCENT );
            enemyG.sprite = greenSprite;
            enemyG.program = &_spriteProgram;
            
            addComponent( enemyG );
            
            PhysicalComponent enemyP( enemyId );
            
            vec3 pos = enemiesRail[ i ];
            
            auto motionState = new btDefaultMotionState(
                btTransform( btQuaternion( 0,0,0,1 ), btVector3( pos.x, pos.y + 1, pos.z ) ) );
            
            static btCylinderShape CYLINDER_SHAPE( { 0.5, 1, 0.5 } );
            enemyP.body = new btRigidBody( 1, motionState, &CYLINDER_SHAPE );
            
            enemyP.body->setUserPointer( (void*) enemyId.bitPattern );
            
            addComponent( enemyP );
        }

    }
}


void Game::offsetEyelook() {
    using namespace glm;
    /*
    //for animationProgress of shake
    if(_animationProgress > 1) {
        _animationProgress = 1;
    }
    if(_animationProgress < 1) {
        _animationProgress += 1.0 / 45.0;
        float shakeMag;
        if(_animationProgress < 0.70) {
            shakeMag = 0.9 * 0.4;
        }
        else {
            shakeMag = (0.9 - (_animationProgress - 0.7) * 0.9 / 0.3) * 0.4; //after reaching 0.7 progress (when sound starts to dwindle), linearly decrease max magnitude to 0
        }
        //modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, Float(arc4random())*shakeMag, Float(arc4random())*shakeMag, 0);
        //GLKVector3Make(position.x + Float(arc4random())*shakeMag, position.y + Float(arc4random())*shakeMag, position.z + Float(arc4random())*shakeMag);
        //horizontalAngle += (arc4random() / UINT32_MAX) * shakeMag;
        //verticalAngle += (arc4random() / UINT32_MAX) * shakeMag;
        
        mat4 rotMatrix;
        
        rotMatrix = rotate( rotMatrix, arc4random() * shakeMag, vec3 {0, 1, 0} );
        
        //auto v =
    }
     */
    if(_animationProgress > 1) {
        _animationProgress = 1;
    }
    if(_animationProgress < 1) {
        _animationProgress += 1.0 / 45.0;
        //if(_animationProgress <= )
    }
    //ambientComponent =
}


void Game::update( double step )
{
    _currTime += step;
    const double time = _currTime - _startTime;
    
    [_world update: step];
    
    if(!(_rail.isAtEnd()))
        _eyepos = _rail[ time ];
    
    if(!(_raillook.isAtEnd()))
        _eyelook = _raillook[ time ];
    
    _water.update( time / 10, _eyepos );
    
    _fireProgram.bind();
    glUniform1f( _fireProgram.find_uniform( "uDuDvFactor" ), time );
    glUseProgram( 0 );
    
    
    for ( auto& behavior : _behaviors )
        behavior.update( _entities, time );
    
    for ( auto& physable : _physics )
        physable.update( _entities );
    
    for ( auto pair : _entities )
        if ( pair.second.position.y < -5 )
            markEntityForDestruction( pair.first );
    
    for ( auto _id : _badIds )
        destroyEntity( _id );
    
    _badIds.clear();
    
    // Sort our translucent sprites based on distance from camera.
    std::sort( _graphics.begin(), _graphics.end(),
    [this](const GraphicalComponent& lhs, const GraphicalComponent& rhs)
    {
        if ( lhs.visibility == GraphicalComponent::TRANSLUCENT
             && rhs.visibility == GraphicalComponent::TRANSLUCENT )
        {
            vec3 pos1 = _entities[ lhs.entityId ].position;
            vec3 pos2 = _entities[ rhs.entityId ].position;
            
            return glm::distance( pos1, _eyepos ) > glm::distance( pos2, _eyepos );
        }

        return rhs.visibility == GraphicalComponent::TRANSLUCENT;
    } );
}


void Game::render() const
{
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    glEnable( GL_DEPTH_TEST );
    glEnable( GL_CULL_FACE );

    glCullFace( GL_BACK );

    vec3 eyepos = _eyepos;
    vec3 eyelook = _eyelook;
    
    const mat4 view = viewMatrix();
    const mat4 proj = projMatrix();
    
    // Draw to water buffers.
    {
        glEnable( GL_CLIP_DISTANCE(0) );
        
        // Render refLEction.
        eyepos.y = -eyepos.y;
        eyelook.y = -eyelook.y;
        
        _water.bindReflection(_width, _height );
        
        _program.bind();
        glUniform4f( _program.find_uniform( "uWaterPlane" ), 0, 1, 0, 0 );
        _spriteProgram.bind();
        glUniform4f( _spriteProgram.find_uniform( "uWaterPlane" ), 0, 1, 0, 0 );
        _fireProgram.bind();
        glUniform4f( _fireProgram.find_uniform( "uWaterPlane" ), 0, 1, 0, 0 );
        glUseProgram( 0 );

        draw_scene( lookAt( eyepos, eyelook, vec3( 0, 1, 0 ) ), proj );
        
        // Render refRAction
        _water.bindRefraction( _width, _height );
        _program.bind();
        glUniform4f( _program.find_uniform( "uWaterPlane" ), 0, -1, 0, 0 );
        _spriteProgram.bind();
        glUniform4f( _spriteProgram.find_uniform( "uWaterPlane" ), 0, -1, 0, 0 );
        _fireProgram.bind();
        glUniform4f( _fireProgram.find_uniform( "uWaterPlane" ), 0, -1, 0, 0 );

        glUseProgram( 0 );
        
        draw_scene( view, proj );
        
        glDisable( GL_CLIP_DISTANCE(0) );
    }

    // Draw our scene.
    [_view bindDrawable];
    draw_scene( view, proj, true );
}


void Game::draw_scene( glm::mat4 view, glm::mat4 proj, bool drawWater ) const
{
    _skybox.render( view, proj );
    
    if ( drawWater )
        _water.render( view, proj );
    
    _program.bind();
    glUniformMatrix4fv( _program.find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program.find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    _spriteProgram.bind();
    glUniformMatrix4fv( _spriteProgram.find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _spriteProgram.find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    _fireProgram.bind();
    glUniformMatrix4fv( _fireProgram.find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _fireProgram.find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    
    for ( auto drawable : _graphics )
        drawable.update( _entities, view, proj );
}


glm::mat4 Game::viewMatrix() const
{
    return glm::lookAt( _eyepos, _eyelook, glm::vec3( 0, 1, 0 ) );
}

glm::mat4 Game::projMatrix() const
{
    const auto width = _width / 2;
    const auto height = _height / 2;
    const float aspectRatio = width / height;
    
    return glm::perspective< float >( glm::radians( 80.0f ), aspectRatio, 0.1, 1000 );
}

glm::vec4 Game::viewport() const
{
    const auto width = _width / 2;
    const auto height = _height / 2;
    
    return glm::vec4( 0, -height, width, height );
}

GraphicalComponent* Game::findGraphicalComponent( EntityId _id )
{
    for ( auto& drawable : _graphics )
        if ( drawable.entityId == _id )
            return &drawable;
    
    return nullptr;
}

const GraphicalComponent* Game::findGraphicalComponent( EntityId _id ) const
{
    for ( auto& drawable : _graphics )
        if ( drawable.entityId == _id )
            return &drawable;
    
    return nullptr;
}

PhysicalComponent* Game::findPhysicalComponent( EntityId _id )
{
    for ( auto& physible : _physics )
        if ( physible.entityId == _id )
            return &physible;
    
    return nullptr;
}

const PhysicalComponent* Game::findPhysicalComponent( EntityId _id ) const
{
    for ( auto& physible : _physics )
        if ( physible.entityId == _id )
            return &physible;
    
    return nullptr;
}

BehavioralComponent* Game::findBehavioralComponent( EntityId _id )
{
    for ( auto& behavior : _behaviors )
        if ( behavior.entityId == _id )
            return &behavior;
    
    return nullptr;
}

const BehavioralComponent* Game::findBehavioralComponent( EntityId _id ) const
{
    for ( auto& behavior : _behaviors )
        if ( behavior.entityId == _id )
            return &behavior;
    
    return nullptr;
}


void Game::addComponent( GraphicalComponent component )
{
    _graphics.push_back( component );
}

void Game::addComponent( PhysicalComponent component )
{
    _physics.push_back( component );
    [_world addRigidBody: component.body];
}

void Game::addComponent( BehavioralComponent component )
{
    _behaviors.push_back( component );
}

void Game::markEntityForDestruction( EntityId _id )
{
    _badIds.insert( _id );
}

void Game::destroyEntity( EntityId _id )
{
    if ( EntityId::matchesTag( "redemy", _id ) || EntityId::matchesTag( "grnemy", _id ) )
        ++*killCountPtr;
    
    for ( int i = 0; i < _graphics.size(); i++ )
        if ( _graphics[ i ].entityId == _id )
            _graphics.erase( _graphics.begin() + i-- );
    
    for ( int i = 0; i < _physics.size(); i++ )
        if ( _physics[ i ].entityId == _id )
            _physics.erase( _physics.begin() + i-- );
    
    for ( int i = 0; i < _behaviors.size(); i++ )
        if ( _behaviors[ i ].entityId == _id )
            _behaviors.erase( _behaviors.begin() + i-- );

    _entities.erase( _id );
}


/*size_t railsize = _rail.rail.size();
 
 _eyelook = _rail.rail[ (_railidx + 1) % railsize ];
 _eyelook2 = _rail.rail[ (_railidx + 3) % railsize ];
 
 vec3 eyepos = _rail.rail[ _railidx ];
 if ( eyepos.x != _eyepos0.x || eyepos.y != _eyepos0.y || eyepos.z != _eyepos0.z )
 {
 _eyepos0 = eyepos;
 _time = time;
 }
 
 float a = (time - _time) / length( _eyelook - _eyelook2 ) * 6;
 vec3 eyelook = glm::mix( _eyelook, _eyelook2, a );
 
 a = (time - _time) / length( _eyepos0 - _eyelook ) * 6;
 
 eyepos = glm::mix( _eyepos0, _eyelook, a );
 if ( a > 1 ) {
 _railidx += 2;
 _railidx %= railsize;
 }
 
 eyepos.y -= 0.5;
 eyelook.y -= 0.5;*/
