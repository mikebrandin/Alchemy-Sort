import SwiftUI

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

enum Difficulty: String, CaseIterable {
    case tutorial, easy, medium, hard
    
    var containerCount: Int {
        switch self {
        case .tutorial: return 4
        case .easy: return 8
        case .medium: return 12
        case .hard: return 15
        }
    }
    
    var filledcontainers: Int {
        switch self {
        case .tutorial: return 3
        case .easy: return 6
        case .medium: return 10
        case .hard: return 13
        }
    }
    
    var emptycontainers: Int {
        return containerCount - filledcontainers
    }
}

class GameViewModel: ObservableObject {
    @Published var containers: [Container] = []
    @Published var currentDifficulty: Difficulty = .tutorial
    @Published var isLevelComplete = false
    @Published var moves: Int = 0
    @Published var score: Int = 0
    @Published var selectedContainerIndex: Int? = nil
    var containerFrames: [CGRect] = []
    private let maxCapacity = 4
    private let totalcontainers = 6
    
    // Scoring constants
    private let completeContainerPoints = 1000
    private let movePoints = -10
    
    // Store initial state for reset
    private var initialElements: [[Element]] = []
    
    // Store move history for undo
    private struct Move {
        let containers: [Container]
        let score: Int
        let moves: Int
    }
    private var moveHistory: [Move] = []
    
    init() {
        // Initialize with tutorial difficulty
        setupLevel(difficulty: .tutorial)
    }
    
    func setupLevel(difficulty: Difficulty) {
        currentDifficulty = difficulty
        isLevelComplete = false
        moves = 0
        score = 0
        moveHistory.removeAll()
        
        // Initialize containers based on difficulty
        containers = Array(repeating: Container(type: .liquid), count: difficulty.containerCount)
        
        // For tutorial difficulty, use exactly red, green, and blue
        var gameColors: [Color]
        if difficulty == .tutorial {
            gameColors = [.red, .green, .blue]
        } else {
            // For other difficulties, use random colors
            let availableColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
            gameColors = Array(availableColors.shuffled().prefix(difficulty.filledcontainers))
        }
        
        // Create elements (exactly 4 per color)
        var elements: [Element] = []
        for color in gameColors {
            elements += Array(repeating: Element(type: .liquid, color: color), count: maxCapacity)
        }
        elements.shuffle() // Randomly arrange the elements
        
        // Distribute to filled containers
        initialElements = []
        for containerIndex in 0..<difficulty.filledcontainers {
            let start = containerIndex * maxCapacity
            let end = start + maxCapacity
            let containerElements = Array(elements[start..<end])
            containers[containerIndex].elements = containerElements
            initialElements.append(containerElements)
        }
        
        // Add empty arrays for empty containers
        for _ in difficulty.filledcontainers..<difficulty.containerCount {
            initialElements.append([])
        }
        
        updateScore()
        
        print("Level setup with \(difficulty.filledcontainers) filled containers and \(difficulty.emptycontainers) empty containers")
        print("Using colors: \(gameColors)")
    }
    
    func handleContainerTap(at index: Int) {
        if let selectedIndex = selectedContainerIndex {
            // If we already have a selected container
            if selectedIndex != index {
                // Pour from selected to tapped container
                pour(from: selectedIndex, to: index)
            }
            // Clear selection in either case
            selectedContainerIndex = nil
        } else {
            // If no container is selected and the tapped container isn't empty
            if !containers[index].isEmpty {
                selectedContainerIndex = index
            }
        }
    }
    
    func resetLevel() {
        moves = 0
        score = 0
        isLevelComplete = false
        moveHistory.removeAll()
        selectedContainerIndex = nil
        
        // Restore containers to their initial state
        for (index, elements) in initialElements.enumerated() {
            containers[index].elements = elements
        }
        
        updateScore()
    }
    
    func undo() {
        guard let lastMove = moveHistory.popLast() else { return }
        containers = lastMove.containers
        score = lastMove.score
        moves = lastMove.moves
        isLevelComplete = false  // Reset win state when undoing
        selectedContainerIndex = nil  // Clear selection when undoing
    }
    
    var canUndo: Bool {
        !moveHistory.isEmpty
    }
    
    private func updateScore() {
        // Start with 0 score
        var newScore = 0
        
        // Add points for each completed container
        for container in containers {
            if !container.isEmpty && container.isFull {
                let firstColor = container.elements[0].color
                if container.elements.allSatisfy({ $0.color == firstColor }) {
                    newScore += completeContainerPoints
                }
            }
        }
        
        // Subtract points for moves
        newScore += moves * movePoints
        
        // Ensure score doesn't go below 0
        score = max(0, newScore)
    }
    
    func pour(from sourceIndex: Int, to targetIndex: Int) {
        guard validatePour(from: sourceIndex, to: targetIndex) else { return }
        
        // Save current state before making the move
        moveHistory.append(Move(containers: containers, score: score, moves: moves))
        
        let sourceContainer = containers[sourceIndex]
        let targetContainer = containers[targetIndex]
        
        // Get the source color we're trying to pour
        guard let sourceColor = sourceContainer.topColor else { return }
        
        // Count how many matching elements we can pour from the top
        var matchingCount = 0
        for element in sourceContainer.elements.reversed() {
            if element.color == sourceColor {
                matchingCount += 1
            } else {
                break
            }
        }
        
        // Calculate available space in target container
        let availableSpace = maxCapacity - targetContainer.elements.count
        let pourCount = min(matchingCount, availableSpace)
        
        // Create new array to trigger SwiftUI update
        var newContainers = containers
        let elementsToPour = Array(newContainers[sourceIndex].elements.suffix(pourCount))
        newContainers[sourceIndex].elements.removeLast(pourCount)
        newContainers[targetIndex].elements.append(contentsOf: elementsToPour)
        
        // Animate the change
        withAnimation(.spring()) {
            containers = newContainers
            moves += 1
        }
        
        updateScore()
        checkLevelCompletion()
    }
    
    private func validatePour(from: Int, to: Int) -> Bool {
        guard from != to,
              from >= 0 && from < containers.count,
              to >= 0 && to < containers.count,
              !containers[from].elements.isEmpty,
              containers[to].elements.count < maxCapacity
        else { return false }
        
        let sourceColor = containers[from].topColor
        let targetColor = containers[to].topColor
        
        // Can pour if target is empty or colors match
        return targetColor == nil || targetColor == sourceColor
    }
    
    func containerIndex(at location: CGPoint) -> Int? {
        containerFrames.firstIndex { $0.contains(location) }
    }
    
    func updateFrame(_ frame: CGRect, for index: Int) {
        // Ensure array is properly sized
        if containerFrames.count <= index {
            containerFrames += Array(repeating: .zero, count: index - containerFrames.count + 1)
        }
        containerFrames[index] = frame
    }
    
    private func checkLevelCompletion() {
        // Level is complete when all non-empty containers have 4 matching colors
        isLevelComplete = containers.allSatisfy { container in
            if container.isEmpty { 
                // Empty containers are valid in win condition
                return true
            }
            // Non-empty containers must be full and have matching colors
            if !container.isFull { return false }
            let firstColor = container.elements[0].color
            return container.elements.allSatisfy { $0.color == firstColor }
        }
    }
    
    func checkWin() -> Bool {
        return isLevelComplete
    }
}
