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


struct GraphicsComponent
{
    EntityId    entityId;
    bool        visible;
    GLProgram*  program;
    Model*      model;
    Sprite*     sprite;
    
    std::function< void(GraphicsComponent*, glm::mat4, glm::mat4, glm::mat4) > delegate;
    
    void update( glm::mat4 model, glm::mat4 view, glm::mat4 proj )
    {
        delegate( this, model, view, proj );
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

