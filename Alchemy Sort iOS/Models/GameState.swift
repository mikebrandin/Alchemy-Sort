import SwiftUI

struct GameState: Hashable {
    let containers: [[Element]]
    let moves: Int
    let lastMove: (from: Int, to: Int)?
    
    func hash(into hasher: inout Hasher) {
        // Hash each container's elements
        for container in containers {
            hasher.combine(container)
        }
    }
    
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        // Compare containers element by element
        guard lhs.containers.count == rhs.containers.count else { return false }
        
        for (leftContainer, rightContainer) in zip(lhs.containers, rhs.containers) {
            guard leftContainer.count == rightContainer.count else { return false }
            for (leftElement, rightElement) in zip(leftContainer, rightContainer) {
                if leftElement != rightElement { return false }
            }
        }
        return true
    }
    
    func isComplete() -> Bool {
        // A state is complete when:
        // 1. All non-empty containers have exactly 4 elements of the same color
        // 2. There is only Empty containers and non-empty like the above
        for container in containers {
            if !container.isEmpty {
                if container.count != 4 {
                    return false
                }
                let firstColor = container[0].color
                if !container.allSatisfy({ $0.color == firstColor }) {
                    return false
                }
            }
        }
        return true
    }
    
    func canPour(from: Int, to: Int) -> Bool {
        guard from != to,
              from >= 0, from < containers.count,
              to >= 0, to < containers.count,
              !containers[from].isEmpty,
              containers[to].count < 4 else {
            return false
        }
        
        let sourceColor = containers[from].last!.color
        
        // Can pour if target is empty or matches source color
        if containers[to].isEmpty {
            return true
        }
        
        return containers[to].last!.color == sourceColor
    }
    
    func pour(from: Int, to: Int) -> GameState {
        var newContainers = containers
        let sourceColor = newContainers[from].last!.color
        
        // Count matching elements at the top of source
        var matchingCount = 0
        for element in newContainers[from].reversed() {
            if element.color == sourceColor {
                matchingCount += 1
            } else {
                break
            }
        }
        
        // Calculate how many we can actually pour
        let availableSpace = 4 - newContainers[to].count
        let pourCount = min(matchingCount, availableSpace)
        
        // Move the elements
        let elementsToPour = newContainers[from].suffix(pourCount)
        newContainers[from].removeLast(pourCount)
        newContainers[to].append(contentsOf: elementsToPour)
        
        return GameState(
            containers: newContainers,
            moves: moves + 1,
            lastMove: (from, to)
        )
    }
} 
