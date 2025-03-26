//
//  GameManager.swift
//  Alchemy Sort UIKit
//
//

import UIKit

// Helper extension 
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
    
    var filledContainers: Int {
        switch self {
        case .tutorial: return 3
        case .easy: return 6
        case .medium: return 10
        case .hard: return 13
        }
    }
    
    var emptyContainers: Int {
        return containerCount - filledContainers
    }
}

// Protocol for observing game state changes
protocol GameManagerDelegate: AnyObject {
    func gameStateDidChange()
    func containersPoured(from sourceIndex: Int, to targetIndex: Int)
    func levelCompleted()
    func scoreDidChange(to newScore: Int)
    func movesDidChange(to newMoves: Int)
}

class GameManager {
    // Game state
    var containers: [Container] = []
    var currentDifficulty: Difficulty = .tutorial
    var isLevelComplete = false
    var moves: Int = 0 {
        didSet {
            delegate?.movesDidChange(to: moves)
        }
    }
    var score: Int = 0 {
        didSet {
            delegate?.scoreDidChange(to: score)
        }
    }
    var selectedContainerIndex: Int? = nil
    
    // Animation tracking
    var pouringFromIndex: Int? = nil
    var pouringToIndex: Int? = nil
    
    // Game settings
    private let maxCapacity = 4
    
    // Scoring constants
    private let completeContainerPoints = 1000
    private let moveScorePenalty = 10
    
    // Store initial state for reset
    private var initialElements: [[Element]] = []
    
    // Store move history for undo
    private struct Move {
        let containers: [Container]
        let score: Int
        let moves: Int
    }
    private var moveHistory: [Move] = []
    
    // Delegate to notify UI of changes
    weak var delegate: GameManagerDelegate?
    
    init() {
        setupLevel(difficulty: .tutorial)
    }
    
    func setupLevel(difficulty: Difficulty) {
        currentDifficulty = difficulty
        isLevelComplete = false
        moves = 0
        score = 0
        moveHistory.removeAll()
        selectedContainerIndex = nil
        
        // Initialize containers based on difficulty
        containers = Array(repeating: Container(type: .liquid), count: difficulty.containerCount)
        
        // For tutorial difficulty, use exactly red, green, and blue
        var gameColors: [UIColor]
        if difficulty == .tutorial {
            gameColors = [.red, .green, .blue]
        } else {
            // For other difficulties, use random colors
            let availableColors: [UIColor] = [.red, .blue, .green, .yellow, .purple, .orange]
            gameColors = Array(availableColors.shuffled().prefix(difficulty.filledContainers))
        }
        
        // Create elements (exactly 4 per color)
        var elements: [Element] = []
        for color in gameColors {
            elements += Array(repeating: Element(type: .liquid, color: color), count: maxCapacity)
        }
        elements.shuffle() // Randomly arrange the elements
        
        // Distribute to filled containers
        initialElements = []
        for containerIndex in 0..<difficulty.filledContainers {
            let start = containerIndex * maxCapacity
            let end = start + maxCapacity
            let containerElements = Array(elements[start..<end])
            containers[containerIndex].elements = containerElements
            initialElements.append(containerElements)
        }
        
        // Add empty arrays for empty containers
        for _ in difficulty.filledContainers..<difficulty.containerCount {
            initialElements.append([])
        }
        
        updateScore()
        
        print("Level setup with \(difficulty.filledContainers) filled containers and \(difficulty.emptyContainers) empty containers")
        delegate?.gameStateDidChange()
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
        
        delegate?.gameStateDidChange()
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
        delegate?.gameStateDidChange()
    }
    
