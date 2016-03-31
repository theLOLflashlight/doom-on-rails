#pragma once

#include "GLHandle.h"
#include "GLShader.h"
#include "VertexAttribute.h"

#include "gl_types.hpp"

#include <vector>
#include <string>
#include <fstream>
#include <initializer_list>

//using Uniforms = std::vector< GLuint >;

class GLShader;

class GLProgram
{
public:

    using ptr_t = std::shared_ptr< GLProgram >;

    //using AttributesInfo    = const std::vector< std::string >&;
    //using UniformsInfo      = const std::vector< std::string >&;

    //int         attr_count;
    //Uniforms    uniforms;

    GLHandle    glHandle;

    template<
        typename... Attrs,
        typename = meta::require_condition< (sizeof...(Attrs) <= 4) >
    > 
    GLProgram
    (
        std::string     vertPath,
        std::string     fragPath,
        Attrs&&...      attrs
    )
        : glHandle( glCreateProgram() )
    {
        using std::string;
        using std::forward;
        using std::ifstream;

        GLShader vert_shader( GLShader::VERTEX, vertPath );
        GLShader frag_shader( GLShader::FRAGMENT, fragPath );

        int i = 0;
        // Ensure our attribute names aren't optimized away before linking.
        for ( string attr : { string( forward< Attrs >( attrs ) )... } )
            glBindAttribLocation( glHandle, i++, attr.c_str() );

        link( &vert_shader, &frag_shader );
        validate();
    }


    GLProgram( GLProgram&& move );
    GLProgram& operator =( GLProgram&& move );

    void link( GLShader* vert_shader, GLShader* frag_shader );

    bool validate();

    void bind() const;

    GLuint find_attribute( const GLchar* name ) const
    {
        return glGetAttribLocation( glHandle, name );
    }

    GLuint find_uniform( const GLchar* name ) const
    {
        return glGetUniformLocation( glHandle, name );
    }

    template< typename Attr >
    VertexAttribute make_vert_attribute( const char* name ) const
    {
        using value_type = typename Attr::value_type;

        return VertexAttribute(
            find_attribute( name ),
            gl::type_constant< value_type >(),
            sizeof(Attr) / sizeof(value_type),
            sizeof(Attr) );
    }

    struct Exception
        : GLException
    {
        enum Type {
            INIT, READ, LINK
        };

        Type type;
        status_t status;

        Exception( const GLProgram& program, Type type, status_t status = 0 )
            : GLException( program.glHandle )
            , type( type )
            , status( status )
        {
        }
    };
};

