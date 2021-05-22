// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

public class ActiveIndicatorView: UIView {

    override public class var layerClass: AnyClass { CAGradientLayer.self }

    override public func layoutSubviews() {
        super.layoutSubviews()
        update()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update()
    }
}

extension ActiveIndicatorView {

    private func update() {
        guard let gradientLayer = self.layer as? CAGradientLayer else { fatalError("invalid layer") }
        let colors: [UIColor] = [.black, .systemTeal, .systemTeal, .black]
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.locations = [0.0, 0.3, 0.6, 1.0]
    }
}
