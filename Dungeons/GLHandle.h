#pragma once

#include "template_helper.hpp"

#include "gl.h"

#include <array>
#include <memory>

// An OpenGL object name.
using GLname = GLuint;

template< GLsizei N >
// Holds an array of GLnames. Deallocates memory when destructed.
class GLHandles
{
public:
    static const GLsizei SIZE = N;
    static_assert( SIZE > 0,
    "Number of stored names must be a natural number (greater than 0)" );

    using value_t   = GLname;
    using data_t    = std::array< value_t, SIZE >;
    //using ptr_t     = std::shared_ptr< GLHandles >;

    // Releases OpenGL resources.
    ~GLHandles();
    GLHandles( const GLHandles& copy ) = delete;
    GLHandles( GLHandles&& move );

    explicit GLHandles( data_t handles = {} );

    template<
        typename... Names,
        typename = meta::require_condition< sizeof...(Names) == SIZE >,
        typename = meta::require_homogeneous_args< value_t, Names... > >
    explicit GLHandles( Names... names )
        : _glHandles( { value_t( names )... } )
    {
    }

    //operator const GLname*();
                                
    auto operator &     ()                      -> GLname*;         // Gets a mutable pointer to the OpenGL name stored by this object.
    auto operator []    ( GLsizei n )           -> GLname&;         // Gets the nth OpenGL name stored by this object.
    auto operator =     ( GLHandles&& move )    -> GLHandles&;      // Move assignment.
    auto size           () const                -> GLsizei;         // Gets the number of OpenGL names stored in this object.
    auto handle         () const                -> const GLname&;   // Gets a reference to the first stored OpenGL name.

protected:
    
    void reset();   // Sets all stored OpenGL names to 0. Does not release memory.

    union {
        value_t _glHandle;  // First stored OpenGL name.
        data_t  _glHandles; // Array of stored OpenGL names.
    };
};

template< GLsizei N >
inline const GLname& GLHandles< N >::handle() const
{
    return _glHandle;// _glHandles[ 0 ];
}

template< GLsizei N >
inline void GLHandles< N >::reset()
{
    _glHandles.fill( 0 );
}

template< GLsizei N >
inline GLHandles< N >::~GLHandles()
{
    if ( _glHandle == 0 )
        return;

    else if ( N == 1 && glIsShader( _glHandle ) )
        glDeleteShader( _glHandle );

    else if ( N == 1 && glIsProgram( _glHandle ) )
        glDeleteProgram( _glHandle );

    else if ( glIsBuffer( _glHandle ) )
        glDeleteBuffers( SIZE, &_glHandle );

    else if ( glIsVertexArray( _glHandle ) )
        glDeleteVertexArrays( SIZE, &_glHandle );

    else if ( glIsTexture( _glHandle ) )
        glDeleteTextures( SIZE, &_glHandle );
    
    //else if ( glIsSampler( _glHandle ) )
    //    glDeleteSamplers( SIZE, &_glHandle );

    else if ( glIsFramebuffer( _glHandle ) )
        glDeleteFramebuffers( SIZE, &_glHandle );

    else if ( glIsRenderbuffer( _glHandle ) )
        glDeleteRenderbuffers( SIZE, &_glHandle );

    //else if ( glIsTransformFeedback( _glHandle ) )
    //    glDeleteTransformFeedbacks( SIZE, &_glHandle );

    //else if ( glIsQuery( _glHandle ) )
    //    glDeleteQueries( SIZE, &_glHandle );

    //else
    //    std::abort();

    this->reset();
}

// Holds a single GLname. Deallocates memory when destructed.
class GLHandle
    : public GLHandles< 1 >
{
public:
    using Super = GLHandles< 1 >;

    using ptr_t = std::shared_ptr< GLHandle >;

    GLHandle( const GLHandle& copy ) = delete;
    GLHandle( GLHandle&& move );

    GLHandle( GLname name = 0 );

    operator GLname() const;

    GLHandle& operator =( GLHandle&& move );
};


template< GLsizei N >
inline GLHandles< N >::GLHandles( data_t handles )
    : _glHandles( handles )
{
}

template< GLsizei N >
inline GLHandles< N >::GLHandles( GLHandles&& move )
    : _glHandles( std::move( move._glHandles ) )
{
    move.reset();
}

//template< GLsizei N >
//inline GLHandles< N >::operator const GLname*()
//{
//    return &_glHandles;
//}

template< GLsizei N >
inline auto GLHandles< N >::operator &() -> GLname*
{
    return &_glHandle;
}

template< GLsizei N >
inline auto GLHandles< N >::operator []( GLsizei n ) -> GLname&
{
    return _glHandles[ n ];
}

template< GLsizei N >
inline auto GLHandles< N >::operator =( GLHandles&& move ) -> GLHandles&
{
    std::swap( _glHandles, move._glHandles );
    return *this;
}

template< GLsizei N >
inline GLsizei GLHandles< N >::size() const
{
    return SIZE;
}


class GLException
{
public:

    using status_t = GLint;

    const GLname glName;
    const GLsizei size;

    template< GLsizei N >
    explicit GLException( const GLHandles< N >& handle )
        : glName( handle.handle() )
        , size( handle.size() )
    {
    }
};

