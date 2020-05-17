// Copyright © 2020 Brad Howes. All rights reserved.
//

import UIKit

/// A click and draggable view of an ADSR Envelope (Atttack, Decay, Sustain, Release)
@IBDesignable public class ADSRView_AudioKit: UIView {

    /// Type of function to call when values of the ADSR have changed
    public typealias ADSRCallback = (Double, Double, Double, Double) -> Void

    /// Attack duration in seconds, Default: 0.1
    @IBInspectable public var attackDuration: Double = 0.100

    /// Decay duration in seconds, Default: 0.1
    @IBInspectable public var decayDuration: Double = 0.100

    /// Sustain Level (0-1), Default: 0.5
    @IBInspectable public var sustainLevel: Double = 0.50

    /// Release duration in seconds, Default: 0.1
    @IBInspectable public var releaseDuration: Double = 0.100

    /// Attack duration in milliseconds
    var attackTime: CGFloat {
        get { CGFloat(attackDuration * 1_000.0) }
        set { attackDuration = Double(newValue / 1_000.0) }
    }

    /// Decay duration in milliseconds
    var decayTime: CGFloat {
        get { CGFloat(decayDuration * 1_000.0) }
        set { decayDuration = Double(newValue / 1_000.0) }
    }

    /// Sustain level as a percentage 0% - 100%
    var sustainPercent: CGFloat {
        get { CGFloat(sustainLevel * 100.0) }
        set { sustainLevel = Double(newValue / 100.0) }
    }

    /// Release duration in milliseconds
    var releaseTime: CGFloat {
        get { CGFloat(releaseDuration * 1_000.0) }
        set { releaseDuration = Double(newValue / 1_000.0) }
    }

    /// Function to call when the values of the ADSR changes
    public var callback: ADSRCallback?

    private enum DragArea: Int {
        case attack
        case decaySustain
        case release
        case none = -1
    }

    private var touchAreas = [UIBezierPath(), UIBezierPath(), UIBezierPath()]
    private var currentDragArea: DragArea = .none

    @IBInspectable public var attackColor: UIColor = #colorLiteral(red: 0.767, green: 0.000, blue: 0.000, alpha: 1.000)
    @IBInspectable public var decayColor: UIColor = #colorLiteral(red: 0.942, green: 0.648, blue: 0.000, alpha: 1.000)
    @IBInspectable public var sustainColor: UIColor = #colorLiteral(red: 0.320, green: 0.800, blue: 0.616, alpha: 1.000)
    @IBInspectable public var releaseColor: UIColor = #colorLiteral(red: 0.720, green: 0.519, blue: 0.888, alpha: 1.000)
    @IBInspectable public var bgColor: UIColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
    @IBInspectable public var curveStrokeWidth: CGFloat = 1
    @IBInspectable public var curveColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

