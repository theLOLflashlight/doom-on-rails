//
//  BulletPhysics.m
//  BulletTest
//
//  Created by Borna Noureddin on 2015-03-20.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#import "BulletPhysics.h"
//#include "bullet-2.82-r2704/src/btBulletDynamicsCommon.h"

@interface BulletPhysics()
{
    btBroadphaseInterface*                  broadphase;
    btDefaultCollisionConfiguration*        collisionConfiguration;
    btCollisionDispatcher*                  dispatcher;
    btSequentialImpulseConstraintSolver*    solver;

    /*btCollisionShape *groundShape;
    btCollisionShape *fallShape;
    btDefaultMotionState *groundMotionState;
    btRigidBody *groundRigidBody;
    btDefaultMotionState *fallMotionState;
    btRigidBody *fallRigidBody;*/
}

@end

@implementation BulletPhysics

- (instancetype) init
{
    self = [super init];
    if (self) {
        broadphase = new btDbvtBroadphase();
        
        collisionConfiguration = new btDefaultCollisionConfiguration();
        dispatcher = new btCollisionDispatcher(collisionConfiguration);
        
        solver = new btSequentialImpulseConstraintSolver;
        
        _dynamicsWorld = new btDiscreteDynamicsWorld(dispatcher,broadphase,solver,collisionConfiguration);
        
        _dynamicsWorld->setGravity(btVector3(0,-9.81,0));
        
        /*groundShape = new btStaticPlaneShape(btVector3(0,1,0),1);
        
        fallShape = new btSphereShape(1);
        
        
        groundMotionState = new btDefaultMotionState(btTransform(btQuaternion(0,0,0,1),btVector3(0,1,0)));
        btRigidBody::btRigidBodyConstructionInfo
        groundRigidBodyCI(0,groundMotionState,groundShape,btVector3(0,0,0));
        groundRigidBody = new btRigidBody(groundRigidBodyCI);
        dynamicsWorld->addRigidBody(groundRigidBody);
        
        // change this to start sphere in a different location
        fallMotionState = new btDefaultMotionState(btTransform(btQuaternion(0,0,0,1),btVector3(0,5,0)));
        btScalar mass = 1;
        btVector3 fallInertia(0,0,0);
        fallShape->calculateLocalInertia(mass,fallInertia);
        btRigidBody::btRigidBodyConstructionInfo fallRigidBodyCI(mass,fallMotionState,fallShape,fallInertia);
        fallRigidBody = new btRigidBody(fallRigidBodyCI);
        dynamicsWorld->addRigidBody(fallRigidBody);*/
        
        NSLog(@"Starting bullet physics...\n");
    }
    return self;
}

- (void) dealloc
{
    delete _dynamicsWorld;
    delete solver;
    delete collisionConfiguration;
    delete dispatcher;
    delete broadphase;
    NSLog(@"Ending bullet physics...\n");
}

-(void) addRigidBody:(btRigidBody*) body
{
    _dynamicsWorld->addRigidBody( body );
}

-(void) addCollisionObject:(btCollisionObject*) obj
{
    _dynamicsWorld->addCollisionObject( obj );
}

-(void) removeRigidBody:(btRigidBody*) body
{
    _dynamicsWorld->removeRigidBody( body );
}

-(void) removeCollisionObject:(btCollisionObject*) obj
{
    _dynamicsWorld->removeCollisionObject( obj );
}

-(void) update:(float) elapsedTime
{
    _dynamicsWorld->stepSimulation( elapsedTime, 10 );
}


@end
