import SwiftUI

class GameViewModel: ObservableObject {
    @Published var containers: [Container] = []
    var containerFrames: [CGRect] = []
    private let maxCapacity = 4
    private let totalTubes = 6
    
    init() {
        setupRandomLevel()
    }
    
    func setupRandomLevel() {
        containers = Array(repeating: Container(elements: []), count: totalTubes)
        
        // Game parameters
        let numberOfColors = Int.random(in: 4...5)
        let colors = ElementType.allCases.shuffled().prefix(numberOfColors)
        let emptyTubes = Int.random(in: 1...2)
        let filledTubes = totalTubes - emptyTubes
        
        // Create elements (exactly 4 per color)
        var elements: [Element] = []
        for color in colors {
            elements += Array(repeating: Element(type: color), count: maxCapacity)
        }
        elements.shuffle()
        
        // Distribute to first N tubes
        for tubeIndex in 0..<filledTubes {
            let start = tubeIndex * maxCapacity
            let end = start + maxCapacity
            containers[tubeIndex].elements = Array(elements[start..<end])
        }
        
        // Keep empty tubes at the end (remove shuffle)
    }
    
    func pour(from sourceIndex: Int, to targetIndex: Int) {
        guard validatePour(from: sourceIndex, to: targetIndex) else { return }
        
        let sourceColor = containers[sourceIndex].elements.last!.type
        var movableElements: [Element] = []
        
        // Get movable elements
        for element in containers[sourceIndex].elements.reversed() {
            guard element.type == sourceColor else { break }
            movableElements.append(element)
        }
        
        // Calculate available space
        let availableSpace = maxCapacity - containers[targetIndex].elements.count
        movableElements = Array(movableElements.prefix(availableSpace))
        
        // Create new array to trigger SwiftUI update
        var newContainers = containers
        newContainers[sourceIndex].elements.removeLast(movableElements.count)
        newContainers[targetIndex].elements.append(contentsOf: movableElements.reversed())
        
        // Animate the change
        withAnimation(.spring()) {
            containers = newContainers
        }
    }
    
    private func validatePour(from: Int, to: Int) -> Bool {
        guard from != to,
              from >= 0 && from < containers.count,
              to >= 0 && to < containers.count,
              !containers[from].elements.isEmpty,
              containers[to].elements.count < maxCapacity
        else { return false }
        
        let targetColor = containers[to].elements.last?.type
        return targetColor == nil || targetColor == containers[from].elements.last?.type
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
}
