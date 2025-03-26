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
        case .tutorial: return 4  // 3 colors + 1 empty
        case .easy: return 6      // 5 colors + 1 empty
        case .medium: return 8    // 7 colors + 1 empty
        case .hard: return 10     // 8 colors + 2 empty
        }
    }
    
    var filledcontainers: Int {
        switch self {
        case .tutorial: return containerCount - 1  // 1 empty
        case .easy: return containerCount - 1      // 1 empty
        case .medium: return containerCount - 1    // 1 empty
        case .hard: return containerCount - 2      // 2 empty
        }
    }
    
    var emptycontainers: Int {
        containerCount - filledcontainers
    }
}

class GameViewModel: ObservableObject {
    @Published var containers: [Container] = []
    @Published var isLevelComplete = false
    @Published var moves: Int = 0
    @Published var score: Int = 0
    @Published var selectedContainerIndex: Int? = nil
    @Published var pouringState: PouringState?
    var containerFrames: [CGRect] = []
    let level: Level
    private let maxCapacity = 4
    
    // Scoring constants
    private let completeContainerPoints = 1000
    private let movePoints = -10
    
    // Store initial state for reset
    private var initialElements: [[Element]] = []
    
    // Store move history for undo
    private struct Move {
        let sourceIndex: Int
        let targetIndex: Int
        let sourceElements: [Element]
        let targetElements: [Element]
    }
    private var moveHistory: [Move] = []
    @Published var canUndo: Bool = false
    
     @Published var hintMove: (from: Int, to: Int)?
     @Published var isHintCooldown = false
    // private var solutionCache: [GameState: [(from: Int, to: Int)]] = [:]
    // private var isCalculatingHint = false
     private var initialSolutionPath: [(from: Int, to: Int)] = []
    
    @Published var showWinScreen = false
    @Published var nextLevelAvailable: Bool
    
    // Cache for successful level patterns
    private static var mediumLevelPatterns: [[[Element]]] = []
    
    init(level: Level) {
        self.level = level
        // Determine if next level is available based on current level ID
        self.nextLevelAvailable = Level.levels.contains { $0.id == level.id + 1 }
        setupLevel()
    }
    
