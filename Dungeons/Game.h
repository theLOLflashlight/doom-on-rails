#pragma once
#include "glhelp.h"

#include "Entity.h"
#include "Skybox.hpp"
#include "Water.hpp"
#include "BulletPhysics.h"

#include <UIKit/UIKit.h>
#include <GLKit/GLKit.h>

#include <memory>
#include <vector>
#include <chrono>
#include <set>

#define VECTOR3( vec ) { vec[0], vec[1], vec[2] }
#define VECTOR4( vec ) { vec[0], vec[1], vec[2], vec[3] }

inline btVector3 btVector( glm::vec3 vec )
{
    return VECTOR3( vec );
}

inline btVector4 btVector( glm::vec4 vec )
{
    return VECTOR4( vec );
}

namespace glm
{
    inline glm::vec3 vec( btVector3 vec )
    {
        return VECTOR3( vec );
    }
    
    inline glm::vec4 vec( btVector4 vec )
    {
        return VECTOR4( vec );
    }
}

struct Rail
{
    std::vector< glm::vec3 > data;
    float       speed;
    
    double      _time;
    size_t      _idx;
    size_t      _offset;
    glm::vec3   _pos0, _pos1;
    
    Rail() : data()
    {
    }
    
    explicit Rail( std::vector<glm::vec3> _data, size_t offset = 0 )
        : data( std::move( _data ) )
        , speed( 6 )
        , _time( 0 )
        , _idx( offset )
        , _offset( offset )
        , _pos0( data[ _idx ] )
        , _pos1( data[ _idx + 1 ] )
    {
    }
    
    glm::vec3 operator []( const double time )
    {
        using namespace glm;
        
        const size_t railsize = data.size();
        
        _pos1 = data[ (_idx + 1 + _offset) % railsize ];
        
        vec3 pos = data[ _idx + _offset ];
        
        if ( pos.x != _pos0.x || pos.y != _pos0.y || pos.z != _pos0.z )
        {
            _pos0 = pos;
            _time = time;
        }
        
        float a = (time - _time) / length( _pos0 - _pos1 ) * speed;
        
        pos = glm::mix( _pos0, _pos1, a );
        
        if ( a > 1 ) {
            _idx += 2;
            _idx %= railsize;
        }
        
        return pos;
    }
    
    bool isAtEnd()
    {
        return !(_idx < (data.size() - 1));
    }
    
};



class Game
{
public:

    Game( GLKView* view, std::string levelName, std::string redEnemies, std::string railName, std::string name, glm::vec3 sunPosition, glm::vec4 sunColor, int enemyTypes );

    int* killCountPtr;
    
    void render() const;
    void offsetEyelook ();
    void update( double );
    
    glm::mat4 viewMatrix() const;
    glm::mat4 projMatrix() const;
    glm::vec4 viewport() const;
    
    GraphicalComponent*         findGraphicalComponent( EntityId _id );
    const GraphicalComponent*   findGraphicalComponent( EntityId _id ) const;
    
    PhysicalComponent*          findPhysicalComponent( EntityId _id );
    const PhysicalComponent*    findPhysicalComponent( EntityId _id ) const;
    
    BehavioralComponent*        findBehavioralComponent( EntityId _id );
    const BehavioralComponent*  findBehavioralComponent( EntityId _id ) const;

    void addComponent( GraphicalComponent component );
    void addComponent( PhysicalComponent component );
    void addComponent( BehavioralComponent component );
    
    void destroyEntity( EntityId _id );
    
    void draw_scene( glm::mat4 view, glm::mat4 proj, bool drawWater = false ) const;

    
    GLKView*                _view;
    BulletPhysics*          _world;
    GLfloat                 _width, _height;
    double                  _startTime, _currTime;
    
    mutable GLProgram       _program, _spriteProgram, _fireProgram;
    
    Model                   _level;
    Rail                    _rail, _raillook;
    
    template< typename Component >
    using ComponentCollection = std::vector< Component >;
    
    mutable EntityCollection            _entities;
    
    ComponentCollection< GraphicalComponent >   _graphics;
    ComponentCollection< PhysicalComponent >    _physics;
    ComponentCollection< BehavioralComponent >  _behaviors;
    
    std::set< EntityId >    _badIds;
    
    void markEntityForDestruction( EntityId _id );

    Skybox                  _skybox;
    Water                   _water;
    
    glm::vec3               _eyepos, _eyelook;
    double                  _animationProgress;
    
    bool                    _endOfLevel;
};

