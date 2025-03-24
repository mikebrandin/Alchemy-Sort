import SwiftUI

struct GameView: View {
    @StateObject var viewModel = GameViewModel()
    
    var body: some View {
        VStack {
            Text("Alchemy Sort")
                .font(.largeTitle)
                .padding()
            
            HStack(spacing: 30) {
                ForEach(0..<viewModel.containers.count, id: \.self) { index in
                    ContainerView(container: viewModel.containers[index], index: index)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        viewModel.updateFrame(geo.frame(in: .global), for: index)
                                    }
                                    .onChange(of: geo.frame(in: .global)) { newFrame in
                                        viewModel.updateFrame(newFrame, for: index)
                                    }
                            }
                        )
                }
            }
            .padding()
            
            Button("New Game") {
                viewModel.setupRandomLevel()
            }
            .buttonStyle(.borderedProminent)
        }
        .environmentObject(viewModel)
    }
}
