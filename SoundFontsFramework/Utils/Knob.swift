// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Custom UIControl that depicts a value as a point on a circle. Changing the value is done by touching on the control and moving up to increase
 and down to decrease the current value. While touching, moving away from the control in either direction will inrease the resolution of the
 touch changes, causing the value to change more slowly as vertical distance changes. Pretty much works like UISlider but with the travel path
 as an arc.

 Visual representation of the knob is done via CoreAnimation components, namely CAShapeLayer and UIBezierPath. The diameter of the arc of the knob is
 defined by the min(width, height) of the view's frame. The start and end of the arc is controlled by the `startAngle` and `endAngle` settings.
 */
@IBDesignable open class Knob: UIControl {

    /// The minimum value reported by the control.
    @IBInspectable open var minimumValue: Float = 0.0 { didSet { clampValue(valueStore) }}
    /// The maximum value reported by the control.
    @IBInspectable open var maximumValue: Float = 1.0 { didSet { clampValue(valueStore) }}
    /// The current value of the control.
    @IBInspectable open var value: Float { get { valueStore } set { clampValue(newValue) } }

    /// How much travel is need to move 4x the width or height of the knob to go from minimumValue to maximumValue. By default this is 4x the knob
    /// size.
    @IBInspectable open var touchSensitivity: Float = 4.0

    /// The width of the arc that is shown after the current value.
    @IBInspectable open var trackLineWidth: CGFloat = 4 {
        didSet {
            trackLayer.lineWidth = trackLineWidth
            draw()
        }
    }

    /// The color of the arc shown after the current value.
    @IBInspectable open var trackColor: UIColor = .darkGray {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
            draw()
        }
    }

    /// The width of the arc from the start up to the current value.
    @IBInspectable open var progressLineWidth: CGFloat = 2 {
        didSet {
            progressLayer.lineWidth = progressLineWidth
            draw()
        }
    }

    /// The color of the arc from the start up to the current value.
    @IBInspectable open var progressColor: UIColor = .systemTeal {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
            draw()
        }
    }

    /// The width of the radial line drawn from the current value on the arc towards the arc center.
    @IBInspectable open var indicatorLineWidth: CGFloat = 2 {
        didSet {
            indicatorLayer.lineWidth = indicatorLineWidth
            draw()
        }
    }

    /// The color of the radial line drawn from the current value on the arc towards the arc center.
    @IBInspectable open var indicatorColor: UIColor = .systemTeal {
        didSet {
            indicatorLayer.strokeColor = indicatorColor.cgColor
            draw()
        }
    }

    /// The proportion of the radial line drawn from the current value on the arc towards the arc center.
    /// Range is from 0.0 to 1.0, where 1.0 will draw a complete line, and anything less will draw that fraction of it
    /// starting from the arc.
    @IBInspectable open var indicatorLineLength: CGFloat = 0.3 { didSet { draw() } }

    /// The starting angle of the arc where a value of 0.0 is located. Arc angles are explained in the UIBezier documentation
    /// for init(arcCenter:radius:startAngle:endAngle:clockwise:). In short, a value of 0.0 will start on the positive X axis,
    /// a positive PI/2 will lie on the negative Y axis. The default values will leave a small gap at the bottom.
    @IBInspectable open var startAngle: CGFloat = -CGFloat.pi * 2.0 * 11 / 16.0 { didSet { draw() } }

    /// The ending angle of the arc where a value of 1.0 is located. See `startAngle` for additional info.
    @IBInspectable open var endAngle: CGFloat = CGFloat.pi * 2.0 * 3.0 / 16.0 { didSet { draw() } }

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let indicatorLayer = CAShapeLayer()

    private var panOrigin: CGPoint = .zero
    private var valueStore: Float = 0.0 { didSet { draw() } }

    /**
     Construction from an encoded representation.

     - parameter aDecoder: the representation to use
     */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    /**
     Construct a new instance with the given location and size. A knob will take the size of the smaller of width and height dimensions
     given in the `frame` parameter.

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
        trackLayer.bounds = bounds
        trackLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        progressLayer.bounds = trackLayer.bounds
        progressLayer.position = trackLayer.position
        indicatorLayer.bounds = trackLayer.bounds
        indicatorLayer.position = trackLayer.position
        draw()
    }
}

extension Knob {

    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        panOrigin = touch.location(in: self)
        sendActions(for: .valueChanged) // Done so we will see the value of the knob when it is first touched.
        return true
    }

    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)

        // Scale touchSensitivity by how far away in the X direction the touch is -- farther away the larger the sensitivity, thus making for smaller value changes.
        let scaleT = log10(max(abs(Float(panOrigin.x - point.x)), 1.0)) + 1
        let deltaT = Float(panOrigin.y - point.y) / (Float(min(bounds.height, bounds.width)) * touchSensitivity * scaleT)
        defer { panOrigin = CGPoint(x: panOrigin.x, y: point.y) }

        self.value += deltaT * (maximumValue - minimumValue)
        sendActions(for: .valueChanged)
        return true
    }

    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        sendActions(for: .valueChanged)
    }
}

extension Knob {

    private func initialize() {
        trackLayer.fillColor = UIColor.clear.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        indicatorLayer.fillColor = UIColor.clear.cgColor

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        layer.addSublayer(indicatorLayer)

        trackLayer.lineWidth = trackLineWidth
        trackLayer.strokeColor = trackColor.cgColor

        progressLayer.lineWidth = progressLineWidth
        progressLayer.strokeColor = progressColor.cgColor

        indicatorLayer.lineWidth = indicatorLineWidth
        indicatorLayer.strokeColor = indicatorColor.cgColor

    }

    private func draw() {
        let center = CGPoint(x: trackLayer.bounds.width / 2, y: trackLayer.bounds.height / 2)
        let radius = (min(trackLayer.bounds.width, trackLayer.bounds.height) / 2) - trackLineWidth
        let ring = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        trackLayer.path = ring.cgPath
        trackLayer.lineCap = .round

        let pointer = UIBezierPath()
        pointer.move(to: CGPoint(x: center.x + radius, y: center.y))
        pointer.addLine(to: CGPoint(x: center.x + radius * (1.0 - indicatorLineLength), y: center.y))
        indicatorLayer.path = pointer.cgPath
        indicatorLayer.lineCap = .round

        let angle = CGFloat(angleForValue(value))
        let progressRing = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: angle, clockwise: true)
        progressLayer.path = progressRing.cgPath
        progressLayer.lineCap = .round

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        indicatorLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
        CATransaction.commit()
    }

    private func angleForValue(_ value: Float) -> CGFloat {
        let angleRange = endAngle - startAngle
        let valueRange = CGFloat(maximumValue - minimumValue)
        return CGFloat(self.value - minimumValue) / valueRange * angleRange + startAngle
    }

    private func clampValue(_ value: Float) {
        valueStore = min(maximumValue, max(minimumValue, value))
    }
}
