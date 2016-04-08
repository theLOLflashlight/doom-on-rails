#pragma once
#include "glhelp.h"

#include "Entity.h"

#include <UIKit/UIKit.h>
#include <GLKit/GLKit.h>

#include <memory>
#include <vector>
#include <chrono>

class Game
{
public:

    Game( GLKView* view );

    void render() const;
    void update( double );
    
    glm::mat4 viewMatrix() const
    {
        return glm::lookAt( _eyepos, _eyelook, glm::vec3( 0, 1, 0 ) );
    }
    
    glm::mat4 projMatrix() const
    {
        const auto width = _width / 2;
        const auto height = _height / 2;
        const float aspectRatio = width / height;
        
        return glm::perspective< float >( glm::radians( 80.0f ), aspectRatio, 0.1, 1000 );
    }
    
    glm::vec4 viewport() const
    {
        const auto width = _width / 2;
        const auto height = _height / 2;

        return glm::vec4( 0, -height, width, height );
    }
    
    GraphicalComponent* findGraphicalComponent( EntityId _id )
    {
        for ( auto& drawable : _graphics )
            if ( drawable.entityId == _id )
                return &drawable;
        
        return nullptr;
    }
    
    const GraphicalComponent* findGraphicalComponent( EntityId _id ) const
    {
        for ( auto& drawable : _graphics )
            if ( drawable.entityId == _id )
                return &drawable;
        
        return nullptr;
    }
    
    PhysicalComponent* findPhysicalComponent( EntityId _id )
    {
        for ( auto& physible : _physics )
            if ( physible.entityId == _id )
                return &physible;
        
        return nullptr;
    }
    
    const PhysicalComponent* findPhysicalComponent( EntityId _id ) const
    {
        for ( auto& physible : _physics )
            if ( physible.entityId == _id )
                return &physible;
        
        return nullptr;
    }

//private:

    void draw_scene( glm::mat4 view, glm::mat4 proj ) const;

    GLKView*                _view;
    GLfloat                 _width, _height;
    double                  _startTime, _currTime;
    
    GLProgram::ptr_t        _program;
    
    Model                   _model, _level, _enemies;
    ObjMesh                 _rail;
    
    mutable EntityCollection            _entities;
    std::vector< GraphicalComponent >   _graphics;
    std::vector< PhysicalComponent >    _physics;

    GLHandle                _skybox_texture;
    GLProgram               _skybox_program;
    GLVertexBuffer          _skybox_buffer;

    GLTexture               _water_dudv;
    GLTexture               _water_normal;
    
    GLProgram               _water_program;
    GLVertexBuffer          _water_quad;
    
    GLHandle                _water_reflect_texture;
    GLHandle                _water_reflect_fbo;
    
    GLHandle                _water_refract_texture;
    GLHandle                _water_refract_depth_texture;
    GLHandle                _water_refract_fbo;
    
    GLHandle                _water_reflect_render_buffer;
    GLHandle                _water_refract_render_buffer;
    
    glm::vec3               _eyepos, _eyepos0, _eyelook, _eyelook2;
    int                     _railidx = 0;
    double                  _time = 0;

};

