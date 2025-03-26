//
//  ContainerView.swift
//  Alchemy Sort UIKit
//
//

import UIKit

class ContainerView: UIView {
    // Container properties
    private let container: Container
    private let index: Int
    
    // UI Elements
    private let tubeImageView = UIImageView()
    private let liquidView = UIView()
    private let selectionIndicator = UIView()
    
    // Animation properties
    private var originalCenter: CGPoint = .zero
    private var originalTransform: CGAffineTransform = .identity
    private var elementLayers: [CALayer] = []
    
    // Appearance constants
    private let containerWidth: CGFloat = 100
    private let containerHeight: CGFloat = 160
    private let liquidWidth: CGFloat = 34
    private let elementHeight: CGFloat = 25
    
    // Callback for tap events
    var onTap: ((Int) -> Void)?
    
    // MARK: - Initialization
    
    init(container: Container, index: Int) {
        self.container = container
        self.index = index
        super.init(frame: CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setup
    
    private func setupViews() {
        // Configure container view
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        // Configure liquid view (will contain colored elements)
        liquidView.frame = CGRect(x: (containerWidth - liquidWidth) / 2, y: 0, width: liquidWidth, height: containerHeight - 20)
        liquidView.backgroundColor = .clear
        liquidView.clipsToBounds = true
        liquidView.layer.cornerRadius = liquidWidth / 2
        liquidView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] // Round bottom corners only
        addSubview(liquidView)
        
        // Configure tube image view
        tubeImageView.frame = bounds
        tubeImageView.contentMode = .scaleAspectFit
        tubeImageView.image = UIImage(named: "test_tube")
        addSubview(tubeImageView)
        
        // Configure selection indicator
        selectionIndicator.frame = bounds.insetBy(dx: -3, dy: -3)
        selectionIndicator.backgroundColor = .clear
        selectionIndicator.layer.borderWidth = 3
        selectionIndicator.layer.borderColor = UIColor.yellow.cgColor
        selectionIndicator.layer.cornerRadius = 10
        selectionIndicator.isHidden = true
        addSubview(selectionIndicator)
        
        // Initial setup of elements
        updateElements()
        
        // Save original position for animations
        originalCenter = center
        originalTransform = transform
    }
    
    // MARK: - Update Elements
    
    func updateWithContainer(_ container: Container, isSelected: Bool) {
        selectionIndicator.isHidden = !isSelected
        
        // Only update elements if they've changed
        if self.container.elements.count != container.elements.count ||
            !zip(self.container.elements, container.elements).allSatisfy({ $0.0.color.isEqual($0.1.color) }) {
            // Update the container reference
            updateElements(with: container)
        }
    }
    
    private func updateElements(with container: Container? = nil) {
        // Clear existing element layers
        elementLayers.forEach { $0.removeFromSuperlayer() }
        elementLayers.removeAll()
        
        let containerToUse = container ?? self.container
        
        // Calculate space for empty elements
        let filledElementsHeight = CGFloat(containerToUse.elements.count) * elementHeight
        let liquidContainerHeight = containerHeight - 20
        let topSpacerHeight = max(0, liquidContainerHeight - filledElementsHeight)
        
        // Create layers for each element (in reverse order to show from bottom up)
        for (index, element) in containerToUse.elements.reversed().enumerated() {
            let yPosition = topSpacerHeight + CGFloat(index) * elementHeight
            
            let elementLayer = CALayer()
            elementLayer.frame = CGRect(x: 0, 
                                        y: yPosition, 
                                        width: liquidWidth, 
                                        height: elementHeight)
            elementLayer.backgroundColor = element.color.cgColor
            
            liquidView.layer.addSublayer(elementLayer)
            elementLayers.append(elementLayer)
        }
    }
    
    // MARK: - User Interaction
    
    @objc private func handleTap() {
        onTap?(index)
    }
    
    // MARK: - Animations
    
    func animateSelection(isSelected: Bool) {
        UIView.animate(withDuration: 0.3, 
                       delay: 0, 
                       usingSpringWithDamping: 0.7, 
                       initialSpringVelocity: 0.3, 
                       options: [], 
                       animations: {
            self.transform = isSelected ? CGAffineTransform(scaleX: 1.1, y: 1.1) : .identity
            self.selectionIndicator.isHidden = !isSelected
        })
    }
    
    func animatePouringTo(targetView: ContainerView, elementsCount: Int, completion: @escaping () -> Void) {
        // Step 1: Calculate the animation path
        let isLeftOfTarget = center.x < targetView.center.x
        
        // Duration factors based on elements count
        let durationFactor = 0.3 + (Double(elementsCount) * 0.2) // 0.5s for 1, 0.7s for 2, 0.9s for 3
        
        // Float to position near target
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
            // Position near target (above and to side)
            let targetX = isLeftOfTarget ? 
                targetView.center.x - self.containerWidth/2 : 
                targetView.center.x + self.containerWidth/2
            let targetY = targetView.frame.minY - self.containerHeight/2
            
            self.center = CGPoint(x: targetX, y: targetY)
        }, completion: { _ in
            // Rotate to pour
            UIView.animate(withDuration: durationFactor, delay: 0.1, options: .curveEaseInOut, animations: {
                // Rotate left or right based on position
                let rotationAngle = isLeftOfTarget ? CGFloat.pi/2.2 : -CGFloat.pi/2.2
                self.transform = CGAffineTransform(rotationAngle: rotationAngle)
                
                // Shift liquid toward opening
                let shiftX = isLeftOfTarget ? 15 : -15
                self.liquidView.transform = CGAffineTransform(translationX: CGFloat(shiftX), y: -10)
            }, completion: { _ in
                // Animation for elements "flowing" to target would go here
                
                // Return to original rotation
                UIView.animate(withDuration: 0.4, delay: 0.2, options: .curveEaseInOut, animations: {
                    self.transform = .identity
                    self.liquidView.transform = .identity
                }, completion: { _ in
                    // Return to original position
                    UIView.animate(withDuration: 0.5, options: .curveEaseInOut, animations: {
                        self.center = self.originalCenter
                    }, completion: { _ in
                        // Completion callback
                        completion()
                    })
                })
            })
        })
    }
    
    func animateReceivingFrom(sourceView: ContainerView, elementsCount: Int, colors: [UIColor]) {
        // This would be where we animate new elements appearing in the target container
        // For now, we'll just update the view after the model changes
    }
} 