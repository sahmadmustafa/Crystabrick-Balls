

import SwiftUI
import Combine

// MARK: - Game Constants
struct GameConstants {
    static let paddleWidth: CGFloat = 100
    static let paddleHeight: CGFloat = 14
    static let ballSize: CGFloat = 18
    static let brickRows: Int = 6
    static let brickColumns: Int = 9
    static let brickWidth: CGFloat = 36
    static let brickHeight: CGFloat = 20
    static let brickSpacing: CGFloat = 3
    static let initialBallSpeed: CGFloat = 6
    static let maxBallSpeed: CGFloat = 18
    static let speedIncreaseFactor: CGFloat = 1.12
    static let powerUpSize: CGFloat = 24
    static let powerUpFallSpeed: CGFloat = 3
}

// MARK: - Brick Model
struct Brick: Identifiable {
    let id = UUID()
    var color: Color
    var position: CGRect
    var health: Int
    var isVisible: Bool = true
    var specialEffect: SpecialEffect?
    var isIndestructible: Bool = false
}

enum SpecialEffect: CaseIterable {
    case extraBall
    case widenPaddle
    case laserPaddle
    case slowBall
    case scoreMultiplier
    case bomb
}

// MARK: - PowerUp Model
struct PowerUp: Identifiable {
    let id = UUID()
    var type: SpecialEffect
    var position: CGPoint
    var isActive: Bool = true
}

// MARK: - Particle Effect
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var scale: CGFloat
    var opacity: Double
    var velocity: CGSize
    var lifetime: Double
    var text: String?
    
    // Optional: Add this if you need to reference the font size
    var fontSize: CGFloat {
        scale * 12
    }
}

// MARK: - Game ViewModel
class GameViewModel: ObservableObject {
    @Published var paddlePosition: CGRect = .zero
    @Published var ballPosition: CGRect = .zero
    @Published var balls: [CGRect] = []
    @Published var bricks: [Brick] = []
    @Published var ballVelocities: [CGSize] = []
    @Published var powerUps: [PowerUp] = []
    @Published var particles: [Particle] = []
    @Published var score: Int = 0
    @Published var highScore: Int = 0
    @Published var gameOver: Bool = false
    @Published var level: Int = 1
    @Published var showInstructions: Bool = true
    @Published var totalBricksBroken: Int = 0
    @Published var comboCounter: Int = 0
    @Published var lastBrickBreakTime: Date = Date()
    @Published var isPaddleWide: Bool = false
    @Published var isLaserActive: Bool = false
    @Published var lasers: [CGRect] = []
    @Published var multiplier: Int = 1
    
    private var gameArea: CGRect = .zero
    private var timer: AnyCancellable?
    private var lastUpdateTime: Date?
    private var paddleOriginalWidth: CGFloat = GameConstants.paddleWidth
    private var laserTimer: AnyCancellable?
    private var powerUpTimers: [UUID: AnyCancellable] = [:]
    
    init() {
        loadHighScore()
        paddleOriginalWidth = GameConstants.paddleWidth
    }
    
    func startGame() {
        showInstructions = false
        gameOver = false
        resetGame()
        resetBall()
        ballVelocities = [CGSize(width: 0, height: GameConstants.initialBallSpeed)]
        lastUpdateTime = Date()
        
        timer = Timer.publish(every: 0.016, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateGame()
            }
    }
    
    func resetGame() {
        score = 0
        totalBricksBroken = 0
        level = 1
        multiplier = 1
        comboCounter = 0
        balls = []
        ballVelocities = []
        powerUps = []
        lasers = []
        isPaddleWide = false
        isLaserActive = false
        generateBricks()
        resetBall()
    }
    
    func resetBall() {
        let ballRect = CGRect(
            x: gameArea.midX - GameConstants.ballSize / 2,
            y: gameArea.maxY - GameConstants.paddleHeight - GameConstants.ballSize - 30,
            width: GameConstants.ballSize,
            height: GameConstants.ballSize
        )
        balls = [ballRect]
        ballVelocities = [CGSize(width: 0, height: GameConstants.initialBallSpeed)]
    }
    
