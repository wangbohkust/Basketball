//
//  PhysicsWorldBridge.h
//  Basketball
//
//  Created by wangbo on 1/17/15.
//  Copyright (c) 2015 wangbo. All rights reserved.
//

#import <SceneKit/SceneKit.h>

@interface PhysicsWorldBridge : NSObject

- (void) physicsWorldSpeed:(SCNScene *) scene withSpeed:(float) speed;
- (void) physicsGravity:(SCNScene *) scene withGravity:(SCNVector3) gravity;

@end