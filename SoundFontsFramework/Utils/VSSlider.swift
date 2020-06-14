//
// VSSlider.swift
// VerticalSteppedSlider
//
// Created by Melissa Ludowise on 8/24/17.
// Copyright © 2017 Mel Ludowise. All rights reserved.
// (https://github.com/mludowise/VerticalSteppedSlider)
//
// Modifications: Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

@IBDesignable
public class VSSlider: UIControl {

    class InternalSlider: UISlider {

        init() {
            super.init(frame: CGRect.zero)
            self.frame.size = self.intrinsicContentSize
            initialize()
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            initialize()
        }

        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            initialize()
        }

        private func initialize() {
            addTarget(self, action: #selector(endSliding), for: .touchUpInside)
            // addTarget(self, action: #selector(endSliding), for: .touchUpOutside)
        }

        @objc private func endSliding() {
            sendActions(for: .valueChanged)
        }
    }

    private let slider = InternalSlider()

    @IBInspectable
    public var vertical: Bool = true { didSet { updateSlider() } }

    // Ascending is defined as:
    // - Min on the left and max on the right when horizontal in left-to-right localized layouts.
    // - Min on the right and max on the left when horizontal in right-to-left localized layouts.
    // - Min on top and max on the bottom when vertical
    // Default is false
    @IBInspectable
    public var ascending: Bool = false { didSet { updateSlider() } }

    @IBInspectable
    public var value: Float {
        get { slider.value }
        set {
            slider.setValue(newValue, animated: true)
            updateSlider()
        }
    }

    @IBInspectable
    public var minimumValue: Float {
        get { slider.minimumValue }
        set {
            slider.minimumValue = newValue
            updateSlider()
        }
    }

    @IBInspectable
    public var maximumValue: Float {
        get { slider.maximumValue }
        set {
            slider.maximumValue = newValue
            updateSlider()
        }
    }

    @IBInspectable
    public var increment: Float = 0.5 { didSet { updateSlider() } }

    @IBInspectable
    public var trackWidth: CGFloat = 2 { didSet { updateSlider() } }

    @IBInspectable
    public var markWidth: CGFloat = 1 { didSet { updateSlider() } }

    @IBInspectable
    public var markColor: UIColor = UIColor.darkGray { didSet { updateSlider() } }

    @IBInspectable
    public var minimumTrackTintColor: UIColor? { didSet { updateSlider() } }

    @IBInspectable public var maximumTrackTintColor: UIColor? { didSet { updateSlider() } }

    @IBInspectable
    public var thumbTintColor: UIColor? { didSet { updateSlider() } }

    @IBInspectable
    public var minimumTrackImage: UIImage? { didSet { updateSlider() } }

    @IBInspectable
    public var maximumTrackImage: UIImage? { didSet { updateSlider() } }

    @IBInspectable
    public var thumbImage: UIImage? { didSet { updateSlider() } }

    @IBInspectable
    public var trackExtendsUnderThumb: Bool = true { didSet { updateSlider() } }

    @IBInspectable
    public var isContinuous: Bool = true { didSet { updateSlider() } }

    override public var isEnabled: Bool {
        didSet {
            super.isEnabled = self.isEnabled
            updateSlider(animated: true)
        }
    }

    override public var tag: Int {
        get { slider.tag }
        set { slider.tag = newValue }
    }

    @available(iOS 9.0, *)
    public override var semanticContentAttribute: UISemanticContentAttribute {
        set {
            super.semanticContentAttribute = newValue
            slider.semanticContentAttribute = newValue
            updateSlider()
        }
        get {
            return super.semanticContentAttribute
        }
    }

    private var lastDrawnSliderSize = CGSize.zero

    private var markRange: [Float] {
        return increment > 0 ? Array(stride(from: minimumValue + increment, to: maximumValue, by: increment)) : []
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    required override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    private func initialize() {
        updateSlider()
        addSubview(slider)
    }

    private func updateSlider(animated: Bool = false) {
        let layoutDirection = slider.effectiveUserInterfaceLayoutDirection

        switch (vertical, ascending, layoutDirection) {
        case (true, false, .leftToRight),
             (true, true, .rightToLeft):
            slider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi) * -0.5)
        case (true, true, .leftToRight),
             (true, false, .rightToLeft):
            slider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi) * 0.5).scaledBy(x: 1, y: -1)
        case (false, true, _):
            slider.transform = CGAffineTransform(scaleX: 1, y: -1)
        case (false, false, _):
            slider.transform = .identity
        case (true, _, _):
            assertionFailure("unexpected case")
        }

        slider.minimumValue = minimumValue
        slider.maximumValue = maximumValue
        slider.isContinuous = isContinuous

        if let thumbImage = thumbImage {
            slider.setThumbImage(thumbImage, for: .normal)
        } else if let thumbTintColor = thumbTintColor {
            let color = isEnabled ? thumbTintColor : UIColor.gray
            if animated {
                UIView.animate(withDuration: 0.5) {
                    self.slider.thumbTintColor = color
                }
            } else {
                self.slider.thumbTintColor = color
            }
        }

        updateTrackImage(animated: animated)
    }

    public func setValue(_ value: Float, animated: Bool) {
        slider.setValue(value, animated: animated)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        slider.transform = .identity
        if vertical {
            slider.bounds.size.width = bounds.height
        } else {
            slider.bounds.size.width = bounds.width
        }

        slider.center = CGPoint(x: bounds.midX, y: bounds.midY)
        updateSlider()
    }

    override public var intrinsicContentSize: CGSize {
        get {
            if vertical {
                return CGSize(width: slider.intrinsicContentSize.height, height: slider.intrinsicContentSize.width)
            } else {
                return slider.intrinsicContentSize
            }
        }
    }

    override public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        slider.addTarget(target, action: action, for: controlEvents)
    }

    public override func draw(_ rect: CGRect) {
        updateTrackImage(animated: false)
        super.draw(rect)
    }
}