    private func setupLevel() {
        print("\n=== Starting Level Setup ===")
        print("Difficulty: \(level.difficulty), Container Count: \(level.containerCount), Colors: \(level.colors.count)")
        
        isLevelComplete = false
        moves = 0
        score = 0
        moveHistory.removeAll()
        
        var attempts = 0
        let maxAttempts = 100 // Maximum attempts to generate a valid level
        let startTime = Date()
        
        repeat {
            attempts += 1
            print("\n--- Attempt \(attempts) ---")
            
            // Initialize containers based on level
            containers = Array(repeating: Container(type: level.containerType), count: level.containerCount)
            
            if level.difficulty == .hard && !GameViewModel.mediumLevelPatterns.isEmpty {
                print("Attempting pattern-based generation (Available patterns: \(GameViewModel.mediumLevelPatterns.count))")
                if generateHardLevelFromPattern() {
                    print("Successfully generated hard level from pattern")
                    break
                }
                print("Pattern-based generation failed, falling back to random generation")
            }
            
            print("Generating random level configuration...")
            // Create elements (exactly 4 per color)
            var elements: [Element] = []
            for color in level.colors {
                elements += Array(repeating: Element(type: level.elementType, color: color), count: maxCapacity)
            }
            
            // Create valid initial distribution
            initialElements = []
            for containerIndex in 0..<level.filledContainers {
                var containerElements: [Element] = []
                var availableElements = elements
                
                print("Filling container \(containerIndex + 1)/\(level.filledContainers)")
                // Fill each container with 4 elements
                for position in 0..<maxCapacity {
                    // Filter out elements that would create 3 in a row
                    let validElements = availableElements.enumerated().filter { (index, element) in
                        if containerElements.count >= 2 {
                            let lastTwo = containerElements.suffix(2)
                            if lastTwo.allSatisfy({ $0.color == element.color }) {
                                return false // Would create 3 in a row
                            }
                        }
                        return true
                    }
                    
                    print("  Position \(position + 1): \(validElements.count) valid elements available")
                    
                    // If no valid elements (shouldn't happen with proper color counts), just take any
                    let selectedIndex = validElements.isEmpty ? 
                        Int.random(in: 0..<availableElements.count) :
                        validElements[Int.random(in: 0..<validElements.count)].offset
                    
                    containerElements.append(availableElements[selectedIndex])
                    availableElements.remove(at: selectedIndex)
                }
                
                containers[initialElements.count].elements = containerElements
                initialElements.append(containerElements)
                elements = availableElements
            }
            
            // Add empty arrays for empty containers
            for _ in level.filledContainers..<level.containerCount {
                initialElements.append([])
            }
            
            print("\nValidating level configuration...")
            // Validate that the level is solvable
            if validateLevel(containers: initialElements) {
                let duration = Date().timeIntervalSince(startTime)
                print("Found valid level after \(attempts) attempts (Time: \(String(format: "%.2f", duration))s)")
                // Cache pattern if it's a medium level
                if level.difficulty == .medium {
                    GameViewModel.mediumLevelPatterns.append(initialElements)
                    print("Cached medium level pattern (Total patterns: \(GameViewModel.mediumLevelPatterns.count))")
                }
                break
            }
            print("Generated unsolvable level, retrying...")
            
        } while attempts < maxAttempts
        
        if attempts >= maxAttempts {
            print("⚠️ WARNING: Failed to generate valid level after \(maxAttempts) attempts")
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        print("\n=== Level Setup Complete ===")
        print("Total time: \(String(format: "%.2f", totalDuration))s")
        print("Final attempts: \(attempts)")
        print("=========================\n")
        
        updateScore()
        updateCanUndo()
        
        // Removed hint function call.
        // TODO: Figure out best way to implement Hint functionality.
        // calculateHintInBackground()
    }
    
    private func generateHardLevelFromPattern() -> Bool {
        print("\n--- Generating Hard Level from Pattern ---")
        // Select a random medium level pattern
        guard let basePattern = GameViewModel.mediumLevelPatterns.randomElement() else { 
            print("No medium patterns available")
            return false 
        }
        
        print("Selected base pattern with \(basePattern.count) containers")
        
        // Create a copy of the pattern
        var hardPattern = basePattern
        
        // Add new containers for the additional colors
        let additionalColors = level.colors.dropFirst(basePattern.count)
        print("Adding \(additionalColors.count) new color containers")
        for color in additionalColors {
            var newContainer: [Element] = []
            for _ in 0..<maxCapacity {
                newContainer.append(Element(type: level.elementType, color: color))
            }
            hardPattern.append(newContainer)
        }
        
        // Add empty containers
        print("Adding \(level.difficulty.emptycontainers) empty containers")
        for _ in 0..<level.difficulty.emptycontainers {
            hardPattern.append([])
        }
        
        // Shuffle elements within containers to maintain solvability
        print("Shuffling elements within containers")
        for i in 0..<hardPattern.count where !hardPattern[i].isEmpty {
            hardPattern[i].shuffle()
        }
        
        print("Validating generated pattern...")
        // Validate the pattern
        if validateLevel(containers: hardPattern) {
            initialElements = hardPattern
            for (index, elements) in hardPattern.enumerated() {
                containers[index].elements = elements
            }
            print("Pattern validation successful")
            return true
        }
        
        print("Pattern validation failed")
        return false
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
        
        // Removed hint cache reference.
        // TODO: Figure out best way to implement Hint functionality.
        // solutionCache.removeAll()
        updateScore()
        updateCanUndo()
    }
    
    private func updateCanUndo() {
        canUndo = !moveHistory.isEmpty
    }
    
    func undo() {
        guard let lastMove = moveHistory.popLast() else { return }
        
        // Restore the containers to their previous state
        containers[lastMove.sourceIndex].elements = lastMove.sourceElements
        containers[lastMove.targetIndex].elements = lastMove.targetElements
        moves -= 1
        updateScore()
        updateCanUndo()
        
        // Removed hint function call.
        // TODO: Figure out best way to implement Hint functionality.
        // calculateHintInBackground()
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
    
    private func pour(from sourceIndex: Int, to targetIndex: Int) {
        guard validatePour(from: sourceIndex, to: targetIndex) else { return }
        
        let sourceContainer = containers[sourceIndex]
        let targetContainer = containers[targetIndex]
        
        // Save the current state of the containers before modifying them
        let oldSourceElements = sourceContainer.elements
        let oldTargetElements = targetContainer.elements
        
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
        
        // Safety check: ensure we have enough elements to pour
        guard pourCount > 0 && pourCount <= sourceContainer.elements.count else { return }
        
        // Get elements to pour (with safety check)
        let elementsToPour = Array(sourceContainer.elements.suffix(pourCount))
        
        // Start pouring animation
        pouringState = PouringState(
            sourceIndex: sourceIndex,
            targetIndex: targetIndex,
            elementsToPour: elementsToPour
        )
        
        // Sequence the pouring animation
        Task { @MainActor in
            // Move to pouring position
            withAnimation(.easeInOut(duration: 0.3)) {
                pouringState?.phase = .tilting
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Pour the elements
            withAnimation(.easeInOut(duration: 0.2)) {
                pouringState?.phase = .pouring
                
                // Safety check: ensure we still have enough elements to remove
                if sourceContainer.elements.count >= pourCount {
                    // Remove elements from source
                    containers[sourceIndex].elements.removeLast(pourCount)
                    // Add to target
                    containers[targetIndex].elements.append(contentsOf: elementsToPour)
                } else {
                    // If something went wrong, restore the original state
                    containers[sourceIndex].elements = oldSourceElements
                    containers[targetIndex].elements = oldTargetElements
                }
            }
            
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Return to original position
            withAnimation(.easeInOut(duration: 0.3)) {
                pouringState?.phase = .returning
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Complete the animation
            pouringState?.phase = .completed
            pouringState = nil
            moves += 1
            
            updateScore()
            checkLevelCompletion()
            
            // Removed hint function call.
            // TODO: Figure out best way to implement Hint functionality.
            // calculateHintInBackground()
        }
        
        // Add to move history
        moveHistory.append(Move(
            sourceIndex: sourceIndex,
            targetIndex: targetIndex,
            sourceElements: oldSourceElements,
            targetElements: oldTargetElements
        ))
        updateCanUndo()
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
                return true
            }
            if !container.isFull { return false }
            let firstColor = container.elements[0].color
            return container.elements.allSatisfy { $0.color == firstColor }
        }
        
        if isLevelComplete {
            showWinScreen = true
        }
    }
    
    func checkWin() -> Bool {
        return isLevelComplete
    }
    
    private func getSearchLimits(for difficulty: Difficulty) -> (states: Int, moves: Int) {
        switch difficulty {
        case .tutorial:
            return (states: 1_000, moves: 15)
        case .easy:
            return (states: 10_000, moves: 40)
        case .medium:
            return (states: 50_000, moves: 100)
        case .hard:
            return (states: 500_000, moves: 300)
        }
    }
    
    private func calculateHeuristic(state: GameState) -> Int {
        var cost = 0
        let containers = state.containers
        
        // 1. Count misplaced elements and flasks with multiple colors
        var flasksWithMultipleColors = 0
        var misplacedElements = 0
        
        for container in containers {
            if container.isEmpty { continue }
            
            // Get color counts in this container
            var colorCounts: [Color: Int] = [:]
            for element in container {
                colorCounts[element.color, default: 0] += 1
            }
            
            // Multiple colors in this flask
            if colorCounts.count > 1 {
                flasksWithMultipleColors += 1
                
                // Count misplaced elements (elements that don't match the dominant color)
                let (dominantColor, dominantCount) = colorCounts.max(by: { $0.value < $1.value })!
                misplacedElements += container.count - dominantCount
                
                // Higher penalty for breaking up larger groups
                if dominantCount >= 3 {
                    cost += 5 // Significant penalty for breaking up near-complete groups
                }
            } else if container.count < 4 {
                // Container has matching colors but is incomplete
                let color = container[0].color
                
                // Look for matching elements in other containers
                var foundMatching = false
                for otherContainer in containers {
                    if otherContainer == container { continue }
                    let matchingCount = otherContainer.filter { $0.color == color }.count
                    if matchingCount > 0 {
                        foundMatching = true
                        
                        // Penalty based on accessibility of matching elements
                        if otherContainer.last?.color == color {
                            cost += 1 // Easily accessible
                        } else {
                            cost += 3 // Buried under other colors
                        }
                    }
                }
                
                // If no matching elements found and container isn't full, state is invalid
                if !foundMatching && container.count < 4 {
                    return Int.max
                }
            }
        }
        
        // 2. Add weighted penalties
        cost += misplacedElements * 4 // Heavy penalty for misplaced elements
        cost += flasksWithMultipleColors * 6 // Even heavier penalty for mixed flasks
        
        // 3. Add penalty for suboptimal moves
        if let lastMove = state.lastMove {
            let (from, to) = lastMove
            let targetContainer = containers[to]
            
            // Penalize moves that:
            // a) Don't complete a container
            if targetContainer.count < 4 {
                cost += 2
            }
            // b) Split up matching elements
            let sourceContainer = containers[from]
            if !sourceContainer.isEmpty && sourceContainer.last?.color == targetContainer.first?.color {
                cost += 3
            }
        }
        
        return cost
    }
    
    private func getTargetDepth(for difficulty: Difficulty) -> Int {
        switch difficulty {
        case .tutorial: return 10
        case .easy: return 25
        case .medium: return 50
        case .hard: return 100
        }
    }
    
    private func validateLevel(containers: [[Element]]) -> Bool {
        let startTime = Date()
        print("\n--- Starting Level Validation (A*) ---")
        
        let initialState = GameState(containers: containers, moves: 0, lastMove: nil)
        let initialHeuristic = calculateHeuristic(state: initialState)
        
        // If initial state has invalid configuration
        if initialHeuristic == Int.max {
            print("❌ Initial state is invalid")
            return false
        }
        
        // Priority queue using f-score (path length + heuristic)
        var openSet = [(state: initialState, path: [(state: GameState, move: (from: Int, to: Int))](), priority: initialHeuristic)]
        var visited = Set<GameState>()
        visited.insert(initialState)
        
        let targetDepth = getTargetDepth(for: level.difficulty)
        print("Starting A* search with target depth: \(targetDepth)")
        
        var searchedStates = 0
        var lastProgressUpdate = Date()
        let progressInterval: TimeInterval = 1.0
        
        while !openSet.isEmpty {
            // Get state with lowest f-score
            openSet.sort { $0.priority < $1.priority }
            let current = openSet.removeFirst()
            searchedStates += 1
            
            // Progress update
            let now = Date()
            if now.timeIntervalSince(lastProgressUpdate) >= progressInterval {
                let duration = now.timeIntervalSince(startTime)
                print("Progress: Searched \(searchedStates) states - Time: \(String(format: "%.1f", duration))s")
                print("Current path length: \(current.path.count), Heuristic: \(current.priority)")
                lastProgressUpdate = now
            }
            
            if current.state.isComplete() {
                let duration = Date().timeIntervalSince(startTime)
                print("✅ Solution found!")
                print("States searched: \(searchedStates)")
                print("Solution moves: \(current.path.count)")
                print("Time taken: \(String(format: "%.2f", duration))s")
                
                // Store the solution path and cache all states along the path
                initialSolutionPath = current.path.map { $0.move }
                for i in 0..<current.path.count {
                    let state = current.path[i].state
                    let remainingMoves = Array(current.path[i...].map { $0.move })
                    // solutionCache[state] = remainingMoves
                }
                
                // Cache the solution path for every state in the found path
                for i in 0..<current.path.count {
                    let intermediateState = current.path[i].state
                    let remainingMoves = Array(current.path[i...].map { $0.move })
                    // solutionCache[intermediateState] = remainingMoves
                }
                
                return true
            }
            
            // Stop exploring this path if it exceeds target depth
            if current.path.count >= targetDepth {
                continue
            }
            
            // Get valid moves (strict validation)
            var moves: [(from: Int, to: Int)] = []
            for sourceIndex in 0..<current.state.containers.count {
                let sourceContainer = current.state.containers[sourceIndex]
                guard !sourceContainer.isEmpty else { continue }
                // Exclude containers that are already complete (full and uniform)
                if sourceContainer.count == self.maxCapacity && sourceContainer.allSatisfy({ $0.color == sourceContainer.first!.color }) {
                    continue
                }
                let sourceColor = sourceContainer.last!.color
                let sourceMatchingCount = sourceContainer.reversed().prefix(while: { $0.color == sourceColor }).count

                for targetIndex in 0..<current.state.containers.count {
                    guard sourceIndex != targetIndex else { continue }
                    let targetContainer = current.state.containers[targetIndex]
                    // Skip if target is full
                    guard targetContainer.count < self.maxCapacity else { continue }
                    // Can only pour if target is empty or colors match
                    if targetContainer.isEmpty {
                        // Only move to empty if moving all matching elements
                        if sourceMatchingCount == sourceContainer.count {
                            moves.append((sourceIndex, targetIndex))
                        }
                    } else if targetContainer.last!.color == sourceColor {
                        let availableSpace = self.maxCapacity - targetContainer.count
                        if sourceMatchingCount <= availableSpace {
                            moves.append((sourceIndex, targetIndex))
                        }
                    }
                }
            }
            
            // Try each valid move
            for move in moves {
                let nextState = current.state.pour(from: move.from, to: move.to)
                if !visited.contains(nextState) {
                    visited.insert(nextState)
                    let newPath = current.path + [(state: nextState, move: move)]
                    let newHeuristic = calculateHeuristic(state: nextState)
                    
                    // Skip invalid states
                    if newHeuristic == Int.max { continue }
                    
                    // f(n) = g(n) + h(n) where g(n) is path length and h(n) is heuristic
                    let priority = newPath.count + newHeuristic
                    openSet.append((state: nextState, path: newPath, priority: priority))
                }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("❌ No solution found")
        print("States searched: \(searchedStates)")
        print("Time taken: \(String(format: "%.2f", duration))s")
        return false
    }
        
    func getHint() {
    // TODO: find best way to implement
        
    }
    
    func goToNextLevel() {
        if let nextLevelIndex = Level.levels.firstIndex(where: { $0.id == level.id + 1 }) {
            let nextLevel = Level.levels[nextLevelIndex]
            // Handle navigation to next level (this will need to be implemented in the view)
        }
    }
}