    func undo() {
        guard let lastMove = moveHistory.popLast() else { return }
        containers = lastMove.containers
        score = lastMove.score
        moves = lastMove.moves
        isLevelComplete = false  // Reset win state when undoing
        selectedContainerIndex = nil  // Clear selection when undoing
        
        delegate?.gameStateDidChange()
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
                if let firstColor = container.elements.first?.color {
                    let allSameColor = container.elements.allSatisfy { $0.color.isEqual(firstColor) }
                    if allSameColor {
                        newScore += completeContainerPoints
                    }
                }
            }
        }
        
        // Subtract points for moves
        newScore -= moves * moveScorePenalty
        
        // Ensure score doesn't go below 0
        score = max(0, newScore)
    }
    
    func pour(from sourceIndex: Int, to targetIndex: Int) {
        guard validatePour(from: sourceIndex, to: targetIndex) else { 
            selectedContainerIndex = nil
            return 
        }
        
        // Calculate how many elements will be poured
        let elementsCount = getPourCount(from: sourceIndex, to: targetIndex)
        
        // Save current state before making the move
        moveHistory.append(Move(containers: containers, score: score, moves: moves))
        
        // Trigger animation through delegate
        pouringFromIndex = sourceIndex
        pouringToIndex = targetIndex
        delegate?.containersPoured(from: sourceIndex, to: targetIndex)
        
        // Wait for the animation to complete before updating the model
        // In UIKit, we would use a completion handler from the animation
        // For now, we'll simulate this with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            let sourceContainer = self.containers[sourceIndex]
            let targetContainer = self.containers[targetIndex]
            
            // Get the source color we're trying to pour
            guard let sourceColor = sourceContainer.topColor else { return }
            
            // Count how many matching elements we can pour from the top
            var matchingCount = 0
            for element in sourceContainer.elements.reversed() {
                if element.color.isEqual(sourceColor) {
                    matchingCount += 1
                } else {
                    break
                }
            }
            
            // Calculate available space in target container
            let availableSpace = self.maxCapacity - targetContainer.elements.count
            let pourCount = min(matchingCount, availableSpace)
            
            // Create copies for update
            let elementsToPour = Array(self.containers[sourceIndex].elements.suffix(pourCount))
            self.containers[sourceIndex].elements.removeLast(pourCount)
            self.containers[targetIndex].elements.append(contentsOf: elementsToPour)
            
            // Update game state
            self.moves += 1
            self.updateScore()
            self.checkLevelCompletion()
            self.selectedContainerIndex = nil
            
            // Reset pouring animation trackers
            self.pouringFromIndex = nil
            self.pouringToIndex = nil
            
            // Notify UI of changes
            self.delegate?.gameStateDidChange()
        }
    }
    
    private func validatePour(from: Int, to: Int) -> Bool {
        guard from != to,
              from >= 0 && from < containers.count,
              to >= 0 && to < containers.count,
              !containers[from].isEmpty,
              containers[to].elements.count < maxCapacity
        else { return false }
        
        let sourceColor = containers[from].topColor
        let targetColor = containers[to].topColor
        
        // Can pour if target is empty or colors match
        return targetColor == nil || (sourceColor != nil && targetColor!.isEqual(sourceColor!))
    }
    
    func getPourCount(from sourceIndex: Int, to targetIndex: Int) -> Int {
        guard validatePour(from: sourceIndex, to: targetIndex),
              sourceIndex >= 0 && sourceIndex < containers.count,
              targetIndex >= 0 && targetIndex < containers.count else {
            return 0
        }
        
        let sourceContainer = containers[sourceIndex]
        let targetContainer = containers[targetIndex]
        
        // Get the source color we're trying to pour
        guard let sourceColor = sourceContainer.topColor else { return 0 }
        
        // Count how many matching elements we can pour from the top
        var matchingCount = 0
        for element in sourceContainer.elements.reversed() {
            if element.color.isEqual(sourceColor) {
                matchingCount += 1
            } else {
                break
            }
        }
        
        // Calculate available space in target container
        let availableSpace = maxCapacity - targetContainer.elements.count
        let pourCount = min(matchingCount, availableSpace)
        
        return pourCount
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
            if let firstColor = container.elements.first?.color {
                return container.elements.allSatisfy { $0.color.isEqual(firstColor) }
            }
            return false
        }
        
        if isLevelComplete {
            delegate?.levelCompleted()
        }
    }
} 