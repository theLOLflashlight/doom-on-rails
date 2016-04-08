#pragma once

#include "Model.h"

#include "glm/glm.hpp"

#include <functional>
#include <unordered_map>


struct EntityId
{
    static const uint64_t NO_ENTITY = std::numeric_limits< uint64_t >::max();
    
    uint64_t bitPattern;
    
    EntityId()
        : bitPattern( NO_ENTITY ) {}
    
    EntityId( uint64_t entityId )
        : bitPattern( entityId ) {}
    
    template< uint N, typename = typename std::enable_if< (N <= 9) >::type >
    EntityId( const char (&entityName)[ N ] )
    {
        std::strncpy( (char*) &bitPattern, entityName, sizeof( bitPattern ) );
        
        if ( std::strlen( entityName ) > 8 )
            std::printf( "Warning: EntityId initialized with overlength name \"%s\".", entityName );
    }
};

inline bool operator ==( const EntityId& _l, const EntityId& _r )
{
    return _l.bitPattern == _r.bitPattern;
}

namespace std
{
    template<>
    struct hash< EntityId >
    {
        typedef EntityId argument_type;
        typedef std::size_t result_type;
        
        result_type operator()(argument_type const& s) const
        {
            return std::hash< uint64_t >{}( s.bitPattern );
        }
    };
}

struct Entity
{
    glm::vec3   position;
    glm::vec3   rotation;
    
    Entity
    (
        glm::vec3   position        = {},
        glm::vec3   rotation        = {}
    )
        : position( position )
        , rotation( rotation )
    {
    }
    
    glm::mat4 transform_matrix() const
    {
        using namespace glm;
        mat4 transform;
        transform = translate( transform, position );
        
        transform = rotate( transform, rotation.x, vec3( 1, 0, 0 ) );
        transform = rotate( transform, rotation.y, vec3( 0, 1, 0 ) );
        transform = rotate( transform, rotation.z, vec3( 0, 0, 1 ) );
        
        return transform;
    }
};


typedef std::unordered_map< EntityId, Entity > EntityCollection;


struct GraphicalComponent
{
    EntityId    entityId;
    bool        visible;
    GLProgram*  program = 0;
    Model*      model   = 0;
    Sprite*     sprite  = 0;
    glm::vec4   color   = { 1, 1, 1, 0 };
    
    GraphicalComponent( EntityId _id, bool _visible = true )
        : entityId( _id )
        , visible( _visible )
    {
    }
    
    //std::function< void(GraphicsComponent*, glm::mat4, glm::mat4, glm::mat4) > delegate;
    
    void update( EntityCollection& entities, glm::mat4 _view, glm::mat4 _proj )
    {
        if ( !visible )
            return;
        
        if ( program )
            glUniform4fv( program->find_uniform( "uColor" ), 1, &color[ 0 ] );
        
        if ( model )
            model->render( entities[ entityId ].transform_matrix(), _view, _proj, GL_TRIANGLES );
        
        //delegate( this, model, view, proj );
    }
};

struct PhysicalComponent
{
    EntityId    entityId;
    bool        active;
    glm::vec3   position;
    glm::vec3   rotation;
    
    void update( EntityCollection& entities )
    {
        if ( !active )
            return;
        
        Entity& entity = entities[ entityId ];
        entity.position = position;
        entity.rotation = rotation;
    }
};

