//
//  PhysicsWorldBridge.m
//  Basketball
//
//  Created by wangbo on 1/17/15.
//  Copyright (c) 2015 wangbo. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "PhysicsWorldBridge.h"

@implementation PhysicsWorldBridge

- (id) init
{
    if (self = [super init])
    {
    }
    return self;
}

- (void) physicsWorldSpeed:(SCNScene *) scene withSpeed:(float) speed
{
    scene.physicsWorld.speed = speed;
}

- (void) physicsGravity:(SCNScene *) scene withGravity:(SCNVector3) gravity
{
    scene.physicsWorld.gravity = gravity;
}

@end
