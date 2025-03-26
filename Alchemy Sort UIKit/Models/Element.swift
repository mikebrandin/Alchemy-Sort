//
//  Element.swift
//  Alchemy Sort UIKit
//
//

import UIKit

enum ElementType {
    case liquid
    case solid
    case gas
}

class Element: NSObject {
    let id = UUID()
    let type: ElementType
    let color: UIColor
    
    init(type: ElementType, color: UIColor) {
        self.type = type
        self.color = color
        super.init()
    }
} 