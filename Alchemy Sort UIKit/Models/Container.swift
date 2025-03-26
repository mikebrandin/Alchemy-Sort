//
//  Container.swift
//  Alchemy Sort UIKit
//
//

import UIKit
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

class Container: NSObject {
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
    
    var topColor: UIColor? {
        elements.last?.color
    }
    
    init(type: ContainerType, capacity: Int = 4) {
        self.type = type
        self.capacity = capacity
        self.elements = []
        super.init()
    }
    
    func add(_ element: Element) {
        print("Adding element to container with \(elements.count) elements")
        guard !isFull && type.canAccept(element.type) else { return }
        elements.append(element)
        print("Container now has \(elements.count) elements")
    }
    
    func removeTop() -> Element? {
        guard !isEmpty else { return nil }
        return elements.removeLast()
    }
    
    func removeTop(_ count: Int) -> [Element] {
        print("Removing \(count) elements from container with \(elements.count) elements")
        let removed = Array(elements.suffix(count))
        elements.removeLast(min(count, elements.count))
        print("Container now has \(elements.count) elements")
        return removed
    }
} 