/*

//
//  ModuleBViewController.swift
//  Lab3_MobileApps
//
//  Created by Keaton Harvey on 10/21/24.
//

import Foundation

class ModuleBViewController: ViewController {
    
}


*/


// File: ModuleBViewController.swift
import UIKit
import SpriteKit
import CoreMotion

class ModuleBViewController: UIViewController, SKPhysicsContactDelegate {
    
    // Scene and motion manager
    var skView: SKView!
    var scene: SKScene!
    let motionManager = CMMotionManager()
    
    // Physics categories
    struct PhysicsCategory {
        static let player: UInt32 = 0x1 << 0
        static let enemy: UInt32 = 0x1 << 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the SKView and Scene
        skView = SKView(frame: self.view.frame)
        scene = SKScene(size: self.view.frame.size)
        scene.physicsWorld.contactDelegate = self
        scene.backgroundColor = .white
        self.view.addSubview(skView)
        
        skView.presentScene(scene)
        
        // Create game nodes
        createPlayerNode()
        createEnemyNode()
        
        // Setup CoreMotion manager
        startMotionUpdates()
    }
    
    // Create the player node
    func createPlayerNode() {
        let playerNode = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))
        playerNode.position = CGPoint(x: scene.size.width / 2, y: 100)
        playerNode.physicsBody = SKPhysicsBody(rectangleOf: playerNode.size)
        playerNode.physicsBody?.categoryBitMask = PhysicsCategory.player
        playerNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        playerNode.physicsBody?.isDynamic = true
        playerNode.name = "player"
        scene.addChild(playerNode)
    }
    
    // Create an enemy node
    func createEnemyNode() {
        let enemyNode = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        enemyNode.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 100)
        enemyNode.physicsBody = SKPhysicsBody(rectangleOf: enemyNode.size)
        enemyNode.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        enemyNode.physicsBody?.contactTestBitMask = PhysicsCategory.player
        enemyNode.physicsBody?.isDynamic = true
        enemyNode.name = "enemy"
        scene.addChild(enemyNode)
    }
    
    // Start receiving motion updates from CoreMotion
    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] (data, error) in
                guard let data = data else { return }
                self?.updatePlayerPosition(with: data)
            }
        }
    }
    
    // Update player node position based on accelerometer data
    func updatePlayerPosition(with data: CMAccelerometerData) {
        if let playerNode = scene.childNode(withName: "player") as? SKSpriteNode {
            let newX = CGFloat(data.acceleration.x) * 500
            let newY = CGFloat(data.acceleration.y) * 500
            playerNode.position.x += newX
            playerNode.position.y += newY
            
            // Ensure player does not move out of screen bounds
            playerNode.position.x = max(playerNode.size.width / 2, min(playerNode.position.x, scene.size.width - playerNode.size.width / 2))
            playerNode.position.y = max(playerNode.size.height / 2, min(playerNode.position.y, scene.size.height - playerNode.size.height / 2))
        }
    }
    
    // Handle collision detection
    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        // Check if player has collided with an enemy
        if (contact.bodyA.categoryBitMask == PhysicsCategory.player && contact.bodyB.categoryBitMask == PhysicsCategory.enemy) ||
            (contact.bodyB.categoryBitMask == PhysicsCategory.player && contact.bodyA.categoryBitMask == PhysicsCategory.enemy) {
            print("Collision Detected!")
            // Handle collision logic (e.g., end the game or reduce health)
        }
    }
}
