import SwiftUI

struct ContainerView: View {
    @EnvironmentObject var viewModel: GameViewModel
    let container: Container
    let index: Int
    
    private let containerWidth: CGFloat = 100
    private let containerHeight: CGFloat = 100
    private let elementWidth: CGFloat = 34
    private let elementHeight: CGFloat = 22
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer(minLength: 20)
                ForEach(container.elements.reversed()) { element in
                    Rectangle()
                        .fill(element.color)
                        .frame(width: elementWidth, height: elementHeight)
                }
                Spacer(minLength: 0)
            }
            .frame(width: elementWidth)
            .clipShape(
                RoundedRectangle(cornerRadius: elementWidth/2)
            )
            
            Image("test_tube")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: containerWidth, height: containerHeight)
        }
        .scaleEffect(viewModel.selectedContainerIndex == index ? 1.1 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 100)
                .stroke(viewModel.selectedContainerIndex == index ? Color.yellow : Color.clear, lineWidth: 3)
        )
        .animation(.spring(), value: viewModel.selectedContainerIndex == index)
        .onTapGesture {
            viewModel.handleContainerTap(at: index)
        }
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