    var lastPoint = CGPoint.zero

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentDragArea = .none
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            if let found = touchAreas.firstIndex(where: { $0.contains(touchLocation) }) {
                currentDragArea = DragArea(rawValue: found)!
                lastPoint = touchLocation
            }
        }
        setNeedsDisplay()
    }

    /// Handle moving touches
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            switch currentDragArea {
            case .attack:
                attackTime += touchLocation.x - lastPoint.x
                attackTime -= touchLocation.y - lastPoint.y
                attackTime = max(attackTime, 0)
            case .decaySustain:
                sustainPercent -= (touchLocation.y - lastPoint.y) / 10.0
                sustainPercent = min(max(sustainPercent, 0), 100)
                decayTime += touchLocation.x - lastPoint.x
                decayTime = max(decayTime, 0)
            case .release:
                releaseTime += touchLocation.x - lastPoint.x
                releaseTime -= touchLocation.y - lastPoint.y
                releaseTime = max(releaseTime, 0)
            case .none:
                return
            }

            lastPoint = touchLocation

            callback?(Double(attackTime / 1_000.0),
                      Double(decayTime / 1_000.0),
                      Double(sustainPercent / 100.0),
                      Double(releaseTime / 1_000.0))
        }
        setNeedsDisplay()
    }

    private func drawCurveCanvas(size: CGSize, attackDurationMS: CGFloat, decayDurationMS: CGFloat,
                                 releaseDurationMS: CGFloat, sustainLevel: CGFloat) {
        let maxADFraction: CGFloat = 0.75
        // let context = UIGraphicsGetCurrentContext()

        let attackClickRoom = CGFloat(30) // to allow the attack to be clicked even if is zero
        let oneSecond: CGFloat = 0.65 * size.width
        let initialPoint = CGPoint(x: attackClickRoom, y: size.height)
        let buffer = CGFloat(10)//curveStrokeWidth / 2.0 // make a little room for drwing the stroke
        let endAxes = CGPoint(x: size.width, y: size.height)
        let releasePoint = CGPoint(x: attackClickRoom + oneSecond, y: sustainLevel * (size.height - buffer) + buffer)
        let endPoint = CGPoint(x: releasePoint.x + releaseDurationMS / 1_000.0 * oneSecond, y: size.height)
        let endMax = CGPoint(x: min(endPoint.x, size.width), y: buffer)
        let releaseAxis = CGPoint(x: releasePoint.x, y: endPoint.y)
        let releaseMax = CGPoint(x: releasePoint.x, y: buffer)

        let highPoint = CGPoint(x: attackClickRoom +
            min(oneSecond * maxADFraction, attackDurationMS / 1_000.0 * oneSecond),
                                y: buffer)

        let highPointAxis = CGPoint(x: highPoint.x, y: size.height)
        let highMax = CGPoint(x: highPoint.x, y: buffer)
        let minthing = min(oneSecond * maxADFraction, (attackDurationMS + decayDurationMS) / 1_000.0 * oneSecond)
        let sustainPoint = CGPoint(x: max(highPoint.x, attackClickRoom + minthing),
                                   y: sustainLevel * (size.height - buffer) + buffer)
        let sustainAxis = CGPoint(x: sustainPoint.x, y: size.height)
        let initialMax = CGPoint(x: 0, y: buffer)

        let initialToHighControlPoint = CGPoint(x: initialPoint.x, y: highPoint.y)
        let highToSustainControlPoint = CGPoint(x: highPoint.x, y: sustainPoint.y)
        let releaseToEndControlPoint = CGPoint(x: releasePoint.x, y: endPoint.y)

        var path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: highPointAxis)
        path.addLine(to: highMax)
        path.addLine(to: initialMax)
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.close()
        UIColor.white.setFill()
        path.fill()
        touchAreas[DragArea.attack.rawValue] = path

        path = UIBezierPath()
        path.move(to: highPointAxis)
        path.addLine(to: releaseAxis)
        path.addLine(to: releaseMax)
        path.addLine(to: highMax)
        path.addLine(to: highPointAxis)
        path.close()
        UIColor.lightGray.setFill()
        path.fill()
        touchAreas[DragArea.decaySustain.rawValue] = path

        path = UIBezierPath()
        path.move(to: releaseAxis)
        path.addLine(to: endAxes)
        path.addLine(to: endMax)
        path.addLine(to: releaseMax)
        path.addLine(to: releaseAxis)
        path.close()
        UIColor.darkGray.setFill()
        path.fill()
        touchAreas[DragArea.release.rawValue] = path

        let releaseAreaPath = UIBezierPath()
        releaseAreaPath.move(to: releaseAxis)
        releaseAreaPath.addCurve(to: endPoint,
                                 controlPoint1: releaseAxis,
                                 controlPoint2: endPoint)
        releaseAreaPath.addCurve(to: releasePoint,
                                 controlPoint1: releaseToEndControlPoint,
                                 controlPoint2: releasePoint)
        releaseAreaPath.addLine(to: releaseAxis)
        releaseAreaPath.close()
        releaseColor.setFill()
        releaseAreaPath.fill()

        let sustainAreaPath = UIBezierPath()
        sustainAreaPath.move(to: sustainAxis)
        sustainAreaPath.addLine(to: releaseAxis)
        sustainAreaPath.addLine(to: releasePoint)
        sustainAreaPath.addLine(to: sustainPoint)
        sustainAreaPath.addLine(to: sustainAxis)
        sustainAreaPath.close()
        sustainColor.setFill()
        sustainAreaPath.fill()

        let decayAreaPath = UIBezierPath()
        decayAreaPath.move(to: highPointAxis)
        decayAreaPath.addLine(to: sustainAxis)
        decayAreaPath.addCurve(to: sustainPoint,
                                      controlPoint1: sustainAxis,
                                      controlPoint2: sustainPoint)
        decayAreaPath.addCurve(to: highPoint,
                                      controlPoint1: highToSustainControlPoint,
                                      controlPoint2: highPoint)
        decayAreaPath.addLine(to: highPoint)
        decayAreaPath.close()
        decayColor.setFill()
        decayAreaPath.fill()

        let attackAreaPath = UIBezierPath()
        attackAreaPath.move(to: initialPoint)
        attackAreaPath.addLine(to: highPointAxis)
        attackAreaPath.addLine(to: highPoint)
        attackAreaPath.addCurve(to: initialPoint,
                                       controlPoint1: initialToHighControlPoint,
                                       controlPoint2: initialPoint)
        attackAreaPath.close()
        attackColor.setFill()
        attackAreaPath.fill()

        let curvePath = UIBezierPath()
        curvePath.move(to: initialPoint)
        curvePath.addCurve(to: highPoint,
                                  controlPoint1: initialPoint,
                                  controlPoint2: initialToHighControlPoint)
        curvePath.addCurve(to: sustainPoint,
                                  controlPoint1: highPoint,
                                  controlPoint2: highToSustainControlPoint)
        curvePath.addLine(to: releasePoint)
        curvePath.addCurve(to: endPoint,
                                  controlPoint1: releasePoint,
                                  controlPoint2: releaseToEndControlPoint)
        curveColor.setStroke()
        curvePath.lineWidth = curveStrokeWidth
        curvePath.stroke()
    }

    /// Draw the view
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(bounds)
        // context.setFillColor(backgroundColor?.cgColor ?? UIColor.clear.cgColor)
        // context.fill(bounds)

        drawCurveCanvas(size: rect.size, attackDurationMS: attackTime,
                        decayDurationMS: decayTime,
                        releaseDurationMS: releaseTime,
                        sustainLevel: 1.0 - sustainPercent / 100.0)
    }
}
