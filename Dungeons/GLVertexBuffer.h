#pragma once

#include "GLHandle.h"

#include "VertexAttribute.h"

#include <tuple>
#include <vector>

using GLAttr = GLuint;

namespace gl_enums {
inline namespace usage {

    enum GLusage : GLenum
    {
        STREAM_DRAW  = GL_STREAM_DRAW,
        //STREAM_READ  = GL_STREAM_READ,
        //STREAM_COPY  = GL_STREAM_COPY,
        STATIC_DRAW  = GL_STATIC_DRAW,
        //STATIC_READ  = GL_STATIC_READ,
        //STATIC_COPY  = GL_STATIC_COPY,
        DYNAMIC_DRAW = GL_DYNAMIC_DRAW,
        //DYNAMIC_READ = GL_DYNAMIC_READ,
        //DYNAMIC_COPY = GL_DYNAMIC_COPY
    };
}}

template< GLsizei N >
class GLVertexBuffers
{
public:
    static const GLsizei SIZE = N;

    static_assert( SIZE > 0, "" );

    using ptr_t = std::shared_ptr< GLVertexBuffers >;

    GLHandle            vertexArray;
    GLHandles< SIZE >   vertexBuffers;
    //std::array< GLHandle, SIZE >    vertexBuffers   = {};

    //Array< GLAttr >        attrs;
    //Array< GLenum >        types;
    //Array< GLint >         widths;
    //Array< GLsizei >       strides;
    //Array< const GLvoid* > datas;
    //Array< GLsizeiptr >    sizes;

    template<
        typename Vertex,
        typename... Attrs,
        typename = meta::require_condition< SIZE == 1 >,
        typename = meta::require_condition< (sizeof...(Attrs) > 0) >,
        typename = meta::require_homogeneous_args< VertexAttribute, Attrs... >
    >
    GLVertexBuffers
    (
        const Vertex*       data,
        GLsizei             count,
        gl_enums::GLusage   usage,
        Attrs&&...          attrs
    )
    {
        static_assert( !std::is_void< Vertex >::value, "Must use typed pointer" );

        glGenVertexArrays( 1, &vertexArray );
        glBindVertexArray( vertexArray );

        glGenBuffers( SIZE, &vertexBuffers );
        glBindBuffer( GL_ARRAY_BUFFER, vertexBuffers[ 0 ] );

        glBufferData( GL_ARRAY_BUFFER, count * sizeof(Vertex), data, usage );

        GLint offset = 0;
        for ( VertexAttribute attr : { std::forward< Attrs >( attrs )... } )
        {
            glEnableVertexAttribArray( attr.index );
            glVertexAttribPointer( attr.index, attr.width, attr.type,
                GL_FALSE, sizeof(Vertex), (GLvoid*) offset );
            offset += attr.size;
        }
    }

    /*template<
        typename Vertex,
        typename... Attrs,
        typename = meta::require_condition< sizeof...(Attrs) == SIZE >,
        typename = meta::require_homogeneous_args< VertexAttribute, Attrs... >
    >
    GLVertexBuffers
    (
        const std::vector< Vertex >&    vertices,
        gl_enums::GLusage               usage,
        Attrs&&...                      attrs
    )
    {
        glGenVertexArrays( 1, &vertexArray );
        glBindVertexArray( vertexArray );

        glGenBuffers( SIZE, &vertexBuffers );
        glBindBuffer( GL_ARRAY_BUFFER, vertexBuffers[ 0 ] );

        const GLsizei size = vertices.size() * sizeof Vertex;
        glBufferData( GL_ARRAY_BUFFER, size, vertices.data(), usage );

        GLint offset = 0;
        for ( VertexAttribute attr : { std::forward< Attrs >( attrs )... } )
        {
            GLsizei stride = sizeof Vertex - attr.size;
            glEnableVertexAttribArray( attr.index );
            glVertexAttribPointer( attr.index, attr.width, attr.type,
                GL_FALSE, stride, (void*) offset );
            offset += attr.size;
        }

        for ( int i = 0; i < SIZE; i++ )
        {
            glEnableVertexAttribArray( attrlist[ i ]->index );
            glVertexAttribPointer(
                attrlist[ i ]->index,
                attrlist[ i ]->width,
                attrlist[ i ]->type,
                GL_FALSE,
                attrlist[ i ]->stride,
                (void*) attrlist[ i ]->offset );
        }
    }*/

    void draw(
        GLenum  mode,
        GLint   first,
        GLuint  count ) const
    {
        glBindVertexArray( vertexArray );
        glDrawArrays( mode, first, count );
    }
};

using GLVertexBuffer = GLVertexBuffers< 1 >;
