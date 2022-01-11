// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/// Show a vertical blue gradient band to indicate the active item in a list.
public class ActiveIndicatorView: UIView {

  /// The class of the layer to create for the background of the view
  override public class var layerClass: AnyClass { CAGradientLayer.self }

  /**
   Layout changed, update the gradient of the background layer.
   */
  override public func layoutSubviews() {
    super.layoutSubviews()
    update()
  }

  /**
   Traits changed, update the gradient of the background layer.

   - parameter previousTraitCollection: previous traits
   */
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