    func updateGame() {
        guard !gameOver, let lastTime = lastUpdateTime else { return }
        let currentTime = Date()
        let deltaTime = currentTime.timeIntervalSince(lastTime)
        lastUpdateTime = currentTime
        
        // Update ball positions
        var newBalls = balls
        for (index, ball) in balls.enumerated() {
            var newBallPosition = ball
            newBallPosition.origin.x += ballVelocities[index].width * CGFloat(deltaTime) * 60
            newBallPosition.origin.y += ballVelocities[index].height * CGFloat(deltaTime) * 60
            
            // Wall collisions
            if newBallPosition.minX <= gameArea.minX {
                newBallPosition.origin.x = gameArea.minX
                ballVelocities[index].width *= -1
                createImpactParticles(at: CGPoint(x: newBallPosition.minX, y: newBallPosition.midY), color: .white)
            }
            
            if newBallPosition.maxX >= gameArea.maxX {
                newBallPosition.origin.x = gameArea.maxX - GameConstants.ballSize
                ballVelocities[index].width *= -1
                createImpactParticles(at: CGPoint(x: newBallPosition.maxX, y: newBallPosition.midY), color: .white)
            }
            
            if newBallPosition.minY <= gameArea.minY {
                newBallPosition.origin.y = gameArea.minY
                ballVelocities[index].height *= -1
                createImpactParticles(at: CGPoint(x: newBallPosition.midX, y: newBallPosition.minY), color: .white)
            }
            
            // Paddle collision
            if newBallPosition.intersects(paddlePosition) {
                newBallPosition.origin.y = paddlePosition.minY - GameConstants.ballSize
                
                // Calculate bounce angle based on where ball hits paddle
                let hitPosition = (newBallPosition.midX - paddlePosition.minX) / paddlePosition.width
                let angle = (hitPosition - 0.5) * 2 // -1 to 1
                
                let speed = min(
                    GameConstants.initialBallSpeed * pow(GameConstants.speedIncreaseFactor, CGFloat(level - 1)),
                    GameConstants.maxBallSpeed
                )
                
                ballVelocities[index] = CGSize(
                    width: angle * speed * 1.5,
                    height: -speed
                )
                
                createImpactParticles(at: CGPoint(x: newBallPosition.midX, y: newBallPosition.maxY), color: .blue)
            }
            
            // Brick collisions
            for brickIndex in bricks.indices where bricks[brickIndex].isVisible {
                if newBallPosition.intersects(bricks[brickIndex].position) {
                    handleBrickCollision(brickIndex: brickIndex, ballIndex: index, newBallPosition: &newBallPosition)
                    break // Only handle one collision per frame
                }
            }
            
            newBalls[index] = newBallPosition
            
            // Game over check
            if newBallPosition.minY > gameArea.maxY {
                if balls.count > 1 {
                    // Remove this ball but continue with others
                    newBalls.remove(at: index)
                    ballVelocities.remove(at: index)
                } else {
                    gameOver = true
                    timer?.cancel()
                    return
                }
            }
        }
        
        balls = newBalls
        
        // Update power-ups
        var newPowerUps = powerUps
        for (index, powerUp) in powerUps.enumerated() where powerUp.isActive {
            var updatedPowerUp = powerUp
            updatedPowerUp.position.y += GameConstants.powerUpFallSpeed
            
            // Paddle collision with power-up
            let powerUpRect = CGRect(x: updatedPowerUp.position.x - GameConstants.powerUpSize/2,
                                    y: updatedPowerUp.position.y - GameConstants.powerUpSize/2,
                                    width: GameConstants.powerUpSize,
                                    height: GameConstants.powerUpSize)
            
            if powerUpRect.intersects(paddlePosition) {
                activatePowerUp(powerUp.type)
                updatedPowerUp.isActive = false
                createParticleExplosion(at: updatedPowerUp.position, color: .yellow)
            }
            
            // Remove power-ups that fall off screen
            if updatedPowerUp.position.y > gameArea.maxY {
                updatedPowerUp.isActive = false
            }
            
            newPowerUps[index] = updatedPowerUp
        }
        
        powerUps = newPowerUps.filter { $0.isActive }
        
        // Update particles
        updateParticles(deltaTime: deltaTime)
        
        // Update lasers if active
        if isLaserActive {
            lasers = [CGRect(x: paddlePosition.midX - 1, y: 0, width: 2, height: paddlePosition.minY)]
        } else {
            lasers = []
        }
        
        // Level complete check
        if bricks.allSatisfy({ !$0.isVisible || $0.isIndestructible }) {
            levelComplete()
        }
    }
    
