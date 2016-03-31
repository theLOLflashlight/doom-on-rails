#include "ShaderLoader.h"

GLuint compile_shader( GLenum shader, const char* source );

ShaderLoader::~ShaderLoader()
{
    glDeleteProgram( program );
}

ShaderLoader::ShaderLoader( const char* vertSrc, const char* fragSrc )
    : program( glCreateProgram() )
{
    GLuint vertexShader = compile_shader( GL_VERTEX_SHADER, vertSrc );
    GLuint fragmentShader = compile_shader( GL_FRAGMENT_SHADER, fragSrc );

    glAttachShader( program, vertexShader );
    glAttachShader( program, fragmentShader );

    glLinkProgram( program );

    glDeleteShader( vertexShader );
    glDeleteShader( fragmentShader );
}

GLuint compile_shader( GLenum shader, const char* source )
{
    GLuint shaderHandle = glCreateShader( shader );
    glShaderSource( shaderHandle, 1, &source, NULL );
    glCompileShader( shaderHandle );

    return shaderHandle;
}