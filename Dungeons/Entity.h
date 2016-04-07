#pragma once

#include "Model.h"

#include "glm/glm.hpp"

#include <functional>


struct EntityId
{
    static const uint64_t NO_ENTITY = std::numeric_limits< uint64_t >::max();
    
    uint64_t bitPattern;
    
    EntityId()
        : bitPattern( NO_ENTITY ) {}
    
    explicit EntityId( uint64_t entityId )
        : bitPattern( entityId ) {}
    
    explicit EntityId( const char* entityName )
    {
        std::strncpy( (char*) &bitPattern, entityName, sizeof( bitPattern ) );
        
        if ( std::strlen( entityName ) > 8 )
            std::printf( "Warning: EntityId initialized with overlength name \"%s\".", entityName );
    }
};

struct Component
{
    EntityId    entityId;
    bool        enabled;
    
    Component()
        : entityId()
        , enabled( false )
    {
    }
    
    explicit Component( uint64_t entityId )
        : entityId( entityId )
        , enabled( true )
    {
    }
    
    explicit Component( const char* entityName )
        : entityId( entityName )
        , enabled( true )
    {
    }
};


struct GraphicalComponent
{
    EntityId    entityId;
    bool        visible;
    GLProgram*  program = 0;
    Model*      model   = 0;
    Sprite*     sprite  = 0;
    
    GraphicalComponent( EntityId _id, bool _visible = false )
        : entityId( _id )
        , visible( _visible )
    {
    }
    
    //std::function< void(GraphicsComponent*, glm::mat4, glm::mat4, glm::mat4) > delegate;
    
    void update( glm::mat4 _model, glm::mat4 _view, glm::mat4 _proj )
    {
        if ( !visible )
            return;
        
        if ( model )
            model->render( _model, _view, _proj, GL_TRIANGLES );
        
        //delegate( this, model, view, proj );
    }
};

struct PhysicalComponent
{
    EntityId    entityId;
    bool        active;
    glm::vec3   position;
    glm::vec3   rotation;
    
    glm::mat4   model() const
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


struct Entity
{
    const Model*    model;
    glm::vec3       position;
    glm::vec3       rotation;
    glm::vec3       scale;
    glm::vec4       color;

    Entity
    (
        const Model*    model,
        glm::vec3       position        = {},
        glm::vec3       rotation        = {},
        glm::vec3       scale           = { 1, 1, 1 },
        glm::vec4       color           = { 1, 1, 1, 0 }
    );

    void render( glm::mat4 view, glm::mat4 proj ) const;
};