    private func handleBrickCollision(brickIndex: Int, ballIndex: Int, newBallPosition: inout CGRect) {
        bricks[brickIndex].health -= 1
        
        // Combo system
        let now = Date()
        if now.timeIntervalSince(lastBrickBreakTime) < 0.5 {
            comboCounter += 1
        } else {
            comboCounter = 1
        }
        lastBrickBreakTime = now
        
        if bricks[brickIndex].health <= 0 && !bricks[brickIndex].isIndestructible {
            bricks[brickIndex].isVisible = false
            let pointsEarned = 10 * level * multiplier
            score += pointsEarned
            totalBricksBroken += 1
            
            // Create score popup
            createScorePopup(points: pointsEarned, position: bricks[brickIndex].position.origin)
            
            if score > highScore {
                highScore = score
                saveHighScore()
            }
            
            // Chance to drop power-up
            if let effect = bricks[brickIndex].specialEffect, Double.random(in: 0...1) > 0.7 {
                let powerUp = PowerUp(
                    type: effect,
                    position: CGPoint(
                        x: bricks[brickIndex].position.midX,
                        y: bricks[brickIndex].position.midY
                    )
                )
                powerUps.append(powerUp)
            }
            
            // Particle effect
            createBrickBreakParticles(position: bricks[brickIndex].position, color: bricks[brickIndex].color)
        }
        
        // Determine collision side and reverse velocity
        let brick = bricks[brickIndex].position
        let ballCenter = CGPoint(x: newBallPosition.midX, y: newBallPosition.midY)
        
        // Calculate minimum translation to exit brick
        let overlapLeft = newBallPosition.maxX - brick.minX
        let overlapRight = brick.maxX - newBallPosition.minX
        let overlapTop = newBallPosition.maxY - brick.minY
        let overlapBottom = brick.maxY - newBallPosition.minY
        
        let minOverlap = min(overlapLeft, overlapRight, overlapTop, overlapBottom)
        
        // Adjust position and velocity based on collision side
        if minOverlap == overlapLeft {
            newBallPosition.origin.x = brick.minX - GameConstants.ballSize
            ballVelocities[ballIndex].width *= -1
        } else if minOverlap == overlapRight {
            newBallPosition.origin.x = brick.maxX
            ballVelocities[ballIndex].width *= -1
        } else if minOverlap == overlapTop {
            newBallPosition.origin.y = brick.minY - GameConstants.ballSize
            ballVelocities[ballIndex].height *= -1
        } else if minOverlap == overlapBottom {
            newBallPosition.origin.y = brick.maxY
            ballVelocities[ballIndex].height *= -1
        }
        
        createImpactParticles(at: CGPoint(x: newBallPosition.midX, y: newBallPosition.midY), color: bricks[brickIndex].color)
    }
    
    private func levelComplete() {
        level += 1
        multiplier = min(multiplier + 1, 5)
        generateBricks()
        resetBall()
        
        // Reset ball velocities with new speed
        for i in 0..<ballVelocities.count {
            let speed = GameConstants.initialBallSpeed * pow(GameConstants.speedIncreaseFactor, CGFloat(level - 1))
            let direction = ballVelocities[i]
            let magnitude = sqrt(direction.width * direction.width + direction.height * direction.height)
            if magnitude > 0 {
                ballVelocities[i] = CGSize(
                    width: (direction.width / magnitude) * speed,
                    height: (direction.height / magnitude) * speed
                )
            } else {
                ballVelocities[i] = CGSize(width: 0, height: speed)
            }
        }
        
        // Celebration effect
        createLevelCompleteEffect()
    }
    
    private func activatePowerUp(_ effect: SpecialEffect) {
        switch effect {
        case .extraBall:
            addExtraBall()
        case .widenPaddle:
            widenPaddle()
        case .laserPaddle:
            activateLasers()
        case .slowBall:
            slowDownBalls()
        case .scoreMultiplier:
            increaseMultiplier()
        case .bomb:
            explodeNearbyBricks()
        }
    }
    
    private func addExtraBall() {
        guard !balls.isEmpty else { return }
        
        let newBall = balls[0]
        balls.append(newBall)
        
        // Calculate a slightly different angle
        let angle = CGFloat.random(in: -0.5...0.5)
        let speed = min(
            GameConstants.initialBallSpeed * pow(GameConstants.speedIncreaseFactor, CGFloat(level - 1)),
            GameConstants.maxBallSpeed
        )
        
        ballVelocities.append(CGSize(
            width: angle * speed * 1.5,
            height: -speed
        ))
        
        createParticleExplosion(at: CGPoint(x: newBall.midX, y: newBall.midY), color: .green)
    }
    
