//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

class Holder : UIView {

    var content: UIView? {
        didSet {
            if let content = content {
                self.addSubview(content)
                content.center = self.center
            }
        }
    }

    override var center: CGPoint {
        get { super.center }
        set {
            super.center = newValue
            content?.center = newValue
        }
    }
}

class VerticalSegmentedControl: UISegmentedControl {

    var rotation: CGFloat = 0.0
    var rotatedFrame: CGRect = .zero

    override var frame: CGRect {
        get { rotatedFrame }
        set { rotatedFrame = newValue }
    }

    override var intrinsicContentSize: CGSize {
        let r = super.intrinsicContentSize
        self.transform = CGAffineTransform().rotated(by: -90 * .pi / 2.0)
        return CGSize(width: r.width, height: r.height) // CGSize(width: r.height, height: r.width)
    }
}

class MyView: UIView {

    private func setup() {
        self.backgroundColor = UIColor.green

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Hello world"
        label.textAlignment = .center
        label.backgroundColor = .yellow
        self.addSubview(label)

        // let margins = self.layoutMarginsGuide

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])


        let holder = Holder()
        holder.backgroundColor = .yellow
        holder.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(holder)

        let seg = UISegmentedControl()
        seg.backgroundColor = .yellow
        seg.translatesAutoresizingMaskIntoConstraints = false
        seg.insertSegment(withTitle: "First", at: 0, animated: false)
        seg.insertSegment(withTitle: "Second", at: 1, animated: false)
        seg.insertSegment(withTitle: "Third", at: 2, animated: false)
        seg.selectedSegmentIndex = 0
        holder.content = seg

        NSLayoutConstraint.activate([
            holder.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            holder.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let v = MyView(frame: CGRect(x: 0, y: 0, width: 300, height: 600))

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = v
