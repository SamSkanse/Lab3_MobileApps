//
//  GameScene.swift
//  AsteroidAvoidanceGame
//
//  Created by Your Name on Date.
//

import UIKit
import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Motion Property
    let motionManager = CMMotionManager()
    
    // MARK: - Spaceship and Asteroid Properties
    let spaceship = SKSpriteNode(imageNamed: "Spaceship")
    var livesLabel = SKLabelNode(fontNamed: "Chalkduster")
    var timerLabel = SKLabelNode(fontNamed: "Chalkduster")
    var highScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    var lives: Int = 1
    var stepsYesterday: Int = 0 // This should be set before presenting the scene
    var survivalTime: TimeInterval = 0
    var startTime: TimeInterval = 0
    var highScore: TimeInterval = 0
    
    // Categories for collision detection
    let spaceshipCategory: UInt32 = 0x1 << 0
    let asteroidCategory: UInt32 = 0x1 << 1
    
    // Safe area insets
    var safeAreaInsets = UIEdgeInsets.zero
    
    // MARK: - View Hierarchy Functions
    override func didMove(to view: SKView) {
        // Delegate for contact detection
        physicsWorld.contactDelegate = self
        
        backgroundColor = SKColor.black
        
        // Get safe area insets
        if let view = self.view {
            safeAreaInsets = view.safeAreaInsets
        }
        
        // Start motion updates
        startMotionUpdates()
        
        // Set up spaceship
        setupSpaceship()
        
        // Set up labels
        setupLabels()
        
        // Adjust for safe area
        adjustForSafeArea()
        
        // Start dynamic asteroid generation
        scheduleNextAsteroidSpawn()
        
        // Calculate lives based on steps
        calculateLivesBasedOnSteps()
        
        // Load high score
        loadHighScore()
        
        // Start survival timer
        startTime = CACurrentMediaTime()
    }
    
    // MARK: - Setup Functions
    func setupSpaceship() {
        spaceship.size = CGSize(width: size.width * 0.1, height: size.height * 0.1)
        spaceship.position = CGPoint(x: size.width / 2, y: size.height * 0.1 + safeAreaInsets.bottom)

        spaceship.physicsBody = SKPhysicsBody(rectangleOf: spaceship.size)
        spaceship.physicsBody?.isDynamic = true
        spaceship.physicsBody?.affectedByGravity = false
        spaceship.physicsBody?.categoryBitMask = spaceshipCategory
        spaceship.physicsBody?.contactTestBitMask = asteroidCategory
        spaceship.physicsBody?.collisionBitMask = 0

        addChild(spaceship)
    }

    func setupLabels() {
        // Lives Label
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontSize = 20
        livesLabel.fontColor = SKColor.white
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.zPosition = 1
        addChild(livesLabel)

        // Timer Label
        timerLabel.text = "Time: 0.0s"
        timerLabel.fontSize = 20
        timerLabel.fontColor = SKColor.white
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.zPosition = 1
        addChild(timerLabel)

        // High Score Label
        highScoreLabel.text = "High Score: \(String(format: "%.1f", highScore))s"
        highScoreLabel.fontSize = 20
        highScoreLabel.fontColor = SKColor.white
        highScoreLabel.horizontalAlignmentMode = .right
        highScoreLabel.zPosition = 1
        addChild(highScoreLabel)
    }

    func adjustForSafeArea() {
        // Define the vertical position for the labels
        let labelsYPosition = frame.maxY - safeAreaInsets.top - 150 // Adjust this value to move labels lower

        // Adjust labels' positions
        livesLabel.position = CGPoint(x: frame.minX + safeAreaInsets.left + 20, y: labelsYPosition)
        timerLabel.position = CGPoint(x: frame.midX, y: labelsYPosition-80)
        highScoreLabel.position = CGPoint(x: frame.maxX - safeAreaInsets.right - 20, y: labelsYPosition)
    }

    func calculateLivesBasedOnSteps() {
        // For every 2,500 steps, add 1 life
        let extraLives = stepsYesterday / 2500
        lives += extraLives
        livesLabel.text = "Lives: \(lives)"
    }

    func loadHighScore() {
        highScore = UserDefaults.standard.double(forKey: "highScore")
        highScoreLabel.text = "High Score: \(String(format: "%.1f", highScore))s"
    }

    func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: "highScore")
    }

    // MARK: - Asteroid Functions
    func scheduleNextAsteroidSpawn() {
        // Calculate the spawn delay based on survival time
        let spawnDelay = calculateSpawnDelay()
        
        let waitAction = SKAction.wait(forDuration: spawnDelay)
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnAsteroid()
            self?.scheduleNextAsteroidSpawn()
        }
        let sequence = SKAction.sequence([waitAction, spawnAction])
        run(sequence, withKey: "asteroidSpawn")
    }
    
    func calculateSpawnDelay() -> TimeInterval {
        // Define minimum and maximum spawn intervals
        let minSpawnInterval: TimeInterval = 0.5  // Minimum delay between spawns
        let maxSpawnInterval: TimeInterval = 1.5  // Faster initial spawn rate

        // Define how quickly the spawn rate should increase
        let timeToReachMinInterval: TimeInterval = 30.0  // Time in seconds to reach minimum interval

        // Calculate the proportion of time elapsed
        let timeElapsed = survivalTime
        let proportion = min(timeElapsed / timeToReachMinInterval, 1.0)  // Clamp between 0 and 1

        // Calculate the current spawn interval
        let currentSpawnInterval = maxSpawnInterval - (proportion * (maxSpawnInterval - minSpawnInterval))

        return currentSpawnInterval
    }
    
    func spawnAsteroid() {
        let asteroid = SKSpriteNode(imageNamed: "Asteroid")
        asteroid.size = CGSize(width: size.width * 0.1, height: size.height * 0.1)

        let minX = safeAreaInsets.left + asteroid.size.width / 2
        let maxX = size.width - safeAreaInsets.right - asteroid.size.width / 2
        let randomX = CGFloat.random(in: minX...maxX)
        asteroid.position = CGPoint(x: randomX, y: size.height + asteroid.size.height)

        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.size.width / 2)
        asteroid.physicsBody?.isDynamic = true
        asteroid.physicsBody?.affectedByGravity = false
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.contactTestBitMask = spaceshipCategory
        asteroid.physicsBody?.collisionBitMask = 0

        addChild(asteroid)

        // Adjust asteroid speed based on survival time
        let duration = calculateAsteroidSpeed()
        let moveAction = SKAction.move(to: CGPoint(x: randomX, y: -asteroid.size.height), duration: duration)
        let removeAction = SKAction.removeFromParent()
        asteroid.run(SKAction.sequence([moveAction, removeAction]))
    }

    func calculateAsteroidSpeed() -> TimeInterval {
        // Define minimum and maximum durations for asteroid movement
        let minDuration: TimeInterval = 1.5  // Faster asteroids
        let maxDuration: TimeInterval = 4.0  // Slower asteroids at the start

        // Define how quickly the asteroid speed increases
        let timeToReachMinDuration: TimeInterval = 60.0  // Time in seconds to reach minimum duration

        // Calculate the proportion of time elapsed
        let timeElapsed = survivalTime
        let proportion = min(timeElapsed / timeToReachMinDuration, 1.0)  // Clamp between 0 and 1

        // Calculate the current duration
        let currentDuration = maxDuration - (proportion * (maxDuration - minDuration))

        return currentDuration
    }

    // MARK: - Collision Handling
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        if (firstBody.categoryBitMask == spaceshipCategory && secondBody.categoryBitMask == asteroidCategory) ||
            (firstBody.categoryBitMask == asteroidCategory && secondBody.categoryBitMask == spaceshipCategory) {
            // Handle collision
            handleCollision()
        }
    }

    func handleCollision() {
        lives -= 1
        livesLabel.text = "Lives: \(lives)"

        if lives <= 0 {
            gameOver()
        }
    }

    func gameOver() {
        // Stop the game
        isPaused = true

        // Remove asteroid spawn action
        removeAction(forKey: "asteroidSpawn")

        // Check if new high score
        if survivalTime > highScore {
            highScore = survivalTime
            saveHighScore()
            highScoreLabel.text = "High Score: \(String(format: "%.1f", highScore))s"
        }

        // Show Game Over message
        let gameOverLabel = SKLabelNode(fontNamed: "Chalkduster")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.zPosition = 2
        addChild(gameOverLabel)

        // Optionally, add a restart button or transition to a Game Over scene
    }

    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        // Calculate survival time
        survivalTime = currentTime - startTime
        timerLabel.text = String(format: "Time: %.1fs", survivalTime)

        // Update spaceship position based on accelerometer
        updateSpaceshipPosition()
    }

    // MARK: - Motion Functions
    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.02 // 50 Hz
            motionManager.startAccelerometerUpdates()
        }
    }

    func updateSpaceshipPosition() {
        if let accelerometerData = motionManager.accelerometerData {
            let acceleration = accelerometerData.acceleration
            let xMovement = CGFloat(acceleration.x) * 50
            let yMovement = CGFloat(acceleration.y) * 50

            let newX = spaceship.position.x + xMovement
            let newY = spaceship.position.y + yMovement

            let maxX = size.width - spaceship.size.width / 2 - safeAreaInsets.right
            let minX = spaceship.size.width / 2 + safeAreaInsets.left
            let maxY = size.height - spaceship.size.height / 2 - safeAreaInsets.top
            let minY = spaceship.size.height / 2 + safeAreaInsets.bottom

            spaceship.position.x = max(minX, min(maxX, newX))
            spaceship.position.y = max(minY, min(maxY, newY))
        }
    }

    // MARK: - Utility Functions
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UInt32.max))
    }

    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
}
