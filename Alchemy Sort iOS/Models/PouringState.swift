import SwiftUI

struct PouringState {
    let sourceIndex: Int
    let targetIndex: Int
    let elementsToPour: [Element]
    var phase: Phase = .starting
    
    enum Phase {
        case starting    // Initial state
        case tilting    // Moving to pour position
        case pouring    // Transferring elements
        case returning  // Moving back to original position
        case completed  // Animation complete
    }
} 