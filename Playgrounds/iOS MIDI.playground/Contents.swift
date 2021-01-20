import UIKit
import PlaygroundSupport

open class Arrow: UIView {

    public enum Position: Int, CaseIterable {
        case left
        case top
        case right
        case bottom
    }

    open var entry: Position = .left { didSet { createPath() } }
    open var entryIB: Int {
        get { entry.rawValue }
        set { entry = Position(rawValue: newValue) ?? .left }
    }

    open var exit: Position = .bottom { didSet { createPath() } }
    open var exitIB: Int {
        get { exit.rawValue }
        set { exit = Position(rawValue: newValue) ?? .bottom }
    }

    open var arrowWidth: CGFloat = 8.0 { didSet { createPath() } }
    open var arrowLength: CGFloat = 10.0 { didSet { createPath() } }

    open var bendFactor: CGFloat = 0.20 { didSet { createPath() } }
    open var wavyFactor: CGFloat = 0.10 { didSet { createPath() } }

    private let pathLayer = CAShapeLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        let layerBounds = bounds.offsetBy(dx: -bounds.midX, dy: -bounds.midY)
        let layerCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pathLayer.bounds = layerBounds
        pathLayer.position = layerCenter
        createPath()
    }
}

extension Arrow {

    private var entryPoint: CGPoint { positionPoint(entry) }
    private var exitPoint: CGPoint { positionPoint(exit) }

    private func initialize() {
        layer.addSublayer(pathLayer)
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.strokeColor = UIColor.systemRed.cgColor
        pathLayer.lineWidth = 2.0
        createPath()
    }

    private func createPath() {
        let controls = controlOffsets()
        let path = UIBezierPath()
        path.move(to: entryPoint)
        path.addCurve(to: linePathEnd(), controlPoint1: controls.0, controlPoint2: controls.1)
        addArrow(path)
        pathLayer.path = path.cgPath
    }

    private func positionPoint(_ position: Position) -> CGPoint {
        let bounds = pathLayer.bounds
        switch position {
        case .left: return CGPoint(x: bounds.minX, y: bounds.midY)
        case .top: return CGPoint(x: bounds.midX, y: bounds.minY)
        case .right: return CGPoint(x: bounds.maxX, y: bounds.midY)
        case .bottom: return CGPoint(x: bounds.midX, y: bounds.maxY)
        }
    }

    private func linePathEnd() -> CGPoint {
        let bounds = pathLayer.bounds
        switch exit {
        case .left: return CGPoint(x: bounds.minX + arrowWidth, y: bounds.midY)
        case .top: return CGPoint(x: bounds.midX, y: bounds.minY + arrowLength)
        case .right: return CGPoint(x: bounds.maxX - arrowWidth, y: bounds.midY)
        case .bottom: return CGPoint(x: bounds.midX, y: bounds.maxY - arrowLength)
        }
    }

    private func controlOffsets() -> (CGPoint, CGPoint) {
        let bounds = pathLayer.bounds
        switch (entry, exit) {
        case (.left, .top): return controlPoints(CGSize(width: 0.0, height: -bounds.height * bendFactor), CGPoint.zero)
        case (.left, .right): return controlPoints(CGSize(width: 0.0, height: bounds.height * wavyFactor), CGPoint.zero)
        case (.left, .bottom): return controlPoints(CGSize(width: 0.0, height: bounds.height * bendFactor), CGPoint.zero)
        case (.top, .right): return controlPoints(CGSize(width: bounds.width * bendFactor, height: 0.0), CGPoint.zero)
        case (.top, .bottom): return controlPoints(CGSize(width: bounds.width * wavyFactor, height: 0.0), CGPoint.zero)
        case (.top, .left): return controlPoints(CGSize(width: -bounds.width * bendFactor, height: 00.0), CGPoint.zero)
        case (.right, .left): return controlPoints(CGSize(width: 0.0, height: bounds.height * wavyFactor), CGPoint.zero)
        case (.right, .top): return controlPoints(CGSize(width: 0.0, height: -bounds.height * bendFactor), CGPoint.zero)
        case (.right, .bottom): return controlPoints(CGSize(width: 0.0, height: bounds.height * bendFactor), CGPoint.zero)
        case (.bottom, .left): return controlPoints(CGSize(width: -bounds.width * bendFactor, height: 0.0), CGPoint.zero)
        case (.bottom, .top): return controlPoints(CGSize(width: bounds.width * wavyFactor, height: 0.0), CGPoint.zero)
        case (.bottom, .right): return controlPoints(CGSize(width: bounds.width * bendFactor, height: 0.0), CGPoint.zero)
        default: return controlPoints(CGSize.zero, CGPoint.zero)
        }
    }

    private func controlPoints(_ size: CGSize, _ offset: CGPoint) -> (CGPoint, CGPoint) {
        let bounds = pathLayer.bounds
        return (
            CGPoint(x: bounds.midX - size.width / 2 + offset.x, y: bounds.midY - size.height / 2 + offset.y),
            CGPoint(x: bounds.midX + size.width / 2 + offset.x, y: bounds.midY + size.height / 2 + offset.y)
        )
    }

    private func addArrow(_ path: UIBezierPath) {
        let exitPoint = self.exitPoint
        path.addLine(to: exitPoint)
        switch exit {
        case .left:
            path.addLine(to: CGPoint(x: exitPoint.x + arrowLength, y: exitPoint.y - arrowWidth / 2))
            path.move(to: exitPoint)
            path.addLine(to: CGPoint(x: exitPoint.x + arrowLength, y: exitPoint.y + arrowWidth / 2))
        case .right:
            path.addLine(to: CGPoint(x: exitPoint.x - arrowLength, y: exitPoint.y - arrowWidth / 2))
            path.move(to: exitPoint)
            path.addLine(to: CGPoint(x: exitPoint.x - arrowLength, y: exitPoint.y + arrowWidth / 2))
        case .bottom:
            path.addLine(to: CGPoint(x: exitPoint.x - arrowWidth / 2, y: exitPoint.y - arrowLength))
            path.move(to: exitPoint)
            path.addLine(to: CGPoint(x: exitPoint.x + arrowWidth / 2, y: exitPoint.y - arrowLength))
        case .top:
            path.addLine(to: CGPoint(x: exitPoint.x - arrowWidth / 2, y: exitPoint.y + arrowLength))
            path.move(to: exitPoint)
            path.addLine(to: CGPoint(x: exitPoint.x + arrowWidth / 2, y: exitPoint.y + arrowLength))
        }
    }
}

class MyViewController : UIViewController {

    var arrows = [Arrow]()

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        self.view = view

        for entry in Arrow.Position.allCases {
            for exit in Arrow.Position.allCases {
                if entry == exit { continue }
                let arrow = Arrow()
                arrow.entry = entry
                arrow.exit = exit
                arrows.append(arrow)
                view.addSubview(arrow)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width: CGFloat = 140.0
        let height: CGFloat = 80.0
        let spacing: CGFloat = 10.0
        for (index, arrow) in arrows.enumerated() {
            let x = CGFloat(spacing) + (index % 2 == 1 ? 1.0 : 0.0) * (width + spacing)
            let y = CGFloat(spacing + (spacing + height) * CGFloat(index / 2))
            arrow.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
}

PlaygroundPage.current.liveView = MyViewController()