    private func widenPaddle() {
        if isPaddleWide { return }
        
        isPaddleWide = true
        let newWidth = paddleOriginalWidth * 1.5
        paddlePosition.size.width = newWidth
        
        // Schedule reset
        powerUpTimers[UUID()] = Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.isPaddleWide = false
                self?.paddlePosition.size.width = self?.paddleOriginalWidth ?? GameConstants.paddleWidth
            }
    }
    
    private func activateLasers() {
        if isLaserActive { return }
        
        isLaserActive = true
        
        // Schedule deactivation
        powerUpTimers[UUID()] = Timer.publish(every: 8, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.isLaserActive = false
            }
    }
    
    private func slowDownBalls() {
        for i in 0..<ballVelocities.count {
            ballVelocities[i].width *= 0.7
            ballVelocities[i].height *= 0.7
        }
        
        createParticleExplosion(at: CGPoint(x: gameArea.midX, y: gameArea.midY), color: .blue)
    }
    
    private func increaseMultiplier() {
        multiplier = min(multiplier + 1, 5)
        
        createParticleExplosion(at: CGPoint(x: gameArea.midX, y: gameArea.midY), color: .yellow)
    }
    
    private func explodeNearbyBricks() {
        let explosionRadius: CGFloat = 100
        var explodedCount = 0
        
        for index in bricks.indices where bricks[index].isVisible && !bricks[index].isIndestructible {
            let brickCenter = CGPoint(
                x: bricks[index].position.midX,
                y: bricks[index].position.midY
            )
            
            for ball in balls {
                let ballCenter = CGPoint(x: ball.midX, y: ball.midY)
                let distance = hypot(brickCenter.x - ballCenter.x, brickCenter.y - ballCenter.y)
                
                if distance < explosionRadius {
                    bricks[index].isVisible = false
                    explodedCount += 1
                    
                    // Particle effect
                    createBrickBreakParticles(position: bricks[index].position, color: bricks[index].color)
                    break
                }
            }
        }
        
        if explodedCount > 0 {
            score += explodedCount * 15 * level * multiplier
            createParticleExplosion(at: CGPoint(x: gameArea.midX, y: gameArea.midY), color: .red)
        }
    }
    
    private func generateBricks() {
        bricks.removeAll()
        
        let totalBrickWidth = CGFloat(GameConstants.brickColumns) * GameConstants.brickWidth
        let totalBrickSpacing = CGFloat(GameConstants.brickColumns - 1) * GameConstants.brickSpacing
        let startX = (gameArea.width - (totalBrickWidth + totalBrickSpacing)) / 2
        
        // Special brick patterns based on level
        let pattern = level % 5
        
        for row in 0..<GameConstants.brickRows {
            for col in 0..<GameConstants.brickColumns {
                let x = startX + CGFloat(col) * (GameConstants.brickWidth + GameConstants.brickSpacing)
                let y = gameArea.minY + 60 + CGFloat(row) * (GameConstants.brickHeight + GameConstants.brickSpacing)
                
                // Determine brick properties based on pattern
                var health = 1
                var isIndestructible = false
                var specialEffect: SpecialEffect? = nil
                
                switch pattern {
                case 0: // Standard
                    health = 1 + (row / 2)
                    if row == GameConstants.brickRows - 1 && col % 3 == 0 {
                        specialEffect = SpecialEffect.allCases.randomElement()
                    }
                case 1: // Checkerboard
                    if (row + col) % 2 == 0 {
                        health = 2
                    }
                    if row == 0 && col % 4 == 0 {
                        isIndestructible = true
                    }
                case 2: // Pyramid
                    let centerDist = abs(col - GameConstants.brickColumns / 2) + abs(row)
                    health = max(1, 3 - centerDist / 2)
                    if centerDist == 0 {
                        specialEffect = .scoreMultiplier
                    }
                case 3: // Horizontal stripes
                    if row % 2 == 0 {
                        health = 2
                    }
                    if row == 1 && col == GameConstants.brickColumns / 2 {
                        specialEffect = .extraBall
                    }
                case 4: // Vertical stripes
                    if col % 2 == 0 {
                        health = 2
                    }
                    if row == GameConstants.brickRows - 1 && col == GameConstants.brickColumns - 1 {
                        specialEffect = .bomb
                    }
                default:
                    health = 1
                }
                
                // Adjust health based on level
                health = min(health + (level / 3), 5)
                
                // Neon color scheme
                let hue = (0.6 + Double(row) / Double(GameConstants.brickRows) * 0.3).truncatingRemainder(dividingBy: 1.0)
                let saturation = 0.9
                let brightness = 0.7 + Double(col) / Double(GameConstants.brickColumns) * 0.3
                
                let brick = Brick(
                    color: Color(hue: hue, saturation: saturation, brightness: brightness),
                    position: CGRect(
                        x: x,
                        y: y,
                        width: GameConstants.brickWidth,
                        height: GameConstants.brickHeight
                    ),
                    health: health,
                    isVisible: true,
                    specialEffect: specialEffect,
                    isIndestructible: isIndestructible
                )
                bricks.append(brick)
            }
        }
    }
    
    func updateGameArea(_ rect: CGRect) {
        gameArea = rect
        paddlePosition = CGRect(
            x: rect.midX - GameConstants.paddleWidth / 2,
            y: rect.maxY - GameConstants.paddleHeight - 30,
            width: GameConstants.paddleWidth,
            height: GameConstants.paddleHeight
        )
        resetBall()
    }
    
    func movePaddle(to position: CGPoint) {
        var newX = position.x - paddlePosition.width / 2
        newX = max(gameArea.minX, min(newX, gameArea.maxX - paddlePosition.width))
        
        paddlePosition.origin.x = newX
        
        // If game hasn't started, move ball with paddle
        if ballVelocities.first == .zero, !balls.isEmpty {
            balls[0].origin.x = newX + paddlePosition.width / 2 - GameConstants.ballSize / 2
        }
    }
    
    // MARK: - Particle Effects
    
    private func createImpactParticles(at position: CGPoint, color: Color) {
        for _ in 0..<5 {
            particles.append(Particle(
                position: position,
                color: color,
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0,
                velocity: CGSize(
                    width: CGFloat.random(in: -30...30),
                    height: CGFloat.random(in: -30...30)
                ),
                lifetime: Double.random(in: 0.3...0.8)
            ))
        }
    }
    
    private func createBrickBreakParticles(position: CGRect, color: Color) {
        for _ in 0..<15 {
            particles.append(Particle(
                position: CGPoint(
                    x: position.midX + CGFloat.random(in: -position.width/2...position.width/2),
                    y: position.midY + CGFloat.random(in: -position.height/2...position.height/2)
                ),
                color: color,
                scale: CGFloat.random(in: 1.0...2.5),
                opacity: 1.0,
                velocity: CGSize(
                    width: CGFloat.random(in: -50...50),
                    height: CGFloat.random(in: -80...0)
                ),
                lifetime: Double.random(in: 0.5...1.2)
            ))
        }
    }
    
    private func createParticleExplosion(at position: CGPoint, color: Color) {
        for _ in 0..<25 {
            particles.append(Particle(
                position: position,
                color: color,
                scale: CGFloat.random(in: 0.8...2.2),
                opacity: 1.0,
                velocity: CGSize(
                    width: CGFloat.random(in: -100...100),
                    height: CGFloat.random(in: -100...100)
                ),
                lifetime: Double.random(in: 0.8...1.5)
            ))
        }
    }
    
    private func createScorePopup(points: Int, position: CGPoint) {
        let popupColor: Color
        switch comboCounter {
        case 1..<3: popupColor = .white
        case 3..<5: popupColor = .yellow
        case 5..<8: popupColor = .orange
        default: popupColor = .red
        }
        
        let text = "+\(points)" + (comboCounter > 1 ? " x\(comboCounter)" : "")
        
        particles.append(Particle(
            position: position,
            color: popupColor,
            scale: 1.0 + CGFloat(min(comboCounter, 10)) * 0.1,
            opacity: 1.0,
            velocity: CGSize(width: 0, height: -20),
            lifetime: 1.5,
            text: text
        ))
    }
    
    private func createLevelCompleteEffect() {
        // Create a circular particle explosion
        for _ in 0..<50 {
            let angle = Double.random(in: 0..<Double.pi * 2)
            let speed = Double.random(in: 50..<150)
            
            particles.append(Particle(
                position: CGPoint(x: gameArea.midX, y: gameArea.midY),
                color: Color(hue: Double.random(in: 0...1), saturation: 1, brightness: 1),
                scale: CGFloat.random(in: 1.0...3.0),
                opacity: 1.0,
                velocity: CGSize(
                    width: cos(angle) * speed,
                    height: sin(angle) * speed
                ),
                lifetime: Double.random(in: 1.0...2.0)
            ))
        }
    }
    
    private func updateParticles(deltaTime: TimeInterval) {
        var newParticles = particles
        
        for index in particles.indices {
            newParticles[index].position.x += particles[index].velocity.width * CGFloat(deltaTime)
            newParticles[index].position.y += particles[index].velocity.height * CGFloat(deltaTime)
            newParticles[index].lifetime -= deltaTime
            
            // Fade out
            if particles[index].lifetime < 0.3 {
                newParticles[index].opacity = particles[index].lifetime / 0.3
            }
        }
        
        particles = newParticles.filter { $0.lifetime > 0 }
    }
    
    private func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: "NeonBreakoutHighScore")
    }
    
    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: "NeonBreakoutHighScore")
    }
}

