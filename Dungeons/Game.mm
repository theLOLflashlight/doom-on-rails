#include "Game.h"
#include "ios_path.h"

using namespace glm;
using std::shared_ptr;
using std::make_shared;
using std::string;
using std::vector;

Game::Game( GLKView* view )
    // we need to bind the view drawable before our shaders load
    : _view( ([view bindDrawable], view) )

    // why do these need to be doubled??
    , _width( _view.bounds.size.width * 2 )
    , _height( _view.bounds.size.height * 2 )

    , _startTime( 0 )
    , _currTime( _startTime )

    , _program( new GLProgram( ios_path( "MyShader.vs" ), ios_path( "MyShader.fs" ), "aPosition", "aNormal", "aTexCoord" ) )

    , _level( ObjMesh( ios_path( "Level0Layout.obj" ) ), _program )
    , _enemies( ObjMesh( ios_path( "Level0EnemyPos.obj" ) ), _program )

    , _rail( ObjMesh( ios_path( "DemoRail.obj" ) ).rail )
    , _raillook( _rail.data, 1 )

    //, _skybox( "mar", vec3( 0.766, 0.259, 0.643 ), vec4( 1, 1, 0, 0.5 ) )
    , _skybox( "goldrush", vec3( 0.342, 0.866, -0.940 ), vec4( 1, 1, 0.8, 0.5 ) )
    , _water( vec4( 0, 0.3, 0.5, 1 ), _width, _height )
{
    _water.setSun( _skybox.sunPosition, _skybox.sunColor );
    
    // Setup view
    [_view bindDrawable];
    glClearColor( 0, 0, 0, 1 );
    glViewport( 0, 0, _width, _height );
    glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
    
    // Setup main shader
    {
        vec4    ambientComponent( 0.5, 0.5, 0.5, 1.0 );
        vec4    diffuseComponent( 1, 1, 0.1, 0.1 );
        vec4    specularComponent( 1, 1, 0, 0.1 );
        float   shininess = 10.0;
        
        _program->bind();
        glUniform3fv( _program->find_uniform( "uSunPosition" ), 1, &_skybox.sunPosition[0] );
        glUniform4fv( _program->find_uniform( "uAmbientColor" ), 1, &ambientComponent[0] );
        glUniform4fv( _program->find_uniform( "uDiffuseColor" ), 1, &_skybox.sunColor[0] );
        glUniform4fv( _program->find_uniform( "uSpecularColor" ), 1, &specularComponent[0] );
        glUniform1f( _program->find_uniform( "uShininess" ), shininess );
        glUseProgram( 0 );
    }
    
    // Setup level
    {
        GraphicalComponent level( "level", GraphicalComponent::TRANSLUCENT );
        level.model = &_level;
        level.program = _program.get();
        
        _graphics.push_back( level );
    }
    {
        PhysicalComponent level( "level", false );
        _physics.push_back( level );
        
        _entities[ "level" ].position = vec3( 0, -0.1, 0 );
    }

    // Setup enemies
    {
        GraphicalComponent enemies( "enemies", GraphicalComponent::TRANSLUCENT );
        enemies.model = &_enemies;
        enemies.program = _program.get();
        
        /*enemies.delegate = [](GraphicalComponent* gfx, EntityCollection& entities, glm::mat4 view, glm::mat4 proj)
        {
            glUniform4fv( gfx->program->find_uniform( "uColor" ), 1, &gfx->color[ 0 ] );
            
            glEnable( GL_BLEND );
            gfx->model->render( entities[ gfx->entityId ].transform_matrix(), view, proj );
            glDisable( GL_BLEND );
        };*/
        
        _graphics.push_back( enemies );
    }
    {
        PhysicalComponent enemies( "enemies", false );
        _physics.push_back( enemies );
        
        _entities[ "enemies" ].position = vec3( 0, -0.1, 0 );
    }
}


void Game::update( double step )
{
    _currTime += step;
    const double time = _currTime - _startTime;
    
    _eyepos = _rail[ time ];// - vec3( 0, 0.5, 0 );
    _eyelook = _raillook[ time ];// - vec3( 0, 0.5, 0 );
    
    
    //_eyepos += vec3( 1, 1, 1 );
    //_eyelook += vec3( 1, 1, 1 );
    
    
    _water.update( time / 10, _eyepos );
    
    for ( auto& physable : _physics )
        physable.update( _entities );
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
        
        _water.bindReflection( _program.get(), _width, _height );
        draw_scene( lookAt( eyepos, eyelook, vec3( 0, 1, 0 ) ), proj );
        
        // Render refRAction
        _water.bindRefraction( _program.get(), _width, _height );
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
    
    _program->bind();
    glUniformMatrix4fv( _program->find_uniform( "uViewMatrix" ), 1, GL_FALSE, &view[ 0 ][ 0 ] );
    glUniformMatrix4fv( _program->find_uniform( "uProjMatrix" ), 1, GL_FALSE, &proj[ 0 ][ 0 ] );
    glUniform4f( _program->find_uniform( "uColor" ), 1, 1, 1, 0 );

    if ( drawWater )
        _water.render( view, proj );
    
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
}

void Game::addComponent( BehavioralComponent component )
{
    _behaviors.push_back( component );
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
