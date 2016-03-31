#pragma once

#include "GLHandle.h"

#include <string>

class GLShader
{
public:
    using ptr_t = std::shared_ptr< GLShader >;

    enum Type {
        FRAGMENT = GL_FRAGMENT_SHADER,
        VERTEX = GL_VERTEX_SHADER,
    };

    GLHandle    glHandle;

    GLShader( Type type, const std::string& source );

    GLShader( GLShader&& move );
    GLShader& operator =( GLShader&& move );

    GLException::status_t compile();


    struct Exception
        : GLException
    {
        enum Type {
            INIT, READ, COMPILE
        };

        Type type;
        std::string file;
        status_t status;

        Exception( const GLShader& shader, Type type, std::string file, status_t status = 0 )
            : GLException( shader.glHandle )
            , type( type )
            , file( file )
            , status( status )
        {
        }
    };
};