extension Particle {
    var fontSidze: CGFloat {
        scale * 12
    }
}

// MARK: - Main Game View
struct NeonBreakoutGame: View {
    @StateObject private var game = GameViewModel()
    @GestureState private var dragLocation: CGPoint = .zero
    @State private var showCombo: Bool = false
    @State private var comboScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Stars background
            StarsView()
                .opacity(0.5)
            
            // Game area
            GeometryReader { geometry in
                ZStack {
                    // Decorative neon frame
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.8),
                                    Color.purple.opacity(0.8),
                                    Color.pink.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .blur(radius: 2)
                        .padding(1)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.3),
                                    Color.pink.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .padding(1)
                    
                    // Bricks
                    ForEach(game.bricks.filter { $0.isVisible }) { brick in
                        BrickView(brick: brick)
                            .position(
                                x: brick.position.midX,
                                y: brick.position.midY
                            )
                    }
                    
                    // Balls
                    ForEach(game.balls.indices, id: \.self) { index in
                        BallView()
                            .position(
                                x: game.balls[index].midX,
                                y: game.balls[index].midY
                            )
                    }
                    
                    // Power-ups
                    ForEach(game.powerUps.filter { $0.isActive }) { powerUp in
                        PowerUpView(type: powerUp.type)
                            .position(powerUp.position)
                    }
                    
