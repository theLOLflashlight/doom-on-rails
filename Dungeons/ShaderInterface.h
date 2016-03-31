#pragma once

#include "ShaderLoader.h"

#include <memory>

class ShaderInterface
{
public:

    char* vertexStr;
    char* fragmentStr;

    std::shared_ptr< ShaderLoader > shader;

    struct {
        GLint aPosition;
        //GLint aWorld;
        GLint uColor;
    };

    ShaderInterface() = default;
    ShaderInterface( const char* vs, const char* fs );
    ~ShaderInterface();
};

