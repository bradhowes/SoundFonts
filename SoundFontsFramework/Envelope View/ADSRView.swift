// Copyright © 2020 Brad Howes. All rights reserved.
//

import UIKit

@IBDesignable public class ADSRView: UIView {

//    private let margin: CGFloat = 50
//
//    private var attack: CGFloat = 100
//    private var decay: CGFloat = 50
//    private var sustain: CGFloat = 100
//    private var release: CGFloat = 50
//
//    private enum DragArea: Int {
//        case attack
//        case decaySustain
//        case release
//        case none = -1
//    }
//
//    private var touchAreas = [UIBezierPath(), UIBezierPath(), UIBezierPath()]
//    private var currentDragArea: DragArea = .none
//
//    @IBInspectable public var attackColor: UIColor = #colorLiteral(red: 0.767, green: 0.000, blue: 0.000, alpha: 1.000)
//    @IBInspectable public var decayColor: UIColor = #colorLiteral(red: 0.942, green: 0.648, blue: 0.000, alpha: 1.000)
//    @IBInspectable public var sustainColor: UIColor = #colorLiteral(red: 0.320, green: 0.800, blue: 0.616, alpha: 1.000)
//    @IBInspectable public var releaseColor: UIColor = #colorLiteral(red: 0.720, green: 0.519, blue: 0.888, alpha: 1.000)
//    @IBInspectable public var bgColor: UIColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
//
//    var lastPoint = CGPoint.zero
//}
//
//extension ADSRView {
//
//    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        currentDragArea = .none
//        if let touch = touches.first {
//            let touchLocation = touch.location(in: self)
//            if let found = touchAreas.firstIndex(where: { $0.contains(touchLocation) }) {
//                currentDragArea = DragArea(rawValue: found)!
//                lastPoint = touchLocation
//            }
//        }
//        setNeedsDisplay()
//    }
//
//    /// Handle moving touches
//    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let touch = touches.first {
//            let touchLocation = touch.location(in: self)
//            switch currentDragArea {
//            case .attack: setAttack(max(attack + touchLocation.x - lastPoint.x, 0))
//            case .decaySustain:
//                decay = max(decay + touchLocation.x - lastPoint.x, 0)
//                sustain = max(sustain + touchLocation.y - lastPoint.y, 0)
//            case .release: release = max(release + touchLocation.x - lastPoint.x, 0)
//            case .none: return
//            }
//
//            lastPoint = touchLocation
//        }
//        setNeedsDisplay()
//    }
//
//    private func setAttack(_ value: CGFloat) {
//        let maxAttack = bounds.width - 2 * margin - release - minSustainDurationWidth
//        attack = min(max(value, 0), maxAttack)
//        if attack > 
//    }
//}
//
//extension ADSRView {
//
//    // Normalized ADSR in range [0-1]
//    // A + D + S + R == 1.0
//    private func drawEnvelope() {
//        let span = bounds.size.width - 2 * margin
//        let bottom = bounds.size.height
//        let top: CGFloat = 0
//        let minDuration: CGFloat = 60
//        let maxAttack = span - minDuration
//
//        var path = UIBezierPath()
//        path.move(to: CGPoint(x: 0, y: bottom))
//        path.addLine(to: CGPoint(x: 0, y: top))
//        path.addLine(to: CGPoint(x: margin + attack, y: top))
//        path.addLine(to: CGPoint(x: margin + attack, y: bottom))
//        path.close()
//        UIColor.lightGray.setFill()
//        path.fill()
//        touchAreas[DragArea.attack.rawValue] = path
//
//        path = UIBezierPath()
//        path.move(to: CGPoint(x: margin + attack, y:))
//        path.addLine(to: releaseAxis)
//        path.addLine(to: releaseMax)
//        path.addLine(to: highMax)
//        path.addLine(to: highPointAxis)
//        path.close()
//        UIColor.lightGray.setFill()
//        path.fill()
//        touchAreas[DragArea.decaySustain.rawValue] = path
//
//        path = UIBezierPath()
//        path.move(to: releaseAxis)
//        path.addLine(to: endAxes)
//        path.addLine(to: endMax)
//        path.addLine(to: releaseMax)
//        path.addLine(to: releaseAxis)
//        path.close()
//        UIColor.darkGray.setFill()
//        path.fill()
//        touchAreas[DragArea.release.rawValue] = path
//
//        let releaseAreaPath = UIBezierPath()
//        releaseAreaPath.move(to: releaseAxis)
//        releaseAreaPath.addCurve(to: endPoint,
//                                 controlPoint1: releaseAxis,
//                                 controlPoint2: endPoint)
//        releaseAreaPath.addCurve(to: releasePoint,
//                                 controlPoint1: releaseToEndControlPoint,
//                                 controlPoint2: releasePoint)
//        releaseAreaPath.addLine(to: releaseAxis)
//        releaseAreaPath.close()
//        releaseColor.setFill()
//        releaseAreaPath.fill()
//
//        let sustainAreaPath = UIBezierPath()
//        sustainAreaPath.move(to: sustainAxis)
//        sustainAreaPath.addLine(to: releaseAxis)
//        sustainAreaPath.addLine(to: releasePoint)
//        sustainAreaPath.addLine(to: sustainPoint)
//        sustainAreaPath.addLine(to: sustainAxis)
//        sustainAreaPath.close()
//        sustainColor.setFill()
//        sustainAreaPath.fill()
//
//        let decayAreaPath = UIBezierPath()
//        decayAreaPath.move(to: highPointAxis)
//        decayAreaPath.addLine(to: sustainAxis)
//        decayAreaPath.addCurve(to: sustainPoint,
//                                      controlPoint1: sustainAxis,
//                                      controlPoint2: sustainPoint)
//        decayAreaPath.addCurve(to: highPoint,
//                                      controlPoint1: highToSustainControlPoint,
//                                      controlPoint2: highPoint)
//        decayAreaPath.addLine(to: highPoint)
//        decayAreaPath.close()
//        decayColor.setFill()
//        decayAreaPath.fill()
//
//        let attackAreaPath = UIBezierPath()
//        attackAreaPath.move(to: initialPoint)
//        attackAreaPath.addLine(to: highPointAxis)
//        attackAreaPath.addLine(to: highPoint)
//        attackAreaPath.addCurve(to: initialPoint,
//                                       controlPoint1: initialToHighControlPoint,
//                                       controlPoint2: initialPoint)
//        attackAreaPath.close()
//        attackColor.setFill()
//        attackAreaPath.fill()
//
//        let curvePath = UIBezierPath()
//        curvePath.move(to: initialPoint)
//        curvePath.addCurve(to: highPoint,
//                                  controlPoint1: initialPoint,
//                                  controlPoint2: initialToHighControlPoint)
//        curvePath.addCurve(to: sustainPoint,
//                                  controlPoint1: highPoint,
//                                  controlPoint2: highToSustainControlPoint)
//        curvePath.addLine(to: releasePoint)
//        curvePath.addCurve(to: endPoint,
//                                  controlPoint1: releasePoint,
//                                  controlPoint2: releaseToEndControlPoint)
//        curveColor.setStroke()
//        curvePath.lineWidth = curveStrokeWidth
//        curvePath.stroke()
//    }
//
//    /// Draw the view
//    public override func draw(_ rect: CGRect) {
//        guard let context = UIGraphicsGetCurrentContext() else { return }
//        context.clear(bounds)
//    }
}
