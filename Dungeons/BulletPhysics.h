//
//  BulletPhysics.h
//  BulletTest
//
//  Created by Borna Noureddin on 2015-03-20.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "btBulletDynamicsCommon.h"

@interface BulletPhysics: NSObject

@property (nonatomic) btDiscreteDynamicsWorld* dynamicsWorld;

-(void) update:(float) elapsedTime;

-(void) addRigidBody:(btRigidBody*) body;

-(void) addCollisionObject:(btCollisionObject*) obj;

-(void) removeRigidBody:(btRigidBody*) body;

-(void) removeCollisionObject:(btCollisionObject*) obj;

@end
