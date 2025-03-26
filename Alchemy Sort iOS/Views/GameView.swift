import SwiftUI

struct GameView: View {
    @StateObject var viewModel: GameViewModel
    @Binding var selectedLevel: Level?
    
    init(level: Level, selectedLevel: Binding<Level?>) {
        _viewModel = StateObject(wrappedValue: GameViewModel(level: level))
        _selectedLevel = selectedLevel
    }
    
    private func gridColumns(for containerCount: Int) -> [GridItem] {
        let columns: Int
        if containerCount <= 4 {
            columns = 2  // 2 columns for tutorial levels (4 containers)
        } else if containerCount <= 6 {
            columns = 3  // 3 columns for easy levels (6 containers)
        } else if containerCount <= 8 {
            columns = 4  // 4 columns for medium levels (8 containers)
        } else {
            columns = 4  // 4 columns for hard levels (10 containers in 3 rows: 4-4-2)
        }
        return Array(repeating: GridItem(.flexible(), spacing: -35), count: columns)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedContainerIndex = nil
                    }
                
                VStack(spacing: 0) {
                    // Top Bar with Back and Reset buttons
                    HStack {
                        // Back button (top left)
                        Button(action: {
                            selectedLevel = nil
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Reset button (top right)
                        Button(action: {
                            viewModel.resetLevel()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Game Grid
                    LazyVGrid(columns: gridColumns(for: viewModel.level.containerCount), spacing: 20) {
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
                    .padding(.horizontal, 5)
                    
                    Spacer()
                    
                    // Bottom Bar with Undo and Hint buttons
                    HStack {
                        // Undo button (bottom left)
                        Button(action: {
                            viewModel.undo()
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(viewModel.canUndo ? Color.blue : Color.gray)
                                .clipShape(Circle())
                        }
                        .disabled(!viewModel.canUndo)
                        
                        Spacer()
                        
                        // Hint button (bottom right)
                        Button(action: {
                            viewModel.getHint()
                            if viewModel.hintMove != nil {
                                // viewModel.executeHint()
                            }
                        }) {
                            Image(systemName: "lightbulb")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(viewModel.isHintCooldown ? Color.gray : Color.yellow)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.isHintCooldown)
                    }
                    .padding()
                }
            }
            
            // Win Screen Overlay
            if viewModel.showWinScreen {
                ZStack {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text("Level Complete!")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Text("Score: \(viewModel.score)")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                viewModel.resetLevel()
                                viewModel.showWinScreen = false
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                selectedLevel = nil
                            }) {
                                Image(systemName: "list.bullet")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            
                            if viewModel.nextLevelAvailable {
                                Button(action: {
                                    if let nextLevelIndex = Level.levels.firstIndex(where: { $0.id == viewModel.level.id + 1 }) {
                                        selectedLevel = Level.levels[nextLevelIndex]
                                    }
                                }) {
                                    Image(systemName: "arrow.right")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(viewModel)
    }
}
