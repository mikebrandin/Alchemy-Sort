import SwiftUI

struct ContainerView: View {
    @EnvironmentObject var viewModel: GameViewModel
    let container: Container
    let index: Int
    
    private let tubeWidth: CGFloat = 100
    private let tubeHeight: CGFloat = 200
    private let liquidWidth: CGFloat = 60
    private let coordinateSpace = "gameBoardSpace"
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var dropLocation: CGPoint? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("test_tube")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: tubeWidth, height: tubeHeight)
                .overlay(
                    VStack(spacing: 0) {
                        Spacer(minLength: 20)
                        ForEach(container.elements.reversed()) { element in
                            element.type.color
                                .frame(width: liquidWidth, height: 25)
                                .cornerRadius(5)
                                .padding(.horizontal, (tubeWidth - liquidWidth)/2)
                        }
                    }
                    .padding(.bottom, 10)
                )
        }
        .coordinateSpace(name: coordinateSpace) // Add this modifier
        .offset(dragOffset)
        .zIndex(isDragging ? 1 : 0)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: dragOffset) { _ in
                        if isDragging {
                            let frame = geometry.frame(in: .global)
                            dropLocation = CGPoint(
                                x: frame.midX + dragOffset.width,
                                y: frame.midY + dragOffset.height
                            )
                        }
                    }
            }
        )
        .gesture(
            container.elements.isEmpty ? nil :
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    dragOffset = value.translation
                    if !isDragging {
                        isDragging = true
                    }
                }
                .onEnded { value in
                    isDragging = false
                    
                    if let dropLocation = dropLocation,
                       let targetIndex = viewModel.containerIndex(at: dropLocation) {
                        viewModel.pour(from: index, to: targetIndex)
                    }
                    
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                    dropLocation = nil
                }
        )

        .animation(.spring(), value: dragOffset)
    }
}
