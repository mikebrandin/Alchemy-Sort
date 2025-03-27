import SwiftUI

struct Level: Identifiable {
    let id: Int
    let containerCount: Int
    let filledContainers: Int
    let colors: [Color]
    let elementType: ElementType
    let containerType: ContainerType
    let difficulty: Difficulty
    
    static let levels: [Level] = {
        var allLevels: [Level] = []
        let difficulties: [Difficulty] = [.tutorial, .easy, .medium, .hard]
        
        // Base colors available for all levels
        let baseColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .cyan, .teal, .gray, .brown, .mint, .indigo, .pink]
        
        for difficulty in difficulties {
            for levelIndex in 0..<9 {
                let baseIndex = difficulties.firstIndex(of: difficulty)! * 9 + levelIndex
                
                // For now, all levels use liquid type
                let containerType: ContainerType = .liquid
                let elementType: ElementType = .liquid
                
                // Calculate number of colors based on container count
                // Number of colors must be containerCount - 1 (one empty container needed)
                let colorCount = difficulty.containerCount - 1
                
                // Select colors for this level
                let levelColors = Array(baseColors.prefix(colorCount))
                
                allLevels.append(Level(
                    id: baseIndex + 1,
                    containerCount: difficulty.containerCount,
                    filledContainers: difficulty.filledcontainers,
                    colors: levelColors,
                    elementType: elementType,
                    containerType: containerType,
                    difficulty: difficulty
                ))
            }
        }
        
        return allLevels
    }()
} 
