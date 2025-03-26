import SwiftUI

struct LevelsView: View {
    @Binding var selectedLevel: Level?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Alchemy Sort")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            VStack(alignment: .leading) {
                                Text(difficulty.rawValue.capitalized)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(Level.levels.filter { $0.difficulty == difficulty }) { level in
                                        Button(action: {
                                            selectedLevel = level
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(levelColor(for: level))
                                                    .frame(height: 100)
                                                    .shadow(radius: 5)
                                                
                                                VStack {
                                                    Text("\(level.id)")
                                                        .font(.title2)
                                                        .fontWeight(.bold)
                                                    Text("\(level.colors.count) Colors")
                                                        .font(.subheadline)
                                                    Text(elementTypeText(for: level))
                                                        .font(.caption)
                                                }
                                                .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func levelColor(for level: Level) -> Color {
        switch level.difficulty {
        case .tutorial:
            return .blue
        case .easy:
            return .green
        case .medium:
            return .orange
        case .hard:
            return .red
        }
    }
    
    private func elementTypeText(for level: Level) -> String {
        switch level.elementType {
        case .liquid:
            return "Liquid"
        case .solid:
            return "Solid"
        case .gas:
            return "Gas"
        }
    }
} 