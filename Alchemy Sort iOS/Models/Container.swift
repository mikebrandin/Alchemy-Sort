//
//  Container.swift
//  Alchemy Sort
//
//  Created by Mike Brandin on 3/24/25.
//

import SwiftUI
import Foundation

enum ContainerType {
    case liquid
    case solid
    case gas
    
    var assetName: String {
        switch self {
        case .liquid:
            return "test_tube"
        case .solid:
            return "solid_container"
        case .gas:
            return "gas_container"
        }
    }
    
    func canAccept(_ elementType: ElementType) -> Bool {
        switch (self, elementType) {
        case (.liquid, .liquid),
             (.solid, .solid),
             (.gas, .gas):
            return true
        default:
            return false
        }
    }
}

struct Container: Identifiable {
    let id = UUID()
    var elements: [Element]
    let capacity: Int
    let type: ContainerType
    
    var isFull: Bool {
        elements.count >= capacity
    }
    
    var isEmpty: Bool {
        elements.isEmpty
    }
    
    var topElement: Element? {
        elements.last
    }
    
    var canPourInto: Bool {
        !isFull
    }
    
    var topColor: Color? {
        elements.last?.color
    }
    
    init(type: ContainerType, capacity: Int = 4) {
        self.type = type
        self.capacity = capacity
        self.elements = []
    }
    
    mutating func add(_ element: Element) {
        print("Adding element: \(element.color) to container with \(elements.count) elements")
        guard !isFull && type.canAccept(element.type) else { return }
        elements.append(element)
        print("Container now has \(elements.count) elements")
    }
    
    mutating func removeTop() -> Element? {
        guard !isEmpty else { return nil }
        return elements.removeLast()
    }
    
    mutating func removeTop(_ count: Int) -> [Element] {
        print("Removing \(count) elements from container with \(elements.count) elements")
        let removed = Array(elements.suffix(count))
        elements.removeLast(count)
        print("Container now has \(elements.count) elements")
        return removed
    }
}
