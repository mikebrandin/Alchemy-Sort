//
//  Element.swift
//  Alchemy Sort
//
//  Created by Mike Brandin on 3/24/25.
//

import SwiftUI

enum ElementType: Hashable {
    case liquid
    case solid
    case gas
}

struct Element: Identifiable, Hashable {
    let id = UUID()
    let type: ElementType
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
        // Since Color isn't Hashable, we'll hash its components
        if let components = UIColor(color).cgColor.components {
            for component in components {
                hasher.combine(component)
            }
        }
    }
    
    static func == (lhs: Element, rhs: Element) -> Bool {
        // Compare by id since elements should be unique
        return lhs.id == rhs.id
    }
}