                    // Lasers
                    ForEach(game.lasers.indices, id: \.self) { index in
                        LaserView()
                            .frame(width: game.lasers[index].width, height: game.lasers[index].height)
                            .position(x: game.lasers[index].midX, y: game.lasers[index].midY)
                    }
                    
                    ForEach(game.particles) { particle in
                        if let text = particle.text {
                            Text(text)
                                .font(.system(size: particle.fontSize, weight: .bold, design: .rounded))
                                .foregroundColor(particle.color)
                                .position(particle.position)
                                .opacity(particle.opacity)
                                .shadow(color: particle.color, radius: 5, x: 0, y: 0)
                        } else {
                            Circle()
                                .fill(particle.color)
                                .frame(width: particle.scale * 8, height: particle.scale * 8)
                                .position(particle.position)
                                .opacity(particle.opacity)
                                .blur(radius: particle.scale * 2)
                                .shadow(color: particle.color, radius: particle.scale * 3, x: 0, y: 0)
                        }
                    }
                    // Paddle with neon glow
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.8, blue: 1.0),
                                        Color(red: 0.6, green: 0.2, blue: 1.0)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: game.paddlePosition.width, height: game.paddlePosition.height)
                            .blur(radius: 2)
                            .opacity(0.6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.1, green: 0.6, blue: 1.0),
                                        Color(red: 0.5, green: 0.1, blue: 1.0)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: game.paddlePosition.width, height: game.paddlePosition.height)
                        
                        if game.isLaserActive {
                            Capsule()
                                .fill(Color.red)
                                .frame(width: game.paddlePosition.width, height: 3)
                                .offset(y: -5)
                                .shadow(color: .red, radius: 10, x: 0, y: 0)
                        }
                    }
                    .position(x: game.paddlePosition.midX, y: game.paddlePosition.midY)
                    
                    // Game overlay UI
                    VStack {
                        GameStatsView(game: game)
                            .padding(.top, 10)
                        
                        Spacer()
                        
                        if game.gameOver {
                            GameOverView(game: game)
                                .transition(.scale.combined(with: .opacity))
                        } else if game.showInstructions {
                            InstructionsView(game: game)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    // Combo display
                    if game.comboCounter > 1 {
                        Text("COMBO x\(game.comboCounter)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 1.0, green: 0.3, blue: 0.3),
                                                Color(red: 1.0, green: 0.7, blue: 0.0)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .orange, radius: 10, x: 0, y: 0)
                            )
                            .scaleEffect(comboScale)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.4)
                            .onAppear {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                    comboScale = 1.2
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        comboScale = 1.0
                                    }
                                }
                            }
                    }
                }
                .onAppear {
                    game.updateGameArea(geometry.frame(in: .local))
                }
                .onChange(of: geometry.size) { _ in
                    game.updateGameArea(geometry.frame(in: .local))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragLocation) { value, state, _ in
                            state = value.location
                            game.movePaddle(to: state)
                        }
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Stars Background View
struct StarsView: View {
    @State private var stars: [CGPoint] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars.indices, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...2), height: CGFloat.random(in: 1...2))
                        .position(stars[index])
                        .opacity(Double.random(in: 0.5...1.0))
                }
            }
            .onAppear {
                // Generate random stars
                stars = (0..<100).map { _ in
                    CGPoint(
                        x: CGFloat.random(in: 0..<geometry.size.width),
                        y: CGFloat.random(in: 0..<geometry.size.height)
                    )
                }
            }
        }
    }
}

