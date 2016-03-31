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
    ~Game();

    void render() const;
    void update( double );

//private:

    void draw_scene( glm::mat4 view, glm::mat4 proj ) const;

    GLKView*                _view;
    GLfloat                 _width, _height;
    double                  _startTime, _currTime;
    
    GLProgram::ptr_t        _program;
    
    Model                   _model, _level, _enemies;
    ObjMesh                 _rail;
    std::vector< Entity >   _entities;

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
    
    GLHandle                _water_render_buffer;
    
    glm::vec3               _eyepos, _eyepos0, _eyelook, _eyelook2;
    int                     _railidx = 0;
    double                  _time = 0;

};

