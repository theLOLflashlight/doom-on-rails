#include "Entity.h"

using namespace glm;

Entity::Entity
(
    const Model*    model, 
    vec3            position,
    vec3            rotation,
    vec3            scale,
    vec4            color
)
    : model( model )
    , position( position )
    , rotation( rotation )
    , scale( scale )
    , color( color )
{
}

void Entity::render( mat4 view, mat4 proj ) const
{
    mat4 transform;
    transform = translate( transform, position );
    
    transform = rotate( transform, rotation.x, vec3( 1, 0, 0 ) );
    transform = rotate( transform, rotation.y, vec3( 0, 1, 0 ) );
    transform = rotate( transform, rotation.z, vec3( 0, 0, 1 ) );
    
    transform = glm::scale( transform, scale );

    glUniform4fv( model->_program->find_uniform( "uColor" ), 1, &color[ 0 ] );
    
    model->render( transform, view, proj );
}
