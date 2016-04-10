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


inline glm::mat4 CreateBillboardMatrix( glm::vec3 right, glm::vec3 up, glm::vec3 look, glm::vec3 pos )
{
    return glm::mat4( glm::mat4x3( right, up, look, pos ) );
    /*bbmat[0][0] = right.x;
    bbmat[0][1] = right.y;
    bbmat[0][2] = right.z;
    bbmat[0][3] = 0;
    bbmat[1][0] = up.x;
    bbmat[1][1] = up.y;
    bbmat[1][2] = up.z;
    bbmat[1][3] = 0;
    bbmat[2][0] = look.x;
    bbmat[2][1] = look.y;
    bbmat[2][2] = look.z;
    bbmat[2][3] = 0;
    // Add the translation in as well.
    bbmat[3][0] = pos.x;
    bbmat[3][1] = pos.y;
    bbmat[3][2] = pos.z;
    bbmat[3][3] = 1;*/
}

inline glm::mat4 BillboardPoint( glm::vec3 pos, glm::vec3 camPos, glm::vec3 camUp )
{	// create the look vector: pos -> camPos
    glm::vec3	look	= glm::normalize( camPos - pos );
    
    // right hand rule cross products
    glm::vec3	right	= glm::cross( camUp, look );
    glm::vec3	up		= glm::cross( look, right );
    
    glm::mat4	bbmat;
    return CreateBillboardMatrix( right, up, look, pos );
    
    // apply the billboard
    return bbmat;
}

inline glm::mat4 BillboardAxisY( glm::vec3 pos, glm::vec3 camPos )
{	// create the look vector: pos -> camPos
    glm::vec3	look	= camPos - pos;
    look.y = 0;
    look = glm::normalize( look );
    
    // right hand rule cross products
    glm::vec3	up		= glm::vec3( 0, 1, 0 );
    glm::vec3	right	= glm::cross( up, look );
    
    glm::mat4	bbmat;
    return CreateBillboardMatrix( right, up, look, pos );
    
    // apply the billboard
    return bbmat;
}

inline glm::mat4 BillboardAxis( glm::vec3 pos, glm::vec3 camPos, glm::vec3 axis )
{	// create the look vector: pos -> camPos
    glm::vec3	look	= glm::normalize( camPos - pos );
    
    // right hand rule cross products
    glm::vec3	up		= axis;
    glm::vec3	right	= glm::normalize( glm::cross( up, look ) );
    look = glm::cross( right, up );
    
    glm::mat4	bbmat;
    return CreateBillboardMatrix( right, up, look, pos );
    
    // apply the billboard
    return bbmat;
}

inline glm::vec3 extract_eye_pos( glm::mat4 model, glm::mat4 view )
{
    using namespace glm;
    mat4 model_view = view * model;
    vec4 d          = vec4( vec3( model_view[3] ), 1 );
    
    return vec3( -d * model_view );
    //return vec4( (model * view)[3] );
}

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
    Model*      sprite  = 0;
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
        
        if ( program )
            glUniform4fv( program->find_uniform( "uColor" ), 1, &color[ 0 ] );
        
        if ( visibility == TRANSLUCENT )
            glEnable( GL_BLEND );
        
        if ( model )
            model->render( entities[ entityId ].transform_matrix(), view, proj, GL_TRIANGLES );
        
        if ( sprite )
        {
            Entity ntt = entities[ entityId ];

            mat4 mod = ntt.transform_matrix();
            
            mod *= BillboardPoint( vec3( 0, 0, 0 ), vec3( row( view, 2 ) ), vec3( column( view, 1 ) ) );
            
            mod = scale( mod, vec3( 1, 1, 0 ) );
            
            //mod *= BillboardAxisY( vec3( 0, 0, 0 ), vec3( row( view, 2 ) ) );
            
            //mod = lookAt( ntt.position, vec3( row( view, 2 ) ), vec3( column( view, 1 ) ) );
            
            sprite->render( mod, view, proj, GL_TRIANGLES );
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
    using Delegate = std::function< void(BehavioralComponent*, EntityCollection&) >;
    
    EntityId    entityId;
    bool        enabled;
    Delegate    functor;
    
    explicit BehavioralComponent( EntityId _id, bool _enabled = true )
        : entityId( _id )
        , enabled( _enabled )
    {
    }
    
    void update( EntityCollection& entities )
    {
        if ( !enabled )
            return;
        
        if ( functor )
            functor( this, entities );
    }
};

