#pragma once

#include "gl.h"

struct VertexAttribute
{
    GLuint          index;
    const GLenum    type;
    const GLint     width;
    const GLsizei   size;
    //GLsizei         value_size;
    //GLsizei         stride;
    //GLint           offset;

    VertexAttribute
    (
        GLuint  index,
        GLenum  type,
        GLint   width,
        GLsizei size
        //GLsizei value_size,
        //GLsizei stride = 0,
        //GLint   offset = 0
    )
        : index( index )
        , type( type )
        , width( width )
        , size( size )
        //, value_size( value_size )
        //, stride( stride )
        //, offset( offset )
    {
    }
};

/*template< typename Attr >
struct VertexAttributeTraits
{
    using   attr_type               = Attr;
    using   value_type              = typename Attr::value_type;

    static  const GLint     LENGTH  = sizeof(Attr) / sizeof(value_type);
    static  const GLenum    TYPE    = gl::type_constant< value_type >();
};*/
