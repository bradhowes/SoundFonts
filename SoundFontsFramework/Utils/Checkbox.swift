// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Custom UIControl that shows a traditional checkbox. Touching the box toggles the value. Note that
 iOS 14 now has its own variation of this via UISwitch and its checkbox style.
 */
open class Checkbox: UIControl {

    /// The current value of the control.
    open var isChecked: Bool { get { _value } set { setChecked(newValue, animated: false) } }

    /// The width of the border.
    open var borderLineWidth: CGFloat = 3 { didSet { borderLayer.lineWidth = borderLineWidth } }

    /// The shapes supported for a border.
    public enum BorderShape: Int {
        case square
        case circle
    }

    /// The shape of the border.
    open var borderShape: BorderShape = .square { didSet { createBorder() } }
    open var borderShapeIB: Int {
        get { borderShape.rawValue }
        set { borderShape = BorderShape(rawValue: newValue)! }
    }

    /// The color of the border when in the unchecked state
    open var uncheckedBorderColor: UIColor = .darkGray { didSet { draw() } }

    /// The color of the border when in the checked state
    open var checkedBorderColor: UIColor = .darkGray { didSet { draw() } }

    /// The shapes supported for the checked indicator.
    public enum CheckShape: Int {
        case square
        case circle
        case check
        case cross
    }

    /// The shape of the checked indicator.
    open var checkShape: CheckShape = .check { didSet { createCheck() } }
    open var checkShapeIB: Int {
        get { checkShape.rawValue }
        set { checkShape = CheckShape(rawValue: newValue)! }
    }

    /// The stroke width used for checked indicators with lines.
    open var checkLineWidth: CGFloat = 4 { didSet { checkLayer.lineWidth = checkLineWidth } }

    /// Insets applied to the border frame to get the checked indicator frame.
    open var checkInsets: UIEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7) { didSet { createCheck() } }
    open var checkInset: Float {
        get { Float(checkInsets.top) }
        set { checkInsets = UIEdgeInsets(top: CGFloat(newValue), left: CGFloat(newValue), bottom: CGFloat(newValue),
                                         right: CGFloat(newValue)) }
    }

    private let borderLayer = CAShapeLayer()
    private let checkLayer = CAShapeLayer()
    private var _value: Bool = false
    private let updateQueue = DispatchQueue(label: "Checkbox", qos: .userInteractive, attributes: [],
                                            autoreleaseFrequency: .inherit, target: .main)

    /**
     Construction from an encoded representation.

     - paramameter aDecoder: the representation to use
     */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    /**
     Construct a new instance with the given location and size.

     - parameter frame: geometry of the new knob
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    /**
     Reposition layers to reflect new size.
     */
    public override func layoutSubviews() {
        super.layoutSubviews()

        // To make future calculations easier, configure the layers so that (0, 0) is their center
        let layerBounds = bounds.offsetBy(dx: -bounds.midX, dy: -bounds.midY)
        let layerCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        for layer in [borderLayer, checkLayer] {
            layer.bounds = layerBounds
            layer.position = layerCenter
        }
        createShapes()
    }

    /**
     Change the state of the control.

     - parameter checked: the new checked value
     - parameter animated: if true animate the button to the new state
     */
    open func setChecked(_ checked: Bool, animated: Bool) {
        _value = checked
        draw(animated: animated)
    }
}

extension Checkbox {

    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)
        return bounds.contains(point)
    }

    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true
    }

    override open func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
    }

    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        guard let touch = touch else { return }
        let point = touch.location(in: self)
        if bounds.contains(point) {
            setChecked(!_value, animated: true)
            updateQueue.async { self.sendActions(for: .valueChanged) }
        }
    }
}

extension Checkbox {

    private func initialize() {
        borderLayer.fillColor = UIColor.clear.cgColor
        checkLayer.fillColor = UIColor.clear.cgColor

        layer.addSublayer(borderLayer)
        layer.addSublayer(checkLayer)

        borderLayer.lineWidth = borderLineWidth
        borderLayer.strokeColor = uncheckedBorderColor.cgColor
        borderLayer.lineCap = .round

        checkLayer.lineWidth = checkLineWidth
        checkLayer.strokeColor = tintColor.cgColor
        checkLayer.lineCap = .round
    }

    private func createShapes() {
        createBorder()
        createCheck()
        draw(animated: false)
    }

    private func createBorder() {
        let frame = borderLayer.bounds.insetBy(dx: borderLineWidth / 2, dy: borderLineWidth / 2)
        let path = borderShape == .circle ? UIBezierPath(ovalIn: frame) : UIBezierPath(rect: frame)
        borderLayer.path = path.cgPath
    }

    private func createCheck() {
        let frame = checkLayer.bounds.insetBy(dx: borderLineWidth / 2, dy: borderLineWidth / 2).inset(by: checkInsets)
        switch checkShape {
        case .square:
            checkLayer.path = UIBezierPath(rect: frame).cgPath
            checkLayer.fillColor = tintColor.cgColor

        case .circle:
            checkLayer.path = UIBezierPath(ovalIn: frame).cgPath
            checkLayer.fillColor = tintColor.cgColor

        case .check:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: frame.minX, y: 0.25 * frame.maxY))
            path.addLine(to: CGPoint(x: 0, y: frame.maxY))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
            checkLayer.path = path.cgPath
            checkLayer.fillColor = UIColor.clear.cgColor

        case .cross:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: frame.minX, y: frame.minY))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
            path.move(to: CGPoint(x: frame.maxX, y: frame.minY))
            path.addLine(to: CGPoint(x: frame.minX, y: frame.maxY))
            checkLayer.path = path.cgPath
            checkLayer.fillColor = UIColor.clear.cgColor
        }
    }

    private func draw(animated: Bool = false) {
        if !animated { CATransaction.setDisableActions(true) }
        borderLayer.strokeColor = _value ? checkedBorderColor.cgColor : uncheckedBorderColor.cgColor
        checkLayer.isHidden = !_value
    }

    private var radius: CGFloat { (min(bounds.width, bounds.height) / 2) - borderLineWidth }
}