// MARK: - Brick View
struct BrickView: View {
    let brick: Brick
    
    var body: some View {
        ZStack {
            // Brick with neon border
            RoundedRectangle(cornerRadius: 4)
                .fill(brick.color.opacity(brick.isIndestructible ? 0.3 : 0.8))
                .frame(width: brick.position.width, height: brick.position.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    brick.color,
                                    .white
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .opacity(0.8)
                )
                .shadow(color: brick.color, radius: 5, x: 0, y: 0)
            
            // Indestructible bricks have a special pattern
            if brick.isIndestructible {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .white,
                                brick.color
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 2])
                    )
                    .frame(width: brick.position.width, height: brick.position.height)
            }
            
            // Health indicator
            if brick.health > 1 && !brick.isIndestructible {
                Text("\(brick.health)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
            }
            
            // Power-up indicator
            if let effect = brick.specialEffect {
                Image(systemName: iconForEffect(effect))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: brick.health > 1 ? -8 : 0)
                    .shadow(color: .black, radius: 1, x: 1, y: 1)
            }
        }
    }
    
    private func iconForEffect(_ effect: SpecialEffect) -> String {
        switch effect {
        case .extraBall: return "plus.circle"
        case .widenPaddle: return "arrow.left.and.right"
        case .laserPaddle: return "bolt"
        case .slowBall: return "tortoise"
        case .scoreMultiplier: return "x.squareroot"
        case .bomb: return "burst"
        }
    }
}

// MARK: - Ball View
struct BallView: View {
    @State private var pulse: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 1.0, blue: 1.0),
                            Color(red: 0.8, green: 0.8, blue: 1.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: GameConstants.ballSize / 2
                    )
                )
                .frame(width: GameConstants.ballSize, height: GameConstants.ballSize)
                .shadow(color: .blue, radius: 10, x: 0, y: 0)
                .scaleEffect(pulse ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.5).repeatForever(),
                    value: pulse
                )
                .onAppear {
                    pulse = true
                }
            
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.5, blue: 1.0),
                            Color(red: 0.8, green: 0.3, blue: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: GameConstants.ballSize, height: GameConstants.ballSize)
                .blur(radius: 1)
        }
    }
}

// MARK: - PowerUp View
struct PowerUpView: View {
    let type: SpecialEffect
    @State private var floating: Bool = false
    
    var body: some View {
        let (mainColor, secondaryColor) = colorsForPowerUp(type)
        
        return ZStack {
            Circle()
                .fill(mainColor)
                .frame(width: GameConstants.powerUpSize, height: GameConstants.powerUpSize)
                .shadow(color: mainColor, radius: 10, x: 0, y: 0)
                .offset(y: floating ? -5 : 5)
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(),
                    value: floating
                )
                .onAppear {
                    floating = true
                }
            
            Image(systemName: iconForPowerUp(type))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(secondaryColor)
        }
    }
    
    private func colorsForPowerUp(_ type: SpecialEffect) -> (Color, Color) {
        switch type {
        case .extraBall: return (Color.green, Color.white)
        case .widenPaddle: return (Color.blue, Color.white)
        case .laserPaddle: return (Color.red, Color.white)
        case .slowBall: return (Color.purple, Color.white)
        case .scoreMultiplier: return (Color.yellow, Color.black)
        case .bomb: return (Color.orange, Color.white)
        }
    }
    
    private func iconForPowerUp(_ type: SpecialEffect) -> String {
        switch type {
        case .extraBall: return "plus"
        case .widenPaddle: return "arrow.left.and.right"
        case .laserPaddle: return "bolt"
        case .slowBall: return "tortoise"
        case .scoreMultiplier: return "x.squareroot"
        case .bomb: return "burst"
        }
    }
}

// MARK: - Laser View
struct LaserView: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red,
                        Color(red: 1.0, green: 0.5, blue: 0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .red, radius: 5, x: 0, y: 0)
    }
}

// MARK: - Game Stats View
struct GameStatsView: View {
    @ObservedObject var game: GameViewModel
    