// MARK: - Drawing methods

extension VSSlider {

    private func updateTrackImage(animated: Bool) {

        // Get slider dimensions
        let sliderBounds = slider.bounds
        let trackBounds = slider.trackRect(forBounds: sliderBounds)
        let thumbWidth = slider.thumbRect(forBounds: sliderBounds, trackRect: trackBounds, value: 0).size.width

        // We create an innerRect in which we paint the lines
        let innerRect = sliderBounds.insetBy(dx: 1.0, dy: (sliderBounds.height - trackWidth) / 2)

        // Get the range for drawing marks
        let range = markRange

        var minTrackColor = minimumTrackTintColor ?? tintColor ?? UIColor.blue
        if !isEnabled {
            minTrackColor = minTrackColor.darker()
        }

        var maxTrackColor = maximumTrackTintColor ?? UIColor.lightGray
        if !isEnabled {
            maxTrackColor = maxTrackColor.darker()
        }

        if let minimumSide = getTrackImage(innerRect: innerRect, thumbWidth: thumbWidth, range: range,
                                           trackColor: minTrackColor, trackImage: minimumTrackImage) {
            if animated {
                UIView.animate(withDuration: 0.5) {
                    self.slider.setMinimumTrackImage(minimumSide, for: .normal)
                }
            }
            else {
                self.slider.setMinimumTrackImage(minimumSide, for: .normal)
            }
        }
        if let maximumSide = getTrackImage(innerRect: innerRect, thumbWidth: thumbWidth, range: range,
                                           trackColor: maxTrackColor, trackImage: maximumTrackImage) {
            if animated {
                UIView.animate(withDuration: 0.5) {
                    self.slider.setMaximumTrackImage(maximumSide, for: .normal)
                }
            }
            else {
                self.slider.setMaximumTrackImage(maximumSide, for: .normal)
            }
        }
    }

    private func getTrackImage(innerRect: CGRect, thumbWidth: CGFloat, range: [Float], trackColor: UIColor,
                               trackImage: UIImage?) -> UIImage? {
        UIGraphicsBeginImageContext(innerRect.size)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        let endOffset = trackExtendsUnderThumb ? 0 : thumbWidth

        var image: UIImage
        if let trackImage = trackImage {
            trackImage.draw(in: CGRect(x: endOffset / 2, y: (innerRect.height - trackWidth) / 2,
                                       width: innerRect.width - endOffset, height: trackWidth))
            image = UIGraphicsGetImageFromCurrentImageContext()!.resizableImage(withCapInsets: UIEdgeInsets.zero)
        } else {
            context.setLineCap(.round)
            context.setLineWidth(trackWidth)
            context.move(to: CGPoint(x: (trackWidth + endOffset) / 2, y: innerRect.height / 2))
            context.addLine(to: CGPoint(x: innerRect.size.width - (trackWidth + endOffset) / 2 - 2,
                                        y: innerRect.height / 2))
            context.setStrokeColor(trackColor.cgColor)
            context.strokePath()
            image = UIGraphicsGetImageFromCurrentImageContext()!.resizableImage(withCapInsets: UIEdgeInsets.zero)
        }

        image.draw(at: CGPoint.zero)
        for value in range {
            let position = CGFloat((value - minimumValue) / (maximumValue - minimumValue)) *
                (innerRect.width - thumbWidth) + thumbWidth / 2
            context.setLineCap(.butt)
            context.setLineWidth(markWidth)
            context.move(to: CGPoint(x: position, y: innerRect.height / 2 - trackWidth / 2))
            context.addLine(to: CGPoint(x: position, y: innerRect.height / 2 + trackWidth / 2))
            context.setStrokeColor(markColor.cgColor)
            context.strokePath()
        }
        image = UIGraphicsGetImageFromCurrentImageContext()!.resizableImage(withCapInsets: UIEdgeInsets.zero)

        UIGraphicsEndImageContext()

        return image
    }
}

extension VSSlider {

    public func addTapGesture() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: self)
        let value: Float = vertical ? minimumValue + Float((bounds.height - location.y) / bounds.height) * maximumValue
            : minimumValue + Float(location.x / bounds.width) * maximumValue
        slider.setValue(value, animated: true)
        slider.sendActions(for: .valueChanged)
    }
}
