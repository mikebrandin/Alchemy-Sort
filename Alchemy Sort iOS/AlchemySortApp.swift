//
//  AlchemySortApp.swift
//  Alchemy Sort
//
//  Created by Mike Brandin on 3/24/25.
//

import SwiftUI

@main
struct AlchemySortApp: App {
    @State private var selectedLevel: Level?
    
    var body: some Scene {
        WindowGroup {
            if let level = selectedLevel {
                GameView(level: level, selectedLevel: $selectedLevel)
            } else {
                LevelsView(selectedLevel: $selectedLevel)
            }
        }
    }
}

struct AlchemySortAppPreview: View {
    @State private var selectedLevel: Level?
    
    var body: some View {
        if let level = selectedLevel {
            GameView(level: level, selectedLevel: $selectedLevel)
        } else {
            LevelsView(selectedLevel: $selectedLevel)
        }
    }
}

#Preview {
    AlchemySortAppPreview()
}
