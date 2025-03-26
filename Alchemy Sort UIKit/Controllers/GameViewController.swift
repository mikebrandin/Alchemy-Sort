//
//  GameViewController.swift
//  Alchemy Sort UIKit
//
//

import UIKit

class GameViewController: UIViewController {
    // Game properties
    private let gameManager = GameManager()
    private var containerViews: [ContainerView] = []
    
    // UI elements
    private let difficultyLabel = UILabel()
    private let scoreLabel = UILabel()
    private let movesLabel = UILabel()
    private let resetButton = UIButton(type: .system)
    private let undoButton = UIButton(type: .system)
    private let completionLabel = UILabel()
    private let gameContainerView = UIView()
    
    // View layout
    private let containerSpacing: CGFloat = 10
    private var columns: Int {
        switch gameManager.currentDifficulty {
        case .tutorial, .easy: return 2
        case .medium, .hard: return 3
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureGameManager()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .black
        
        // Configure difficulty label
        difficultyLabel.font = UIFont.boldSystemFont(ofSize: 24)
        difficultyLabel.textColor = .white
        difficultyLabel.textAlignment = .center
        difficultyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(difficultyLabel)
        
        // Configure score and moves labels
        scoreLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        scoreLabel.textColor = .white
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)
        
        movesLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        movesLabel.textColor = .white
        movesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(movesLabel)
        
        // Configure buttons
        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        resetButton.backgroundColor = UIColor.systemBlue
        resetButton.layer.cornerRadius = 8
        resetButton.tintColor = .white
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        view.addSubview(resetButton)
        
        undoButton.setTitle("Undo", for: .normal)
        undoButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        undoButton.backgroundColor = UIColor.systemBlue
        undoButton.layer.cornerRadius = 8
        undoButton.tintColor = .white
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        undoButton.isEnabled = false
        view.addSubview(undoButton)
        
        // Configure completion label
        completionLabel.text = "Level Complete!"
        completionLabel.font = UIFont.boldSystemFont(ofSize: 24)
        completionLabel.textColor = .green
        completionLabel.textAlignment = .center
        completionLabel.isHidden = true
        completionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(completionLabel)
        
        // Configure game container view
        gameContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gameContainerView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Difficulty label
            difficultyLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            difficultyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Score and moves
            scoreLabel.topAnchor.constraint(equalTo: difficultyLabel.bottomAnchor, constant: 10),
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -70),
            
            movesLabel.topAnchor.constraint(equalTo: difficultyLabel.bottomAnchor, constant: 10),
            movesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 70),
            
            // Reset button (top right)
            resetButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            resetButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalToConstant: 80),
            resetButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Undo button (bottom left)
            undoButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            undoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            undoButton.widthAnchor.constraint(equalToConstant: 80),
            undoButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Game container
            gameContainerView.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 20),
            gameContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            gameContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            gameContainerView.bottomAnchor.constraint(equalTo: undoButton.topAnchor, constant: -20),
            
            // Completion label
            completionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            completionLabel.bottomAnchor.constraint(equalTo: undoButton.topAnchor, constant: -20)
        ])
        
        // Add tap gesture to background for deselecting
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func configureGameManager() {
        gameManager.delegate = self
        updateUI()
    }
    
    // MARK: - Game Container Setup
    
    private func setupContainerViews() {
        // Remove existing container views
        containerViews.forEach { $0.removeFromSuperview() }
        containerViews.removeAll()
        
        // Create container views based on difficulty
        let containers = gameManager.containers
        for (index, container) in containers.enumerated() {
            let containerView = ContainerView(container: container, index: index)
            containerView.onTap = { [weak self] index in
                self?.gameManager.handleContainerTap(at: index)
            }
            containerViews.append(containerView)
            gameContainerView.addSubview(containerView)
        }
        
        layoutContainerViews()
    }
    
    private func layoutContainerViews() {
        let containerWidth: CGFloat = 100
        let containerHeight: CGFloat = 160
        
        // Calculate layout based on grid arrangement
        let horizontalSpacing: CGFloat = 10
        let verticalSpacing: CGFloat = 20
        
        let availableWidth = gameContainerView.bounds.width
        let totalWidth = CGFloat(columns) * containerWidth + CGFloat(columns - 1) * horizontalSpacing
        let horizontalPadding = max(0, (availableWidth - totalWidth) / 2)
        
        for (index, containerView) in containerViews.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let x = horizontalPadding + CGFloat(col) * (containerWidth + horizontalSpacing)
            let y = CGFloat(row) * (containerHeight + verticalSpacing)
            
            containerView.frame = CGRect(x: x, y: y, width: containerWidth, height: containerHeight)
        }
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        // Update labels
        difficultyLabel.text = gameManager.currentDifficulty.rawValue.capitalized
        scoreLabel.text = "Score: \(gameManager.score)"
        movesLabel.text = "Moves: \(gameManager.moves)"
        
        // Update buttons
        undoButton.isEnabled = gameManager.canUndo
        
        // Update completion status
        completionLabel.isHidden = !gameManager.isLevelComplete
        
        // Update container views
        if containerViews.isEmpty {
            setupContainerViews()
        } else {
            for (index, containerView) in containerViews.enumerated() {
                let isSelected = gameManager.selectedContainerIndex == index
                containerView.updateWithContainer(gameManager.containers[index], isSelected: isSelected)
                
                // Update selection animation
                containerView.animateSelection(isSelected: isSelected)
            }
        }
    }
    
    // MARK: - Animation
    
    private func animatePour(from sourceIndex: Int, to targetIndex: Int) {
        guard sourceIndex < containerViews.count, targetIndex < containerViews.count else { return }
        
        let sourceView = containerViews[sourceIndex]
        let targetView = containerViews[targetIndex]
        
        // Get elements count to pour
        let elementsCount = gameManager.getPourCount(from: sourceIndex, to: targetIndex)
        
        // Animate source container pouring
        sourceView.animatePouringTo(targetView: targetView, elementsCount: elementsCount) { [weak self] in
            // Animation is complete, update UI
            self?.updateUI()
        }
    }
    
    // MARK: - User Interaction
    
    @objc private func resetButtonTapped() {
        gameManager.resetLevel()
    }
    
    @objc private func undoButtonTapped() {
        gameManager.undo()
    }
    
    @objc private func handleBackgroundTap(gesture: UITapGestureRecognizer) {
        // Check if tap was outside container views
        let location = gesture.location(in: view)
        let hitView = view.hitTest(location, with: nil)
        
        // If not tapping on a container view, clear selection
        if !containerViews.contains(where: { $0.frame.contains(location) }) {
            gameManager.selectedContainerIndex = nil
            updateUI()
        }
    }
    
    // MARK: - Device Orientation
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { _ in
            // Update layout when device rotates
            self.layoutContainerViews()
        }
    }
}

// MARK: - GameManagerDelegate

extension GameViewController: GameManagerDelegate {
    func gameStateDidChange() {
        updateUI()
    }
    
    func containersPoured(from sourceIndex: Int, to targetIndex: Int) {
        animatePour(from: sourceIndex, to: targetIndex)
    }
    
    func levelCompleted() {
        // Show completion animation
        completionLabel.alpha = 0
        completionLabel.isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            self.completionLabel.alpha = 1
        }
    }
    
    func scoreDidChange(to newScore: Int) {
        scoreLabel.text = "Score: \(newScore)"
    }
    
    func movesDidChange(to newMoves: Int) {
        movesLabel.text = "Moves: \(newMoves)"
    }
} 