#include "GLTexture.h"

#include "SOIL.h"

using std::string;

#define SOIL_LOAD_OGL_TEXTURE_OPTIONS               \
SOIL_LOAD_AUTO,     /*force_channels*/              \
SOIL_CREATE_NEW_ID, /*reuse_texture_id*/            \
SOIL_FLAG_MIPMAPS |                                 \
SOIL_FLAG_INVERT_Y |                                \
SOIL_FLAG_NTSC_SAFE_RGB |                           \
SOIL_FLAG_TEXTURE_REPEATS |                         \
SOIL_FLAG_COMPRESS_TO_DXT


GLname load_texture( string path )
{
    return SOIL_load_OGL_texture( path.c_str(), SOIL_LOAD_OGL_TEXTURE_OPTIONS );
}

GLTexture::GLTexture( const char* path )
    : GLTexture( string( path ) )
{
}

GLTexture::GLTexture( string path )
    : glHandle( load_texture( path ) )
{
    if ( glHandle == 0 ) {
        const char* error = SOIL_last_result();
        printf( "Could not load texture '%s', error: '%s'\n", path.c_str(), error );
        throw Exception( *this, error );
    }
}

GLTexture::GLTexture( GLTexture&& move )
    : glHandle( std::move( move.glHandle ) )
{
}

GLTexture & GLTexture::operator=( GLTexture&& move )
{
    glHandle = std::move( move.glHandle );
    return *this;
}

void GLTexture::bind( GLint unit ) const
{
    const GLenum tex_unit = GL_TEXTURE0 + unit;
#   ifdef _DEBUG
    if ( tex_unit < GL_TEXTURE0 || GL_TEXTURE31 < tex_unit )
        throw Exception( *this, "Texture unit out of range" );
#   endif
    glActiveTexture( tex_unit );
    bind();
}

void GLTexture::bind() const
{
    glBindTexture( GL_TEXTURE_2D, glHandle );
}