    var body: some View {
        HStack(spacing: 10) {
            // Score
            StatBox(title: "SCORE", value: "\(game.score)", color: Color(red: 0.2, green: 0.7, blue: 1.0))
            
            // Level
            StatBox(title: "LEVEL", value: "\(game.level)", color: Color(red: 0.8, green: 0.2, blue: 1.0))
            
            // Multiplier
            if game.multiplier > 1 {
                StatBox(title: "MULTIPLIER", value: "x\(game.multiplier)", color: Color(red: 1.0, green: 0.8, blue: 0.2))
            }
        }
        .padding(.horizontal, 10)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .kerning(1)
            
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(minWidth: 50)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: 1)
        )
    }
}

// MARK: - Instructions View
struct InstructionsView: View {
    @ObservedObject var game: GameViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            // Game title with neon effect
            VStack(spacing: 5) {
                Text("NEON")
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.blue, radius: 10, x: 0, y: 0)
                
                Text("BREAKOUT")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.purple, radius: 10, x: 0, y: 0)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.7, blue: 1.0),
                                Color(red: 0.8, green: 0.2, blue: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Text("BREAKOUT")
                                .font(.system(size: 60, weight: .black, design: .rounded))
                        )
                    )
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 18) {
                InstructionStep(icon: "hand.draw.fill", text: "Drag to move the paddle", color: Color(red: 0.2, green: 0.7, blue: 1.0))
                
                InstructionStep(icon: "circle.fill", text: "Bounce the ball to break bricks", color: Color(red: 0.8, green: 0.2, blue: 1.0))
                
                InstructionStep(icon: "bolt.fill", text: "Collect power-ups for special abilities", color: Color(red: 1.0, green: 0.5, blue: 0.0))
                
                InstructionStep(icon: "flame.fill", text: "Chain breaks for combo multipliers", color: Color(red: 1.0, green: 0.2, blue: 0.2))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.5),
                                        Color.purple.opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 30)
            
            // Start button
            Button(action: {
                withAnimation {
                    game.startGame()
                }
            }) {
                HStack {
                    Text("START GAME")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 30)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.7, blue: 1.0),
                            Color(red: 0.8, green: 0.2, blue: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: Color.purple.opacity(0.7), radius: 10, x: 0, y: 5)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

struct InstructionStep: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    @ObservedObject var game: GameViewModel
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Game over title
            Text("GAME OVER")
                .font(.system(size: 50, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.red, radius: 10, x: 0, y: 0)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.2, blue: 0.2),
                            Color(red: 1.0, green: 0.7, blue: 0.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        Text("GAME OVER")
                            .font(.system(size: 50, weight: .black, design: .rounded))
                    )
                )
            
            // Stats
            VStack(spacing: 15) {
                ScoreStat(title: "SCORE", value: "\(game.score)", isHighlighted: true)
                
                if game.score == game.highScore {
                    Text("NEW HIGH SCORE!")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.2))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 1.0, green: 0.8, blue: 0.2), lineWidth: 1)
                                )
                        )
                }
                
                ScoreStat(title: "HIGH SCORE", value: "\(game.highScore)", isHighlighted: false)
                
                ScoreStat(title: "BRICKS BROKEN", value: "\(game.totalBricksBroken)", isHighlighted: false)
                
                ScoreStat(title: "LEVEL REACHED", value: "\(game.level)", isHighlighted: false)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.5),
                                        Color.purple.opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 30)
            
            // Action buttons
            HStack(spacing: 15) {
                Button(action: {
                    withAnimation {
                        game.startGame()
                    }
                }) {
                    ActionButton(label: "PLAY AGAIN", icon: "arrow.counterclockwise", color: Color(red: 0.2, green: 0.7, blue: 1.0))
                }
                
                Button(action: {
                    showShareSheet = true
                }) {
                    ActionButton(label: "SHARE", icon: "square.and.arrow.up", color: Color(red: 0.8, green: 0.2, blue: 1.0))
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: ["I scored \(game.score) points in Neon Breakout! Can you beat my high score of \(game.highScore)?"])
        }
    }
}

struct ScoreStat: View {
    let title: String
    let value: String
    let isHighlighted: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: isHighlighted ? 24 : 20, weight: .black, design: .rounded))
                .foregroundColor(isHighlighted ? Color(red: 0.2, green: 0.7, blue: 1.0) : .white)
        }
        .frame(width: 200)
    }
}

struct ActionButton: View {
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            
            Text(label)
                .font(.system(size: 16, weight: .black, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(color)
        .cornerRadius(20)
        .shadow(color: color.opacity(0.7), radius: 5, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Activity View for Sharing
struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NeonBreakoutGame()
            .preferredColorScheme(.dark)
    }
}
