import SwiftUI

struct ContainerView: View {
    @EnvironmentObject var viewModel: GameViewModel
    
    let container: Container
    let index: Int
    
    private let containerWidth: CGFloat = 100
    private let containerHeight: CGFloat = 100
    private let elementWidth: CGFloat = 34
    private let elementHeight: CGFloat = 22
    
    private var liquidHeight: CGFloat {
        CGFloat(container.elements.count) * elementHeight
    }
    
    private var isPouring: Bool {
        viewModel.pouringState?.sourceIndex == index
    }
    
    private var isPourTarget: Bool {
        viewModel.pouringState?.targetIndex == index
    }
    
    private var pourProgress: Double {
        guard let pouringState = viewModel.pouringState, isPouring else { return 0 }
        
        switch pouringState.phase {
        case .starting:
            return 0
        case .tilting:
            return 0.2  // Reduced from 0.3
        case .pouring:
            return 0.4  // Reduced from 1.0
        case .returning:
            return 0.2  // Reduced from 0.3
        case .completed:
            return 0
        }
    }

    private var liquidRotation: Double {
        guard let pouringState = viewModel.pouringState, isPouring else { return 0 }
        
        // Match container rotation direction
        let rotationDirection: Double
        if let sourceFrame = viewModel.containerFrames[safe: pouringState.sourceIndex],
        let targetFrame = viewModel.containerFrames[safe: pouringState.targetIndex] {
            rotationDirection = targetFrame.midX > sourceFrame.midX ? 1.0 : -1.0
        } else {
            rotationDirection = 1.0
        }
        
        switch pouringState.phase {
        case .starting:
            return 0
        case .tilting, .pouring:
            return 15.0 * rotationDirection // Reduced from 80.0 for better visibility
        case .returning, .completed:
            return 0
        }
    }

    private var pourRotation: Double {
        guard let pouringState = viewModel.pouringState else { return 0 }
        
        // Determine rotation direction based on source and target positions
        let rotationDirection: Double
        if let sourceFrame = viewModel.containerFrames[safe: pouringState.sourceIndex],
        let targetFrame = viewModel.containerFrames[safe: pouringState.targetIndex] {
            rotationDirection = targetFrame.midX > sourceFrame.midX ? 1.0 : -1.0
        } else {
            rotationDirection = 1.0
        }
        
        // Return rotation angle based on pouring phase
        switch pouringState.phase {
        case .starting:
            return 0
        case .tilting:
            return isPouring ? (80.0 * rotationDirection) : 0  // Reduced from 80.0
        case .pouring:
            return isPouring ? (80.0 * rotationDirection) : 0  // Reduced from 80.0
        case .returning:
            return 0
        case .completed:
            return 0
        }
    }

    private func calculateHorizontalOffset(sourceFrame: CGRect, targetFrame: CGRect) -> CGFloat {
        let sourceCenter = sourceFrame.midX
        let targetCenter = targetFrame.midX
        let horizontalGap: CGFloat = 60
        let horizontalDirection: CGFloat = targetCenter > sourceCenter ? 1.0 : -1.0
        let temp = horizontalDirection * ((containerWidth / 2) + horizontalGap)
        return (targetCenter - sourceCenter) - temp
    }
    
    private func calculateVerticalOffset(sourceFrame: CGRect, targetFrame: CGRect) -> CGFloat {
        let sourceTop = sourceFrame.minY
        let targetTop = targetFrame.minY
        let verticalGap: CGFloat = 110
        return targetTop - sourceTop - verticalGap
    }
    
    private var position: CGSize {
        guard let pouringState = viewModel.pouringState,
              isPouring,
              let sourceFrame = viewModel.containerFrames[safe: pouringState.sourceIndex],
              let targetFrame = viewModel.containerFrames[safe: pouringState.targetIndex] else {
            return .zero
        }
        
        switch pouringState.phase {
        case .starting:
            return .zero
        case .tilting, .pouring:
            let horizontalOffset = calculateHorizontalOffset(sourceFrame: sourceFrame, targetFrame: targetFrame)
            let verticalOffset = calculateVerticalOffset(sourceFrame: sourceFrame, targetFrame: targetFrame)
            return CGSize(width: horizontalOffset, height: verticalOffset)
        case .returning, .completed:
            return .zero
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Liquid elements
            VStack(spacing: 0) {
                Spacer(minLength: containerHeight - liquidHeight)
                if !container.elements.isEmpty {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            ForEach(container.elements.reversed()) { element in
                                Rectangle()
                                    .fill(element.color)
                                    .frame(height: elementHeight)
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .rotationEffect(.degrees(liquidRotation), anchor: .bottom)
                    }
                    .frame(width: elementWidth, height: liquidHeight)
                }
            }
            .frame(width: elementWidth, height: containerHeight, alignment: .bottom)
            .clipShape(RoundedRectangle(cornerRadius: elementWidth/2))
            
            // Container image
            Image("test_tube")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: containerWidth, height: containerHeight)
        }
        .rotationEffect(.degrees(pourRotation), anchor: .bottom)
        .offset(position)
        .scaleEffect(viewModel.selectedContainerIndex == index ? 1.1 : 1.0)
//        .overlay(
//            RoundedRectangle(cornerRadius: 100)
//                .stroke(viewModel.selectedContainerIndex == index ? Color.yellow : Color.clear, lineWidth: 3)
//        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedContainerIndex == index)
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
        .zIndex(isPouring ? 1 : 0)  // Ensure pouring container stays on top
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
