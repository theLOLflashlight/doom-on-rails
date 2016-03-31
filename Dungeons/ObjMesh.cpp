#include "ObjMesh.h"

#include "Material.h"

//#include "glm/gtc/matrix_transform.hpp"
//#include "glm/gtx/transform.hpp"

#include "ios_path.h"

#include <memory>
#include <string>
#include <map>

using std::map;
using std::vector;
using std::string;
using std::shared_ptr;
using std::make_shared;
using glm::vec3;
using glm::vec2; 

using Mtllib = map< string, shared_ptr< Material > >;

bool load_materials( const char* mtlname, Mtllib& mtllib );

ObjMesh::ObjMesh( std::string path )
{
    FILE* file = fopen( path.c_str(), "r" );
    if ( file == 0 )
    {
        printf( "Could not open the file: %s\n", path.c_str() );
        return;
    }

    vector< vec3 > list_v;
    vector< vec3 > list_vn;
    vector< vec2 > list_vt;
    Mtllib         mtllib;

    char lineHeader[ 128 ];
    while ( fscanf( file, "%s", lineHeader ) != EOF )
    {
        const string tag = lineHeader;

        if ( !tag.empty() && tag.front() == '#' )
        {
            char buff[ 512 ];
            fgets( buff, 512, file );
        }
        else if ( tag == "v" )
        {
            vec3 v;
            fscanf( file, "%f %f %f\n", &v.x, &v.y, &v.z );
            list_v.push_back( v );
        }
        else if ( tag == "vn" )
        {
            vec3 vn;
            fscanf( file, "%f %f %f\n", &vn.x, &vn.y, &vn.z );
            list_vn.push_back( vn );
        }
        else if ( tag == "vt" )
        {
            vec2 vt;
            fscanf( file, "%f %f\n", &vt.x, &vt.y );
            list_vt.push_back( vt );
        }
        else if ( tag == "f" )
        {
            GLuint v[3], vt[3], vn[3];
            int matches = fscanf( file, "%d/%d/%d %d/%d/%d %d/%d/%d\n",
                    &v[ 0 ], &vt[ 0 ], &vn[ 0 ],
                    &v[ 1 ], &vt[ 1 ], &vn[ 1 ], 
                    &v[ 2 ], &vt[ 2 ], &vn[ 2 ] );
            if ( matches != 9 )
            {
                printf( "Error parsing face in file '%s'\n", path.c_str() );
                fclose( file );
                return;
            }

            reserve( size() + 3 );
            for ( int i = 0; i < 3; i++ )
                emplace_back(
                    list_v[ v[ i ] - 1 ],
                    list_vn[ vn[ i ] - 1 ],
                    list_vt[ vt[ i ] - 1 ] );
        }
        else if ( tag == "l" )
        {
            GLuint v[2];
            int matches = fscanf( file, "%d %d\n", &v[0], &v[1] );
            if ( matches != 2 )
            {
                printf( "Error parsing line in file '%s'\n", path.c_str() );
                fclose( file );
                return;
            }
            
            rail.reserve( rail.size() + 2 );
            auto min = std::min( v[0], v[1] );
            auto max = std::max( v[0], v[1] );
            rail.emplace_back( list_v[ min - 1 ] );
            rail.emplace_back( list_v[ max - 1 ] );
        }
        else if ( tag == "mtllib" )
        {
            char mtl[ 128 ];
            fscanf( file, "%s\n", mtl );

            load_materials( ios_path( mtl ), mtllib );
        }
        else if ( tag == "usemtl" )
        {
            if ( !textures.empty() )
                textures.back().finish( size() );

            char mtl[ 128 ];
            fscanf( file, "%s\n", mtl );

            textures.emplace_back( mtllib[ mtl ], size() );
        }
    }

    if ( !textures.empty() )
        textures.back().finish( size() );
}

bool load_materials( const char* mtlname, Mtllib& mtllib )
{
    FILE* mtlfile = fopen( mtlname, "r" );
    if ( mtlfile == 0 )
    {
        printf( "Could not open the mtl file: %s\n", mtlname );
        return false;
    }

    shared_ptr< Material > currmat = nullptr;
    char lineHeader[ 128 ];

    while ( fscanf( mtlfile, "%s", lineHeader ) != EOF )
    {
        const std::string tag = lineHeader;

        if ( !tag.empty() && tag.front() == '#' )
        {
            char buff[ 512 ];
            fgets( buff, 512, mtlfile );
        }
        else if ( tag == "newmtl" )
        {
            currmat = make_shared< Material >();
            fscanf( mtlfile, "%s\n", currmat->Name );
            mtllib[ currmat->Name ] = currmat;
        }
        else if ( currmat != nullptr )
        {
            if ( tag == "Ka" )
            {
                fscanf( mtlfile, "%f %f %f\n", &currmat->Ka.r, &currmat->Ka.g, &currmat->Ka.b );
            }
            else if ( tag == "Kd" )
            {
                fscanf( mtlfile, "%f %f %f\n", &currmat->Kd.r, &currmat->Kd.g, &currmat->Kd.b );
            }
            else if ( tag == "Ks" )
            {
                fscanf( mtlfile, "%f %f %f\n", &currmat->Ks.r, &currmat->Ks.g, &currmat->Ks.b );
            }
            else if ( tag == "Ns" )
            {
                fscanf( mtlfile, "%f\n", &currmat->Ns );
            }
            else if ( tag == "d" )
            {
                fscanf( mtlfile, "%f\n", &currmat->d );
            }
            else if ( tag == "Tr" )
            {
                GLfloat Tr = 0;
                fscanf( mtlfile, "%f\n", &Tr );
                currmat->d = 1 - Tr;
            }
            else if ( tag == "map_Ka" )
            {
                char path[ 64 ];
                fscanf( mtlfile, "%s\n", path );
                currmat->map_Ka = make_shared< GLTexture >( ios_path( path ) );
            }
            else if ( tag == "map_Kd" )
            {
                char path[ 64 ];
                fscanf( mtlfile, "%s\n", path );
                currmat->map_Kd = make_shared< GLTexture >( ios_path( path ) );
            }
            else if ( tag == "map_Ks" )
            {
                char path[ 64 ];
                fscanf( mtlfile, "%s\n", path );
                currmat->map_Ks = make_shared< GLTexture >( ios_path( path ) );
            }
            else if ( tag == "map_Ns" )
            {
                char path[ 64 ];
                fscanf( mtlfile, "%s\n", path );
                currmat->map_Ns = make_shared< GLTexture >( ios_path( path ) );
            }
            else if ( tag == "map_d" )
            {
                char path[ 64 ];
                fscanf( mtlfile, "%s\n", path );
                currmat->map_d = make_shared< GLTexture >( ios_path( path ) );
            }
            else if ( tag == "map_bump" )
            {
                char path[ 64 ];
                fscanf( mtlfile, "%s\n", path );
                currmat->map_bump = make_shared< GLTexture >( ios_path( path ) );
            }
        }
    }

    fclose( mtlfile );
    return true;
}