#include "GLShader.h"

#include <fstream>

using std::string;
using std::istream;

GLShader::GLShader( Type type, const std::string& path )
    : glHandle( glCreateShader( GLenum( type ) ) )
{
    using itr_t = std::istreambuf_iterator< char >;
    std::ifstream fsource( path );

    if ( fsource.fail() )
        throw Exception( *this, Exception::READ, path );

    const string shader_source( (itr_t( fsource )), itr_t() );
    const GLchar* src = shader_source.c_str();

    glShaderSource( glHandle, 1, &src, NULL );
    auto status = compile();
    if ( status == GL_FALSE )
        throw Exception( *this, Exception::COMPILE, path, status );
}

GLShader::GLShader( GLShader&& move )
    : glHandle( std::move( move.glHandle ) )
{
}

GLShader& GLShader::operator=( GLShader&& move )
{
    glHandle = std::move( move.glHandle );
    return *this;
}

GLException::status_t GLShader::compile()
{
    glCompileShader( glHandle );

    Exception::status_t status;
    glGetShaderiv( glHandle, GL_COMPILE_STATUS, &status );

    int logLength;
    glGetShaderiv( glHandle, GL_INFO_LOG_LENGTH, &logLength );
    if ( logLength > 1 )
    {
        GLchar* log = new GLchar[ logLength ];
        
        glGetShaderInfoLog( glHandle, logLength, &logLength, log );
        printf( "Shader compile log: %s\n", log );
        delete log;
    }
    return status;
}
