//
//  Element.swift
//  Alchemy Sort
//
//  Created by Mike Brandin on 3/24/25.
//

import SwiftUI

enum ElementType {
    case liquid
    case solid
    case gas
}

struct Element: Identifiable {
    let id = UUID()
    let type: ElementType
    let color: Color
}
