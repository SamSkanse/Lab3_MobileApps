//
//  GameViewController.swift
//  Lab3_MobileApps
//
//  Created by Keaton Harvey on 10/21/24.
//

import UIKit
import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Motion Property
    let motionManager = CMMotionManager()
    let userDefaults = UserDefaults.standard // Added UserDefaults access
    
    // MARK: - Spaceship and Asteroid Properties
    let spaceship = SKSpriteNode(imageNamed: "Spaceship")
    var livesLabel = SKLabelNode(fontNamed: "Chalkduster")
    var timerLabel = SKLabelNode(fontNamed: "Chalkduster")
    var highScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    var lives: Int = 1
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
        
        // Calculate lives based on steps
        calculateLivesBasedOnSteps()
        
        // Load high score
        loadHighScore()
        
        // Start survival timer
        startTime = CACurrentMediaTime()
        
        // Start dynamic asteroid generation
        scheduleNextAsteroidSpawn()
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
        timerLabel.position = CGPoint(x: frame.midX, y: labelsYPosition - 80)
        highScoreLabel.position = CGPoint(x: frame.maxX - safeAreaInsets.right - 20, y: labelsYPosition)
    }

    func calculateLivesBasedOnSteps() {
        lives = 1 // Start with 1 life

        let numStepsGoal = userDefaults.float(forKey: "numStepsGoal")
        let stepsYesterday = userDefaults.integer(forKey: "stepsYesterday")

        if numStepsGoal > 0 && Float(stepsYesterday) >= numStepsGoal {
            let extraLives = Int(floor(numStepsGoal / 2500.0))
            lives += extraLives
        }

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
        let minSpawnInterval: TimeInterval = 0.1  // Minimum delay between spawns
        let maxSpawnInterval: TimeInterval = 1.5 // slower initial spawn rate

        // Define how quickly the spawn rate should increase
        let timeToReachMinInterval: TimeInterval = 120.0  // Time in seconds to reach minimum interval

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
        let minDuration: TimeInterval = 0.8 // Faster asteroids
        let maxDuration: TimeInterval = 6.0  // Slower asteroids at the start

        // Define how quickly the asteroid speed increases
        let timeToReachMinDuration: TimeInterval = 120.0  // Time in seconds to reach minimum duration

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

        if lives > 0 {
            // Flash the lives label red for 2 seconds
            flashLivesLabel()
        }

        if lives <= 0 {
            gameOver()
        }
    }
    
    func flashLivesLabel() {
        // Change the font color to red
        let turnRedAction = SKAction.run { [weak self] in
            self?.livesLabel.fontColor = SKColor.red
        }

        // Wait for 2 seconds
        let waitAction = SKAction.wait(forDuration: 2.0)

        // Change the font color back to white
        let turnWhiteAction = SKAction.run { [weak self] in
            self?.livesLabel.fontColor = SKColor.white
        }

        // Create the sequence
        let sequence = SKAction.sequence([turnRedAction, waitAction, turnWhiteAction])

        // Run the action on the livesLabel
        livesLabel.run(sequence)
    }

    func gameOver() {
        // Stop the game
        isPaused = true

        // Remove asteroid spawn action
        removeAction(forKey: "asteroidSpawn")

        var isNewHighScore = false

        // Check if new high score
        if survivalTime > highScore {
            highScore = survivalTime
            saveHighScore()
            highScoreLabel.text = "High Score: \(String(format: "%.1f", highScore))s"
            isNewHighScore = true
        }

        // Show Game Over message
        let gameOverLabel = SKLabelNode(fontNamed: "Chalkduster")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.zPosition = 2
        addChild(gameOverLabel)

        // Show New High Score message if applicable
        if isNewHighScore {
            let newHighScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
            newHighScoreLabel.text = "New High Score!"
            newHighScoreLabel.fontSize = 40
            newHighScoreLabel.fontColor = SKColor.yellow
            newHighScoreLabel.position = CGPoint(x: size.width / 2, y: gameOverLabel.position.y + 60)
            newHighScoreLabel.zPosition = 2
            addChild(newHighScoreLabel)
        }

        // Add Reset High Score button
        let resetHighScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        resetHighScoreLabel.text = "Reset High Score"
        resetHighScoreLabel.fontSize = 30
        resetHighScoreLabel.fontColor = SKColor.white
        resetHighScoreLabel.position = CGPoint(x: size.width / 2, y: gameOverLabel.position.y - 70)
        resetHighScoreLabel.zPosition = 2
        resetHighScoreLabel.name = "resetHighScoreButton" // Assign a name to identify it in touches
        addChild(resetHighScoreLabel)

        // Add Restart button
        let restartLabel = SKLabelNode(fontNamed: "Chalkduster")
        restartLabel.text = "Restart"
        restartLabel.fontSize = 30
        restartLabel.fontColor = SKColor.white
        restartLabel.position = CGPoint(x: size.width / 2, y: gameOverLabel.position.y - 120)
        restartLabel.zPosition = 2
        restartLabel.name = "restartButton"
        addChild(restartLabel)
    }

    // MARK: - Touch Handling
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)

        for node in nodesAtPoint {
            if node.name == "resetHighScoreButton" {
                resetHighScore()
            } else if node.name == "restartButton" {
                restartGame()
            }
        }
    }

    func resetHighScore() {
        // Reset the high score
        highScore = 0
        saveHighScore()
        highScoreLabel.text = "High Score: 0.0s"

        // Provide feedback to the user
        let resetConfirmationLabel = SKLabelNode(fontNamed: "Chalkduster")
        resetConfirmationLabel.text = "High Score Reset!"
        resetConfirmationLabel.fontSize = 30
        resetConfirmationLabel.fontColor = SKColor.yellow
        resetConfirmationLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 160)
        resetConfirmationLabel.zPosition = 2
        addChild(resetConfirmationLabel)

        // Remove the confirmation message after a delay
        let waitAction = SKAction.wait(forDuration: 2.0)
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.0)
        let removeAction = SKAction.removeFromParent()
        resetConfirmationLabel.run(SKAction.sequence([waitAction, fadeOutAction, removeAction]))
    }

    func restartGame() {
        // Remove all children and actions
        removeAllChildren()
        removeAllActions()

        // Reset variables
        survivalTime = 0
        startTime = CACurrentMediaTime()

        // Re-add the spaceship
        setupSpaceship()

        // Re-add labels
        setupLabels()
        adjustForSafeArea()

        // Recalculate lives based on steps
        calculateLivesBasedOnSteps()

        // Start motion updates
        startMotionUpdates()

        // Start asteroid generation
        scheduleNextAsteroidSpawn()

        // Resume the game
        isPaused = false
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
