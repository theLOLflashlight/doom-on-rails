#pragma once

#include "GLHandle.h"
#include "Material.h"
#include "Vertex.h"


#include <vector>
#include <string>


struct TextureMap
{
    std::shared_ptr< Material > material;
    int offset, count;

    TextureMap() = default;

    TextureMap( std::shared_ptr< Material > mtl, int offset )
        : material( mtl )
        , offset( offset )
        , count( 0 )
    {
    }

    void finish( int end )
    {
        count = end - offset;
    }
};

struct ObjMesh
    : public std::vector< ObjVertex >
{
    std::vector< TextureMap > textures;
    std::vector< glm::vec3 >  rail;

    explicit ObjMesh( std::string path );
};


