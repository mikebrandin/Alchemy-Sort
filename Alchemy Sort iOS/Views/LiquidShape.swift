import SwiftUI

struct LiquidShape: Shape {
    // 0 = no pour (flat top), 1 = fully tilted (curved top)
    var pourProgress: Double

    var animatableData: Double {
        get { pourProgress }
        set { pourProgress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Start at bottom left.
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        // Draw left side upward.
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        // Top edge with a curve that depends on pourProgress.
        // When pourProgress is 0, top is flat; when 1, curve protrudes downward.
        let controlYOffset = rect.height * 0.3 * pourProgress
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                          control: CGPoint(x: rect.midX, y: rect.minY + controlYOffset))
        // Draw right side downward.
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Close the shape.
        path.closeSubpath()
        return path
    }
}
//
//struct LiquidShape_Previews: PreviewProvider {
//    static var previews: some View {
//        LiquidShape(pourProgress: 1)
//            .fill(Color.blue)
//            .frame(width: 50, height: 150)
//    }
//}
