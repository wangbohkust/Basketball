//
//  GameViewController.swift
//  Basketball
//
//  Created by wangbo on 1/17/15.
//  Copyright (c) 2015 wangbo. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit

class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {

    // set the scene to be private by underline
    var _scene:SCNScene!
    // camera node that you view things
    var _cameraNode:SCNNode!
    // node to handle camera orientation
    var _cameraHandle:SCNNode!
    // node of camera orientation
    var _cameraOrientation:SCNNode!
    // used for camera transform, 4*4 matrix
    var _cameraHandleTranforms = [SCNMatrix4](count:10, repeatedValue:SCNMatrix4(m11: 0.0, m12: 0.0, m13: 0.0, m14: 0.0, m21: 0.0, m22: 0.0, m23: 0.0, m24: 0.0, m31: 0.0, m32: 0.0, m33: 0.0, m34: 0.0, m41: 0.0, m42: 0.0, m43: 0.0, m44: 0.0))
    var _ambientLightNode:SCNNode!
    var _spotLightNode:SCNNode!
    var _spotLightParentNode:SCNNode!
    var _floorNode:SCNNode!
    var _rollingBall:SCNNode!
    let BALL_RADIUS = CGFloat(15)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up the EVERYTHING
        setup()
    }
    
    func setup() {
        //set up view    ps: 3d view is scnview, 2d is skview
        let sceneView = view as SCNView
        sceneView.backgroundColor = SKColor.blackColor()
        
        // set up scene
        setupScene()
        
        //connect scene with view
        sceneView.scene = _scene
        
        // scenekit inner bug here, so object-c bridge is needed here
        let bridge = PhysicsWorldBridge()
        bridge.physicsWorldSpeed(sceneView.scene, withSpeed: 2.0) // no effect
        bridge.physicsGravity(sceneView.scene, withGravity: SCNVector3Make(0, -4000, 0)) // the gravity direction
        
        // this view will get all the method called back, delegate itself
        sceneView.delegate = self
        sceneView.jitteringEnabled = true
        sceneView.pointOfView = _cameraNode
        
        /*
        // build 2d layout beyong current 3d layou
        var overlay = SpriteKitOverlayScene
        sceneView.overlaySKScene = overlay*/
        
        // add gesture recognizer container
        //add sceneview's recognizer to it
        //add a tap gesture recognizer, selector is used to call fucntion
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("handleTap"))
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: Selector("handleRotate"))
        var gestureRecognizers = NSMutableArray()
        gestureRecognizers.addObject(tapGesture)
        gestureRecognizers.addObject(rotateGesture)
        gestureRecognizers.addObjectsFromArray(gestureRecognizers)
        sceneView.gestureRecognizers = gestureRecognizers
    }
 
    func handleTap(){
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(1.0)
        SCNTransaction.setCompletionBlock(){
            println("done")
        }
        //when tap the screen move forward 100, animation keep 1 second
        _cameraNode.position.z -= 100
        SCNTransaction.commit()
    }
    
    func setupScene(){
        _scene = SCNScene()
        setupEnvironment()
        setupSceneElements()
        setupIntial()
    }
    
    func setupEnvironment(){
        // create main camera
        _cameraNode = SCNNode()
        _cameraNode.position = SCNVector3Make(0, 0, 120)
        
        //create a node to manipulate camera orientation
        _cameraHandle = SCNNode()
        _cameraHandle.position = SCNVector3Make(0, 60, 0)
        
        //camera orientation
        _cameraOrientation = SCNNode()
        
        _scene.rootNode.addChildNode(_cameraHandle)
        _cameraHandle.addChildNode(_cameraOrientation)
        _cameraOrientation.addChildNode(_cameraNode)
        
        _cameraNode.camera = SCNCamera()
        // camera depth level
        _cameraNode.camera?.zFar = 2000
        
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone {
            _cameraNode.camera?.yFov = 55
        } else {
            _cameraNode.camera?.xFov = 75
        }
        
        _cameraHandleTranforms.insert(_cameraNode.transform, atIndex: 0)
        
        let position = SCNVector3Make(200, 0, 1000)
        
        _cameraNode.position = SCNVector3Make(200, -20, position.z+150)
        // the downwards degress of view
        _cameraNode.eulerAngles = SCNVector3Make(CFloat(-M_PI_2)*0.06, 0, 0)

        //add an ambient light, the light surround the spot light
        _ambientLightNode = SCNNode()
        _ambientLightNode.light = SCNLight()
        _ambientLightNode.light?.type = SCNLightTypeAmbient
        _ambientLightNode.light?.color = SKColor(white: 0.3, alpha: 1.0)
        _scene.rootNode.addChildNode(_ambientLightNode)
        
        //add a spot light to the scene
        _spotLightParentNode = SCNNode()
        _spotLightParentNode.position = SCNVector3Make(0, 90, 20)
        _spotLightNode = SCNNode()
        // node's orientaion
        _spotLightNode.rotation = SCNVector4Make(1, 0, 0, CFloat(-M_PI_4))
        _spotLightNode.light = SCNLight()
        _spotLightNode.light?.type = SCNLightTypeSpot
        _spotLightNode.light?.color = SKColor(white: 1.0, alpha: 1.0)
        //bulb shadow and shadow valid distance
        _spotLightNode.light?.castsShadow = true
        _spotLightNode.light?.shadowColor = SKColor(white: 0, alpha: 0.5)
        _spotLightNode.light?.zNear = 30
        _spotLightNode.light?.zFar = 800
        _spotLightNode.light?.shadowRadius = 1.0
        _spotLightNode.light?.spotInnerAngle = 15
        _spotLightNode.light?.spotOuterAngle = 70
        _cameraNode.addChildNode(_spotLightParentNode)
        _spotLightParentNode.addChildNode(_spotLightNode)
        
        //floor
        var floor = SCNFloor()
        floor.reflectionFalloffEnd = 0
        floor.reflectivity = 0
        _floorNode = SCNNode()
        _floorNode.geometry = floor
        _floorNode.geometry?.firstMaterial?.diffuse.contents = "wood.png"
        _floorNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        // infinite floor by limit floor image
        _floorNode.geometry?.firstMaterial?.diffuse.wrapS = SCNWrapMode.Repeat
        _floorNode.geometry?.firstMaterial?.diffuse.wrapT = SCNWrapMode.Repeat
        _floorNode.geometry?.firstMaterial?.diffuse.mipFilter = SCNFilterMode.Linear
        _floorNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Static, shape: nil)
        _floorNode.physicsBody?.restitution = 1.0
        _scene.rootNode.addChildNode(_floorNode)

    }
    
    func setupSceneElements(){
        let wallGeometry = SCNPlane(width: 800, height: 200)
        //diffuse is color
        wallGeometry.firstMaterial?.diffuse.contents = "wallPaper.png"
        wallGeometry.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Mult(SCNMatrix4MakeScale(8.0, 2.0, 1.0), SCNMatrix4MakeRotation(CFloat(M_PI_4), 0.0, 0.0, 1.0))
        wallGeometry.firstMaterial?.diffuse.wrapS = SCNWrapMode.Repeat
        wallGeometry.firstMaterial?.diffuse.wrapT = SCNWrapMode.Repeat
        wallGeometry.firstMaterial?.doubleSided = false
        wallGeometry.firstMaterial?.locksAmbientWithDiffuse = true
        
        let wallWithBaseboardNode = SCNNode(geometry: wallGeometry)
        wallWithBaseboardNode.position = SCNVector3Make(200, 100, 900)
        wallWithBaseboardNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Static, shape: nil)
        wallWithBaseboardNode.physicsBody?.restitution = 1.0
        wallWithBaseboardNode.castsShadow = false
        
        let baseBoardNode = SCNNode(geometry: SCNPlane(width: 800, height: 8))
        baseBoardNode.geometry?.firstMaterial?.diffuse.contents = "baseboard.jpg"
        baseBoardNode.geometry?.firstMaterial?.diffuse.wrapS = SCNWrapMode.Repeat
        baseBoardNode.geometry?.firstMaterial?.doubleSided = false
        baseBoardNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        baseBoardNode.position = SCNVector3Make(0, -wallWithBaseboardNode.position.y + 4, 0.5)
        baseBoardNode.castsShadow = false
        
        wallWithBaseboardNode.addChildNode(baseBoardNode)
        _scene.rootNode.addChildNode(wallWithBaseboardNode)

    }
    
    func setupIntial(){
        //initial dark lighting
        _ambientLightNode.light?.color = SKColor.blackColor()
        _spotLightNode.light?.color = SKColor.blackColor()
        _spotLightNode.position = SCNVector3Make(50, 90, -50)
        _spotLightNode.eulerAngles = SCNVector3Make(CFloat(-M_PI_2)*0.75, CFloat(M_PI_4)*0.5, 0)
        
        _rollingBall = SCNNode(geometry: SCNSphere(radius: BALL_RADIUS))
        _rollingBall.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "balldimpled")
        _rollingBall.geometry?.firstMaterial?.emission.contents = UIImage(named: "balldimpled")
        _rollingBall.geometry?.firstMaterial?.emission.intensity = 0
        _rollingBall.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Dynamic, shape: nil)
        _rollingBall.physicsBody?.restitution = 0.6
        _rollingBall.physicsBody?.angularVelocity = SCNVector4(x: 1, y: 1, z: 1, w: 1)
        
        let position = SCNVector3Make(200, 0, 950)
        _rollingBall.position = position
        _rollingBall.position.y += CFloat(BALL_RADIUS * 8)
        _scene.rootNode.addChildNode(_rollingBall)
        
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(1.0)
        SCNTransaction.setCompletionBlock() {
            SCNTransaction.begin()
            SCNTransaction.setAnimationDuration(2.5)
            self._spotLightNode.light?.color = SKColor(white: 1, alpha: 1)
            SCNTransaction.commit()
        }
        _spotLightNode.light?.color = SKColor(white: 0.001, alpha: 1)
        SCNTransaction.commit()
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
