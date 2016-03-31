#include "Entity.h"

using namespace glm;

Entity::Entity
(
    const Model*    model, 
    vec3            position,
#if USE_QUATERNIONS
    vec4            orientation,
#else
    vec3            rotation,
#endif
    vec3            scale,
    vec4            color
)
    : model( model )
    , position( position )
#if USE_QUATERNIONS
    , orientation( orientation )
#else
    , rotation( rotation )
#endif
    , scale( scale )
    , color( color )
{
}

void Entity::render( mat4 view, mat4 proj ) const
{
    mat4 transform;
    transform = translate( transform, position );
#if USE_QUATERNIONS
    auto q = orientation;
    transform *=
        mat4( q.w,    q.z,    -q.y,   q.x,
              -q.z,   q.w,    q.x,    q.y,
              q.y,    -q.x,   q.w,    q.z,
              -q.x,   -q.y,   -q.z,   q.w )
        *
        mat4( q.w,    q.z,    -q.y,   -q.x,
              -q.z,   q.w,    q.x,    -q.y,
              q.y,    -q.x,   q.w,    -q.z,
              -q.x,   -q.y,   -q.z,   -q.w );
#else
    transform = rotate( transform, rotation.x, vec3( 1, 0, 0 ) );
    transform = rotate( transform, rotation.y, vec3( 0, 1, 0 ) );
    transform = rotate( transform, rotation.z, vec3( 0, 0, 1 ) );
#endif
    transform = glm::scale( transform, scale );

    glUniform4fv( model->_program->find_uniform( "uColor" ),
                  1, &color[ 0 ] );
    
    model->render( transform, view, proj );
}
