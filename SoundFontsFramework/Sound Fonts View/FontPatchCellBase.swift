// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
public class FontPatchCellBase: UITableViewCell {
    private static let log = Logging.logger("FPCB")
    private var log: OSLog { Self.log }

    /// Unicode character to show when a cell refers to a Patch that is in a Favorite
    private static let goldStarPrefix = "✮"

    public static func favoriteTag(_ isFavorite: Bool) -> String { return isFavorite ? goldStarPrefix + " " : "" }

    internal let selectedIndicator = CAShapeLayer()

    @IBOutlet internal weak var name: UILabel!
    @IBInspectable public var selectedBackgroundColor: UIColor = .darkGray

    private var normalFontColor: UIColor?
    private var shouldAnimate = false

    @IBInspectable public var selectedFontColor: UIColor = .lightGray
    @IBInspectable public var activedFontColor: UIColor = .systemTeal
    @IBInspectable public var favoriteFontColor: UIColor = .systemBlue

    public override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
        normalFontColor = self.name?.textColor
    }

    override public func prepareForReuse() {
        selectedIndicator.opacity = 0.0
    }

    override public func setSelected(_ selected: Bool, animated: Bool) {
        os_log(.info, log: log, "setSelected: '%s' selected: %d animated: %d'", name.text ?? "", selected, animated)
        super.setSelected(selected, animated: animated)
        let targetOpacity: Float = selected ? 1.0 : 0.0
        if targetOpacity != selectedIndicator.opacity {
            if animated {
                let anim = CABasicAnimation(keyPath: "opacity")
                anim.fromValue = selectedIndicator.opacity
                anim.toValue = targetOpacity
                anim.duration = 0.3
                selectedIndicator.add(anim, forKey: nil)
            }
            selectedIndicator.opacity = targetOpacity
        }
    }

    override public func layoutSubviews() {
        makeIndicator()
        super.layoutSubviews()
    }

    internal func fontColorWhen(isSelected: Bool, isActive: Bool, isFavorite: Bool) -> UIColor? {
        if isActive { return activedFontColor }
        if isSelected { return selectedFontColor }
        if isFavorite { return favoriteFontColor }
        return normalFontColor
    }

    private func initialize() {
        selectionStyle = .none
        selectedIndicator.lineWidth = 5.0
        selectedIndicator.backgroundColor = nil
        selectedIndicator.fillColor = nil
        selectedIndicator.isOpaque = false
        selectedIndicator.opacity = 0.0
        selectedIndicator.allowsGroupOpacity = false
        selectedIndicator.allowsEdgeAntialiasing = true
        selectedIndicator.strokeColor = UIColor.systemTeal.cgColor
        selectedIndicator.lineCap = .round
        layer.insertSublayer(selectedIndicator, at: 0)
    }

    private func makeIndicator() {
        selectedIndicator.frame = self.bounds
        let path = CGMutablePath()
        path.move(to: CGPoint(x: bounds.minX + 4, y: bounds.minY + 4))
        path.addLine(to: CGPoint(x: bounds.minX + 4, y: bounds.maxY - 4))
        selectedIndicator.path = path
    }
}

private class BackgroundView: UIView {

    var frameColor: UIColor = .systemTeal

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(frameColor.cgColor)
            context.setLineWidth(2.0)
            context.move(to: CGPoint(x: 4, y: 4))
            context.addLine(to: CGPoint(x: 4, y: bounds.height - 4))
            context.strokePath()
        }
    }
}
