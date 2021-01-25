// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Custom UIControl that depicts a value as a point on a circle. Changing the value is done by touching on the control
 and moving up to increase
 and down to decrease the current value. While touching, moving away from the control in either direction will increase
 the resolution of the
 touch changes, causing the value to change more slowly as vertical distance changes. Pretty much works like UISlider
 but with the travel path
 as an arc.

 Visual representation of the knob is done via CoreAnimation components, namely CAShapeLayer and UIBezierPath. The
 diameter of the arc of the knob is
 defined by the min(width, height) of the view's frame. The start and end of the arc is controlled by the `startAngle`
 and `endAngle` settings.
 */
open class Knob: UIControl {

    /// The minimum value reported by the control.
    open var minimumValue: Float = 0.0 { didSet { setValue(clampedValue(value), animated: false) } }

    /// The maximum value reported by the control.
    open var maximumValue: Float = 1.0 { didSet { setValue(clampedValue(value), animated: false) } }

    /// The current value of the control.
    open var value: Float { get { _value } set { setValue(clampedValue(newValue), animated: false) } }

    /// How much travel is need to move 4x the width or height of the knob to go from minimumValue to maximumValue. By
    /// default this is 4x the knob size.
    open var touchSensitivity: Float = 4.0

    /// The width of the arc that is shown after the current value.
    open var trackLineWidth: CGFloat = 3 { didSet { trackLayer.lineWidth = trackLineWidth } }

    /// The color of the arc shown after the current value.
    open var trackColor: UIColor = .darkGray { didSet { trackLayer.strokeColor = trackColor.cgColor } }

    /// The width of the arc from the start up to the current value.
    open var progressLineWidth: CGFloat = 5 { didSet { progressLayer.lineWidth = progressLineWidth } }

    /// The color of the arc from the start up to the current value.
    open var progressColor: UIColor = .systemTeal { didSet { progressLayer.strokeColor = progressColor.cgColor } }

    /// The width of the radial line drawn from the current value on the arc towards the arc center.
    open var indicatorLineWidth: CGFloat = 5 { didSet { indicatorLayer.lineWidth = indicatorLineWidth } }

    /// The color of the radial line drawn from the current value on the arc towards the arc center.
    open var indicatorColor: UIColor = .systemTeal { didSet { indicatorLayer.strokeColor = indicatorColor.cgColor } }

    /// The proportion of the radial line drawn from the current value on the arc towards the arc center.
    /// Range is from 0.0 to 1.0, where 1.0 will draw a complete line, and anything less will draw that fraction of it
    /// starting from the arc.
    open var indicatorLineLength: CGFloat = 0.3 { didSet { createShapes() } }

    /// The width of the radial line drawn from the current value on the arc to the arc center.
    open var radialLineWidth: CGFloat = 1 { didSet { radialLayer.lineWidth = radialLineWidth } }

    /// The color of the radial line drawn from the current value on the arc towards the arc center.
    open var radialLineColor: UIColor = .systemTeal { didSet { radialLayer.strokeColor = radialLineColor.cgColor } }

    /// The proportion of the radial line drawn from the current value on the arc towards the arc center.
    /// Range is from 0.0 to 1.0, where 1.0 will draw a complete line, and anything less will draw that fraction of it
    /// starting from the arc.
    open var radialLineLength: CGFloat = 0.1 { didSet { createShapes() } }

    /// Number of ticks to show inside the track, with the first indicating the `minimumValue` and the last indicating
    /// the `maximumValue`
    open var tickCount: Int = 0 { didSet { createShapes() } }

    /// Length of the tick. Range is from 0.0 to 1.0 where 1.0 will draw a line ending at the center of the knob.
    open var tickLineLength: CGFloat = 0.2 { didSet { createShapes() } }

    /// The width of the tick line.
    open var tickLineWidth: CGFloat = 1.0 { didSet { ticksLayer.lineWidth = tickLineWidth } }

