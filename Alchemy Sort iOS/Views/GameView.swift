import SwiftUI

struct GameView: View {
    @StateObject var viewModel = GameViewModel()
    
    private func gridColumns(for difficulty: Difficulty) -> [GridItem] {
        let columns: Int
        switch difficulty {
        case .tutorial: columns = 2  // 2x2 grid
        case .easy: columns = 2      // 2x4 grid
        case .medium, .hard: columns = 3  // 3x4 or 3x5 grid
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack(alignment: .topTrailing) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedContainerIndex = nil
                        }
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
                    
                    VStack {
                        Text(viewModel.currentDifficulty.rawValue.capitalized)
                            .font(.title)
                            .padding(.top)
                        
                        // Score and Moves
                        HStack(spacing: 20) {
                            Text("Score: \(viewModel.score)")
                                .font(.headline)
                            Text("Moves: \(viewModel.moves)")
                                .font(.headline)
                        }
                        .padding(.bottom)
                        
                        // Game Grid
                        LazyVGrid(columns: gridColumns(for: viewModel.currentDifficulty), spacing: 10) {
                            ForEach(0..<viewModel.containers.count, id: \.self) { index in
                                ContainerView(container: viewModel.containers[index], index: index)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .onAppear {
                                                    viewModel.updateFrame(geo.frame(in: .global), for: index)
                                                }
                                        }
                                    )
                            }
                        }
                        .padding(.horizontal, 10)
                        
                        if viewModel.isLevelComplete {
                            Text("Level Complete!")
                                .font(.title)
                                .foregroundColor(.green)
                                .padding()
                        }
                        
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    
                    // Reset button in top right
                    Button("Reset") {
                        viewModel.resetLevel()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            
            // Undo button in bottom left
            VStack {
                Spacer()
                HStack {
                    Button("Undo") {
                        viewModel.undo()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canUndo)
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(viewModel)
    }
}
