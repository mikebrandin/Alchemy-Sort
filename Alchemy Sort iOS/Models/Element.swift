//
//  Element.swift
//  Alchemy Sort
//
//  Created by Mike Brandin on 3/24/25.
//

import SwiftUI

enum ElementType: String, CaseIterable {
    case red, blue, green, yellow, purple // 5 colors
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .purple: return .purple
        }
    }
}

struct Element: Identifiable {
    let id = UUID()
    var type: ElementType
}
