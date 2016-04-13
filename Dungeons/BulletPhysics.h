// Andrew

#include "btBulletDynamicsCommon.h"

struct BulletPhysics
{
    btDbvtBroadphase                        _broadphase;
    btDefaultCollisionConfiguration         _collisionConfiguration;
    btCollisionDispatcher                   _dispatcher;
    btSequentialImpulseConstraintSolver     _solver;
    btDiscreteDynamicsWorld                 world;
    
    explicit BulletPhysics( float gravity = 0 )
        : _broadphase()
        , _collisionConfiguration()
        , _dispatcher( &_collisionConfiguration )
        , _solver()
        , world( &_dispatcher, &_broadphase, &_solver, &_collisionConfiguration )
    {
        world.setGravity( btVector3( 0, gravity, 0 ) );
    }
    
    
    void update( float elapsedTime, int maxSubSteps = 10 )
    {
        world.stepSimulation( elapsedTime, maxSubSteps );
    }
    
    void addRigidBody( btRigidBody* body )
    {
        world.addRigidBody( body );
    }
    
    void addCollisionObject( btCollisionObject* obj )
    {
        world.addCollisionObject( obj );
    }
    
    void removeRigidBody( btRigidBody* body )
    {
        world.removeRigidBody( body );
    }
    
    void removeCollisionObject( btCollisionObject* obj )
    {
        world.removeCollisionObject( obj );
    }
    
};
