#pragma once
#include "glhelp.h"

#include "Entity.h"
#include "Skybox.hpp"
#include "Water.hpp"

#include <UIKit/UIKit.h>
#include <GLKit/GLKit.h>

#include <memory>
#include <vector>
#include <chrono>

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
};



class Game
{
public:

    Game( GLKView* view );

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

    void draw_scene( glm::mat4 view, glm::mat4 proj, bool drawWater = false ) const;

    
    GLKView*                _view;
    GLfloat                 _width, _height;
    double                  _startTime, _currTime;
    
    GLProgram::ptr_t        _program;
    
    Model                   _level, _enemies;
    Rail                    _rail, _raillook;
    
    mutable EntityCollection            _entities;
    std::vector< GraphicalComponent >   _graphics;
    std::vector< PhysicalComponent >    _physics;

    Skybox                  _skybox;
    Water                   _water;
    
    glm::vec3               _eyepos, _eyelook;
    double                  _animationProgress;
};

