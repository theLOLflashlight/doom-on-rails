#pragma once

#include "glhelp.h"
#include "ObjMesh.h"

#include <vector>
#include <memory>
#include <string>


struct Renderable
{
    GLProgram* _program;
    
    virtual void render( glm::mat4 modelMatrix ) const = 0;
    
    explicit Renderable( GLProgram* program ) : _program( program ) {}
};


struct Sprite : Renderable
{
    GLTexture       _texture;
    GLVertexBuffer  _buffer;
    
    float           width = 1;
    float           height = 1;
    glm::vec3       spriteAxis = { 0, 0, 0 };
    
    Sprite( std::string texture, GLProgram* program );
    
    void render( glm::mat4 modelMatrix ) const;
};

struct Model : Renderable
{
    ObjMesh         _mesh;
    GLVertexBuffer  _buffer;
    
    GLenum           mode = GL_TRIANGLES;
    
    Model( const ObjMesh& mesh, GLProgram* program );
    
    void render( glm::mat4 modelMatrix ) const;
};

