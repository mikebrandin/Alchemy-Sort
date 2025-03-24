//
//  Container.swift
//  Alchemy Sort
//
//  Created by Mike Brandin on 3/24/25.
//

import SwiftUI

struct Container: Identifiable {
    let id = UUID()
    var elements: [Element]
    var isSelected = false
    var topElement: Element? { elements.last }
}
