#pragma once

#include "GLHandle.h"

#include <string>

class GLTexture
{
public:
    using ptr_t = std::shared_ptr< GLTexture >;

    GLHandle    glHandle;

    GLTexture( GLTexture&& move );

    explicit GLTexture( std::string path );
    explicit GLTexture( const char* path );

    GLTexture& operator =( GLTexture&& move );

    void bind( GLint unit ) const;
    void bind() const;

    struct Exception
        : GLException
    {
        std::string message;

        Exception( const GLTexture& texture, std::string message )
            : GLException( texture.glHandle )
            , message( message )
        {
        }
    };
};
