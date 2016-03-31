#include "GLHandle.h"


GLHandle::GLHandle( GLname name )
    : Super( name )
{
}

GLHandle::GLHandle( GLHandle&& move )
    : Super( std::move( move ) )
{
}

GLHandle& GLHandle::operator =( GLHandle&& move )
{
    Super::operator=( std::move( move ) );
    return *this;
}

GLHandle::operator GLname() const
{
    return _glHandle;
}