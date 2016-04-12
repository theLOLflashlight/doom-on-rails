#pragma once

#include "glhelp.h"
#include "ObjMesh.h"

#include <vector>
#include <memory>
#include <string>


struct Sprite
{
    GLTexture       _texture;
    GLProgram*      _program;
    GLVertexBuffer  _buffer;
    
    float           width = 1;
    float           height = 1;
    glm::vec3       spriteAxis = { 0, 0, 0 };
    
    Sprite( std::string texture, GLProgram* program );
    
    void render( glm::mat4 model ) const;

};

struct Model
{
    Model( const ObjMesh& mesh, GLProgram* program );

    //void render() const;
    void render( glm::mat4 model,
                 GLenum    mode = GL_TRIANGLES ) const;

    ObjMesh             _mesh;
    GLProgram*          _program;
    GLVertexBuffer      _buffer;
};

