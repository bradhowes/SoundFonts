// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

@IBDesignable public class Knob: UIControl {
    @IBInspectable public var minimumValue: Float = 0.0 { didSet { draw() }}
    @IBInspectable public var maximumValue: Float = 1.0 { didSet { draw() }}
    @IBInspectable public var value: Float = 0.0 {
        didSet {
            value = min(maximumValue, max(minimumValue, value))
            setNeedsLayout()
        }
    }

    @IBInspectable public var baseColor: UIColor = .lightGray { didSet { draw() }}
    @IBInspectable public var pointerColor: UIColor = .lightGray { didSet { draw() }}
    @IBInspectable public var progressColor: UIColor = .systemTeal { didSet { draw() }}
    @IBInspectable public var baseLineWidth: CGFloat = 2 { didSet { draw() }}
    @IBInspectable public var progressLineWidth: CGFloat = 2 { didSet { draw() }}
    @IBInspectable public var pointerLineWidth: CGFloat = 2 { didSet { draw() }}

    public private(set) var baseLayer = CAShapeLayer()
    public private(set) var progressLayer = CAShapeLayer()
    public private(set) var pointerLayer = CAShapeLayer()
    public var startAngle = -CGFloat.pi * 11 / 8.0
    public var endAngle = CGFloat.pi * 3 / 8.0

    private var gestureRecognizer: UIPanGestureRecognizer!
    private var panOrigin: CGPoint = .zero

    // MARK: Init

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    private func initialize() {
        gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(gestureRecognizer)

        baseLayer.fillColor = UIColor.clear.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        pointerLayer.fillColor = UIColor.clear.cgColor

        layer.addSublayer(baseLayer)
        layer.addSublayer(progressLayer)
        layer.addSublayer(pointerLayer)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        draw()
    }

    public func draw() {
        baseLayer.bounds = bounds
        baseLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        progressLayer.bounds = baseLayer.bounds
        progressLayer.position = baseLayer.position
        pointerLayer.bounds = baseLayer.bounds
        pointerLayer.position = baseLayer.position
        baseLayer.lineWidth = baseLineWidth
        progressLayer.lineWidth = progressLineWidth
        pointerLayer.lineWidth = pointerLineWidth
        baseLayer.strokeColor = baseColor.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        pointerLayer.strokeColor = pointerColor.cgColor

        let center = CGPoint(x: baseLayer.bounds.width / 2, y: baseLayer.bounds.height / 2)
        let radius = (min(baseLayer.bounds.width, baseLayer.bounds.height) / 2) - baseLineWidth
        let ring = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        baseLayer.path = ring.cgPath
        baseLayer.lineCap = .round

        let pointer = UIBezierPath()
        pointer.move(to: center)
        pointer.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        pointerLayer.path = pointer.cgPath
        pointerLayer.lineCap = .round

        let angle = CGFloat(angleForValue(value))
        let progressRing = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: angle, clockwise: true)
        progressLayer.path = progressRing.cgPath
        progressLayer.lineCap = .round

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pointerLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
        CATransaction.commit()
    }

    @objc dynamic func handleGesture(_ panner: UIPanGestureRecognizer) {
        if panner.state == .began {
            panOrigin = panner.translation(in: self)
        }
        else {
            let point = panner.translation(in: self)
            let change = Float(point.y - panOrigin.y) / 2.0
            panOrigin = point
            self.value -= change
            sendActions(for: .valueChanged)
        }
    }

    public func angleForValue(_ value: Float) -> CGFloat {
        let angleRange = endAngle - startAngle
        let valueRange = CGFloat(maximumValue - minimumValue)
        return CGFloat(self.value - minimumValue) / valueRange * angleRange + startAngle
    }
}
