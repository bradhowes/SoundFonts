// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/// Custom UIView that draws an arrow between an entry and an exit point on the border of the view.
class ArrowView: UIView {

  /**
   Supported locations for an entry or an exit
   */
  enum Position: Int, CaseIterable {
    case left
    case top
    case right
    case bottom
  }

  /// Entry point for the arrow in this view
  var entry: Position = .top

  /// Exit point for the arrow in this view
  var exit: Position = .bottom

  /// Line width of the line
  var lineWidth: CGFloat = 0.5

  /// Width of the arrow tail (gap across the top of the "V")
  var arrowWidth: CGFloat = 8.0 { didSet { createArrow() } }

  /// Color of the line
  var lineColor: UIColor = .systemOrange {
    didSet { lineLayer.strokeColor = lineColor.cgColor }
  }

  /// Color of the arrow
  var arrowBorderColor: UIColor = .systemOrange {
    didSet { arrowLayer.strokeColor = arrowBorderColor.cgColor }
  }

  /// Color of the arrow
  var arrowFillColor: UIColor = .systemOrange {
    didSet { arrowLayer.fillColor = arrowFillColor.cgColor }
  }

  /// Length of the arrow
  var arrowLength: CGFloat = 10.0 { didSet { createPaths() } }

  /// Amount of bending given to a curve. This is multiplied with the dimension of the of the view and added to the
  /// dimension mid point to obtain
  /// an X or Y coordinate for a control point.
  var bendFactor: CGFloat = 0.20 { didSet { createLine() } }

  /// Amount of waviness in horizontal/vertical lines. This is multiplied with the dimension of the of the view and
  /// added to the dimension
  /// mid point to obtain an X or Y coordinate for a control point.
  var wavyFactor: CGFloat = 0.10 { didSet { createLine() } }

  private let lineLayer = CAShapeLayer()
  private let arrowLayer = CAShapeLayer()

  /**
   Construct new view with the given frame

   - parameter frame: geometry of the new view
   */
  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  /**
   Construct new view from data in the given coder

   - parameter coder: source to read from
   */
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initialize()
  }

  /**
   Update the view due to layout changes.
   */
  override func layoutSubviews() {
    super.layoutSubviews()
    let layerBounds = bounds.offsetBy(dx: -bounds.midX, dy: -bounds.midY)
    let layerCenter = CGPoint(x: bounds.midX, y: bounds.midY)
    lineLayer.bounds = layerBounds
    lineLayer.position = layerCenter
    arrowLayer.bounds = layerBounds
    arrowLayer.position = layerCenter
    createPaths()
  }
}

private extension ArrowView {

  var entryPoint: CGPoint { positionPoint(entry) }
  var exitPoint: CGPoint { positionPoint(exit) }

  func initialize() {
    lineLayer.fillColor = UIColor.clear.cgColor
    lineLayer.strokeColor = lineColor.cgColor
    lineLayer.lineWidth = lineWidth
    lineLayer.lineCap = .round
    layer.addSublayer(lineLayer)

    arrowLayer.fillColor = arrowFillColor.cgColor
    arrowLayer.strokeColor = arrowBorderColor.cgColor
    arrowLayer.lineWidth = lineWidth
    arrowLayer.lineCap = .round
    layer.addSublayer(arrowLayer)
    createPaths()
  }

  func createPaths() {
    createLine()
    createArrow()
  }

  func createLine() {
    let controls = controlPoints(controlPointParams())
    let linePath = UIBezierPath()
    linePath.move(to: entryPoint)
    linePath.addCurve(to: linePathEnd(), controlPoint1: controls.0, controlPoint2: controls.1)
    lineLayer.path = linePath.cgPath
  }

  func createArrow() {
    let arrowHead = self.exitPoint
    let tailPoints = arrowPoints()
    let arrowPath = UIBezierPath()
    arrowPath.move(to: tailPoints.0)
    arrowPath.addLine(to: arrowHead)
    arrowPath.addLine(to: tailPoints.1)
    arrowPath.addLine(to: tailPoints.0)
    arrowLayer.path = arrowPath.cgPath
  }

  func positionPoint(_ position: Position) -> CGPoint {
    let bounds = lineLayer.bounds
    switch position {
    case .left: return CGPoint(x: bounds.minX, y: bounds.midY)
    case .top: return CGPoint(x: bounds.midX, y: bounds.minY)
    case .right: return CGPoint(x: bounds.maxX, y: bounds.midY)
    case .bottom: return CGPoint(x: bounds.midX, y: bounds.maxY)
    }
  }

  func linePathEnd() -> CGPoint {
    let bounds = lineLayer.bounds
    switch exit {
    case .left: return CGPoint(x: bounds.minX + arrowWidth, y: bounds.midY)
    case .top: return CGPoint(x: bounds.midX, y: bounds.minY + arrowLength)
    case .right: return CGPoint(x: bounds.maxX - arrowWidth, y: bounds.midY)
    case .bottom: return CGPoint(x: bounds.midX, y: bounds.maxY - arrowLength)
    }
  }

  func controlPointParams() -> CGSize {
    let bounds = lineLayer.bounds
    switch (entry, exit) {
    case (_, .top) where (entry == .left || entry == .right):
      return CGSize(width: 0.0, height: -bounds.height * bendFactor)
    case (_, .bottom) where (entry == .left || entry == .right):
      return CGSize(width: 0.0, height: bounds.height * bendFactor)
    case (_, .right) where (entry == .left || entry == .right):
      return CGSize(width: 0.0, height: bounds.height * wavyFactor)
    case (_, .left) where (entry == .top || entry == .bottom):
      return CGSize(width: -bounds.width * bendFactor, height: 0.0)
    case (_, .right) where (entry == .top || entry == .bottom):
      return CGSize(width: bounds.width * bendFactor, height: 0.0)
    case (.top, .bottom):
      return CGSize(width: bounds.width * wavyFactor, height: 0.0)
    case (.bottom, .top):
      return CGSize(width: bounds.width * wavyFactor, height: 0.0)
    default: return CGSize.zero
    }
  }

  func controlPoints(_ size: CGSize) -> (CGPoint, CGPoint) {
    let bounds = lineLayer.bounds
    return (
      CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2),
      CGPoint(x: bounds.midX + size.width / 2, y: bounds.midY + size.height / 2)
    )
  }

  func arrowPoints() -> (CGPoint, CGPoint) {
    let exitPoint = self.exitPoint
    switch exit {
    case .left:
      return (
        CGPoint(x: exitPoint.x + arrowLength, y: exitPoint.y - arrowWidth / 2),
        CGPoint(x: exitPoint.x + arrowLength, y: exitPoint.y + arrowWidth / 2)
      )
    case .right:
      return (
        CGPoint(x: exitPoint.x - arrowLength, y: exitPoint.y - arrowWidth / 2),
        CGPoint(x: exitPoint.x - arrowLength, y: exitPoint.y + arrowWidth / 2)
      )
    case .bottom:
      return (
        CGPoint(x: exitPoint.x - arrowWidth / 2, y: exitPoint.y - arrowLength),
        CGPoint(x: exitPoint.x + arrowWidth / 2, y: exitPoint.y - arrowLength)
      )
    case .top:
      return (
        CGPoint(x: exitPoint.x - arrowWidth / 2, y: exitPoint.y + arrowLength),
        CGPoint(x: exitPoint.x + arrowWidth / 2, y: exitPoint.y + arrowLength)
      )
    }
  }
}
