// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Custom UIControl that depicts a value as a point on a circle. Changing the value is done by touching on the control and moving up to increase
 and down to decrease the current value. While touching, moving away from the control in either direction will inrease the resolution of the
 touch changes, causing the value to change more slowly as vertical distance changes.
 */
@IBDesignable public final class Knob: UIControl {
    static let log = Logging.logger("Knob")
    private lazy var log = Self.log

    @IBInspectable public var minimumValue: Float = 0.0 { didSet { draw() }}
    @IBInspectable public var maximumValue: Float = 1.0 { didSet { draw() }}
    @IBInspectable public var value: Float = 0.0 {
        didSet {
            value = value.clamp(min: minimumValue, max: maximumValue)
            setNeedsLayout()
        }
    }

    /// How much travel is need to move 4x the min(width, height) to go from minimumValue to maximumValue. By default this is 4x the smallest
    /// dimension of the frame.
    @IBInspectable public var scale: Float = 4.0

    @IBInspectable public var trackLineWidth: CGFloat = 4 {
        didSet {
            trackLayer.lineWidth = trackLineWidth
            draw()
        }
    }

    @IBInspectable public var trackColor: UIColor = .darkGray {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
            draw()
        }
    }

    @IBInspectable public var progressLineWidth: CGFloat = 2 {
        didSet {
            progressLayer.lineWidth = progressLineWidth
            draw()
        }
    }

    @IBInspectable public var progressColor: UIColor = .systemTeal {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
            draw()
        }
    }

    @IBInspectable public var indicatorLineWidth: CGFloat = 2 {
        didSet {
            indicatorLayer.lineWidth = indicatorLineWidth
            draw()
        }
    }

    @IBInspectable public var indicatorColor: UIColor = .systemTeal {
        didSet {
            indicatorLayer.strokeColor = indicatorColor.cgColor
            draw()
        }
    }

    @IBInspectable public var indicatorLineLength: CGFloat = 0.3 {
        didSet {
            draw()
        }
    }

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let indicatorLayer = CAShapeLayer()
    private let startAngle = -CGFloat.pi * 2.0 * 11 / 16.0
    private let endAngle = CGFloat.pi * 2.0 * 3.0 / 16.0
    private var panOrigin: CGPoint = .zero

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

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

    @objc dynamic func handleGesture(_ panner: UIPanGestureRecognizer) {
        if panner.state == .began {
            panOrigin = panner.translation(in: self)
        }
        else {
            let point = panner.translation(in: self)

            // Calculate scaling factor to apply to default `scale`. Min value is 1 and it increases logarithmically as X delta grows
            let scaleT = log10(max(abs(Float(panOrigin.x - point.x)), 1.0)) + 1

            let deltaT = Float(panOrigin.y - point.y) / (Float(min(bounds.height, bounds.width)) * scale * scaleT)
            defer { panOrigin = CGPoint(x: panOrigin.x, y: point.y) }
            self.value += deltaT * (maximumValue - minimumValue)
            sendActions(for: .valueChanged)
        }
    }
}

extension Knob {

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else { return }
        guard let touch = touches.first else { return }
        panOrigin = touch.location(in: self)
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else { return }
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let scaleT = log10(max(abs(Float(panOrigin.x - point.x)), 1.0)) + 1
        let deltaT = Float(panOrigin.y - point.y) / (Float(min(bounds.height, bounds.width)) * scale * scaleT)
        defer { panOrigin = CGPoint(x: panOrigin.x, y: point.y) }
        self.value += deltaT * (maximumValue - minimumValue)
        sendActions(for: .valueChanged)
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
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
}
