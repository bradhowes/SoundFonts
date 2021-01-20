// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

public class GradientView: UIView {

    var startColor: UIColor = .black { didSet { updateColors() }}
    var endColor: UIColor = .white { didSet { updateColors() }}

    var startLocation: Double =   0.05 { didSet { updateLocations() }}
    var endLocation: Double =   0.95 { didSet { updateLocations() }}

    var horizontalMode: Bool =  false { didSet { updatePoints() }}
    var diagonalMode: Bool =  false { didSet { updatePoints() }}

    override public class var layerClass: AnyClass { CAGradientLayer.self }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePoints()
        updateLocations()
        updateColors()
    }
}

extension GradientView {

    private func updatePoints() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { fatalError("invalid layer") }
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? .init(x: 1, y: 0) : .init(x: 0, y: 0.5)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 0, y: 1) : .init(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? .init(x: 0, y: 0) : .init(x: 0.5, y: 0)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 1, y: 1) : .init(x: 0.5, y: 1)
        }
    }

    func updateLocations() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { fatalError("invalid layer") }
        gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
    }

    func updateColors() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { fatalError("invalid layer") }
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
}