    /// The color of the tick line.
    open var tickLineColor: UIColor = .systemTeal { didSet { ticksLayer.strokeColor = tickLineColor.cgColor } }

    /// The starting angle of the arc where a value of 0.0 is located. Arc angles are explained in the UIBezier
    /// documentation
    /// for init(arcCenter:radius:startAngle:endAngle:clockwise:). In short, a value of 0.0 will start on the positive
    ///  X axis,
    /// a positive PI/2 will lie on the negative Y axis. The default values will leave a small gap at the bottom.
    open var startAngle: Float = -Float.pi * 2.0 * 11 / 16.0 { didSet { createShapes() } }

    /// The ending angle of the arc where a value of 1.0 is located. See `startAngle` for additional info.
    open var endAngle: Float = Float.pi * 2.0 * 3.0 / 16.0 { didSet { createShapes() } }

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let radialLayer = CAShapeLayer()
    private let indicatorLayer = CAShapeLayer()
    private let ticksLayer = CAShapeLayer()

    private var _value: Float = 0.0
    private var panOrigin: CGPoint = .zero
    private var activeTouch: Bool = false

    /**
     Construction from an encoded representation.

     - parameter aDecoder: the representation to use
     */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    /**
     Construct a new instance with the given location and size. A knob will take the size of the smaller of width and
     height dimensions
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

        // To make future calculations easier, configure the layers so that (0, 0) is their center
        let layerBounds = bounds.offsetBy(dx: -bounds.midX, dy: -bounds.midY)
        let layerCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        for layer in [trackLayer, progressLayer, radialLayer, indicatorLayer, ticksLayer] {
            layer.bounds = layerBounds
            layer.position = layerCenter
        }
        createShapes()
    }

    public func setValue(_ value: Float, animated: Bool = false) {
        let lastValue = _value
        _value = clampedValue(value)
        draw(previousValue: lastValue, animated: animated)
    }
}

extension Knob {

    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        panOrigin = touch.location(in: self)
        activeTouch = true
        sendActions(for: .valueChanged)
        return true
    }

    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let point = touch.location(in: self)

        // Scale touchSensitivity by how far away in the X direction the touch is -- farther away the larger the
        // sensitivity, thus making for smaller value changes for the same
        // distance traveled in the Y direction.
        let scaleT = log10(max(abs(Float(panOrigin.x - point.x)), 1.0)) + 1
        let deltaT = Float(panOrigin.y - point.y) / (Float(min(bounds.height, bounds.width)) * touchSensitivity *
                                                        scaleT)
        defer { panOrigin = CGPoint(x: panOrigin.x, y: point.y) }
        let change = deltaT * (maximumValue - minimumValue)
        self.value += change
        sendActions(for: .valueChanged)
        return true
    }

    override open func cancelTracking(with event: UIEvent?) {
        activeTouch = false
        super.cancelTracking(with: event)
        self.sendActions(for: .valueChanged)
    }

    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        activeTouch = false
        super.endTracking(touch, with: event)
        sendActions(for: .valueChanged)
    }
}

extension Knob {

    private func initialize() {
        trackLayer.fillColor = UIColor.clear.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        radialLayer.fillColor = UIColor.clear.cgColor
        indicatorLayer.fillColor = UIColor.clear.cgColor
        ticksLayer.fillColor = UIColor.clear.cgColor

        layer.addSublayer(ticksLayer)
        layer.addSublayer(trackLayer)
        layer.addSublayer(radialLayer)
        layer.addSublayer(indicatorLayer)
        layer.addSublayer(progressLayer)

        trackLayer.lineWidth = trackLineWidth
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineCap = .round
        trackLayer.drawsAsynchronously = true

        progressLayer.lineWidth = progressLineWidth
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeStart = 0.0
        progressLayer.strokeEnd = 0.0
        progressLayer.drawsAsynchronously = true

        indicatorLayer.lineWidth = indicatorLineWidth
        indicatorLayer.strokeColor = indicatorColor.cgColor
        indicatorLayer.lineCap = .round
        indicatorLayer.drawsAsynchronously = true

        radialLayer.lineWidth = radialLineWidth
        radialLayer.strokeColor = radialLineColor.cgColor
        radialLayer.lineCap = .round
        radialLayer.drawsAsynchronously = true

        ticksLayer.lineWidth = tickLineWidth
        ticksLayer.strokeColor = tickLineColor.cgColor
        ticksLayer.lineCap = .round
        ticksLayer.drawsAsynchronously = true
    }

    private func createShapes() {
        createTrack()
        createTicks()
        createRadial()
        createIndicator()
        createProgressTrack()
        draw(previousValue: _value, animated: false)
    }

    private func createTrack() {
        let ring = UIBezierPath(arcCenter: CGPoint.zero, radius: radius, startAngle: CGFloat(startAngle),
                                endAngle: CGFloat(endAngle), clockwise: true)
        trackLayer.path = ring.cgPath
        trackLayer.shadowPath = ring.cgPath
    }

    private func createRadial() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: radius, y: 0.0))
        path.addLine(to: CGPoint(x: radius * (1.0 - radialLineLength), y: 0.0))
        radialLayer.path = path.cgPath
        radialLayer.shadowPath = path.cgPath
    }

    private func createIndicator() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: radius, y: 0.0))
        path.addLine(to: CGPoint(x: radius * (1.0 - indicatorLineLength), y: 0.0))
        indicatorLayer.path = path.cgPath
        indicatorLayer.shadowPath = path.cgPath
    }

    private func createProgressTrack() {
        let path = UIBezierPath(arcCenter: CGPoint.zero, radius: radius, startAngle: CGFloat(startAngle),
                                endAngle: CGFloat(endAngle), clockwise: true)
        progressLayer.path = path.cgPath
        progressLayer.shadowPath = path.cgPath
   }

    private func createTicks() {
        let ticks = UIBezierPath()
        for tickIndex in 0..<tickCount {
            let path = UIBezierPath()
            let theta = CGFloat(angle(for: Float(tickIndex) / max(1.0, Float(tickCount - 1))))
            path.move(to: CGPoint(x: 0.0 + radius, y: 0.0))
            path.addLine(to: CGPoint(x: 0.0 + radius * (1.0 - tickLineLength), y: 0.0))
            path.apply(CGAffineTransform(rotationAngle: theta))
            ticks.append(path)
        }
        ticksLayer.path = ticks.cgPath
        ticksLayer.shadowPath = ticks.cgPath
    }

    private func draw(previousValue: Float, animated: Bool = false) {
        let endAngle = angleForValue
        let endStrokeEnd = CGFloat((value - minimumValue) / (maximumValue - minimumValue))
        let transform = CATransform3DMakeRotation(CGFloat(endAngle), 0, 0, 1)

        if !animated || activeTouch {
            CATransaction.setDisableActions(true)
            self.indicatorLayer.transform = transform
            self.radialLayer.transform = transform
            self.progressLayer.strokeEnd = endStrokeEnd
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        radialLayer.transform = transform
        indicatorLayer.transform = transform
        CATransaction.commit()

        CATransaction.begin()
        progressLayer.strokeEnd = endStrokeEnd
        CATransaction.commit()
    }

    private var radius: CGFloat { (min(trackLayer.bounds.width, trackLayer.bounds.height) / 2) - trackLineWidth }

    private var angleForValue: Float { angle(for: (_value - minimumValue) / (maximumValue - minimumValue)) }

    private func angle(for normalizedValue: Float) -> Float { normalizedValue * (endAngle - startAngle) + startAngle }

    private func clampedValue(_ value: Float) -> Float { min(maximumValue, max(minimumValue, value)) }
}
