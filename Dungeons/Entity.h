#pragma once

#include "Model.h"

#include "glm/glm.hpp"
#include "glhelp.h"
#include "btBulletDynamicsCommon.h"

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
        bitPattern <<= (8 - (N - 1)) * 8;
    }
    
    template< uint N, typename = typename std::enable_if< (N <= 7) >::type >
    EntityId( const char (&tag)[ N ], uint16_t index )
    {
        std::strncpy( (char*) &bitPattern, tag, sizeof( bitPattern ) );
        bitPattern <<= sizeof( index ) * 8;
        bitPattern |= uint64_t( index );
    }
    
    template< uint N, typename = typename std::enable_if< (N <= 7) >::type >
    static bool matchesTag( const char (&tag)[ N ], EntityId _id )
    {
        return _id.bitPattern >= EntityId( tag, 0 ).bitPattern
            && _id.bitPattern <= EntityId( tag, 65535 ).bitPattern;
    }
};

inline bool operator ==( const EntityId& _l, const EntityId& _r )
{
    return _l.bitPattern == _r.bitPattern;
}

inline bool operator <( const EntityId& _l, const EntityId& _r )
{
    return _l.bitPattern < _r.bitPattern;
}

namespace std
{
    template<>
    struct hash< EntityId >
    {
        typedef EntityId argument_type;
        typedef std::size_t result_type;
        
        result_type operator()( const argument_type& eid ) const
        {
            return std::hash< uint64_t >{}( eid.bitPattern );
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
    enum Visibility
    {
        INVISIBLE = 0,
        VISIBLE,
        TRANSLUCENT
    };
    
    EntityId    entityId;
    Visibility  visibility;
    GLProgram*  program = 0;
    Model*      model   = 0;
    Sprite*     sprite  = 0;
    glm::vec4   color   = { 1, 1, 1, 0 };
    
    explicit GraphicalComponent( EntityId _id, Visibility _visibility = VISIBLE )
        : entityId( _id )
        , visibility( _visibility )
    {
    }
    
    GraphicalComponent( EntityId _id, bool _visible )
        : entityId( _id )
        , visibility( _visible ? VISIBLE : INVISIBLE )
    {
    }

    
    void update( EntityCollection& entities, glm::mat4 view, glm::mat4 proj )
    {
        using namespace glm;
        
        if ( visibility == INVISIBLE )
            return;
        
        if ( program ) {
            program->bind();
            glUniform4fv( program->find_uniform( "uColor" ), 1, &color[ 0 ] );
        }
        
        if ( visibility == TRANSLUCENT )
            glEnable( GL_BLEND );
        
        Entity ntt = entities[ entityId ];
        
        if ( model )
            model->render( ntt.transform_matrix(), GL_TRIANGLES );
        
        if ( sprite )
        {
            sprite->render( ntt.transform_matrix() );
        }
        
        if ( visibility == TRANSLUCENT )
            glDisable( GL_BLEND );
    }
};

struct PhysicalComponent
{
    EntityId        entityId;
    bool            active;
    btRigidBody*    body;
    
    explicit PhysicalComponent( EntityId _id, bool _active = true )
        : entityId( _id )
        , active( _active )
    {
    }
    
    void update( EntityCollection& entities )
    {
        if ( !active )
            return;
        
        btTransform trans;
        body->getMotionState()->getWorldTransform( trans );
        
        btVector3 pos = trans.getOrigin();
        
        Entity& entity = entities[ entityId ];
        entity.position = glm::vec3( pos.x(), pos.y(), pos.z() );
        //entity.rotation = rotation;
    }
};


struct HealthComponent
{
    EntityId    entityId;
    float       health;
    
    HealthComponent( EntityId _id, float maxHealth )
        : entityId( _id )
        , health( maxHealth )
    {
    }
    
    void update( EntityCollection& entities )
    {
        if ( health <= 0 )
        {
            
        }
    }
};


struct BehavioralComponent
{
    using Delegate = std::function< void(BehavioralComponent*, EntityCollection&, double) >;
    
    EntityId    entityId;
    bool        enabled;
    Delegate    functor;
    
    explicit BehavioralComponent( EntityId _id, bool _enabled = true )
        : entityId( _id )
        , enabled( _enabled )
    {
    }
    
    void update( EntityCollection& entities, double time )
    {
        if ( !enabled )
            return;
        
        if ( functor )
            functor( this, entities, time );
    }
};

