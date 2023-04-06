// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit

/**
 Animates an expanding circle that fades as it grows.
 */
class MIDIIndicatorPulseAnimation: CALayer {

  override init(layer: Any) {
    super.init(layer: layer)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init() {
    super.init()
    self.backgroundColor = UIColor.black.cgColor
    self.contentsScale = UIScreen.main.scale
    self.opacity = 0.0
  }

  /**
   Begin animating the pulse.

   - parameter radius: the radius of the final circle to show
   - parameter color: the color to draw with
   - parameter duration: the duration of the animation
   - parameter repetitions: the number of times the animation repeats
   */
  func start(radius: CGFloat, color: UIColor, duration: TimeInterval, repetitions: Float) {
    self.cornerRadius = radius
    self.backgroundColor = color.cgColor
    DispatchQueue.global(qos: .default).async {
      let animation = self.makeAnimation(duration: duration, repetitions: repetitions)
      DispatchQueue.main.async {
        self.add(animation, forKey: "pulse")
      }
    }
  }

  private func scaleAnimation(duration: TimeInterval) -> CABasicAnimation {
    let scaleAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
    scaleAnimation.fromValue = NSNumber(value: 0)
    scaleAnimation.toValue = NSNumber(value: 1)
    scaleAnimation.duration = duration
    return scaleAnimation
  }

  private func createOpacityAnimation(duration: TimeInterval) -> CAKeyframeAnimation {
    let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
    opacityAnimation.duration = duration
    opacityAnimation.values = [0.3, 0.8, 0]
    opacityAnimation.keyTimes = [0, 0.3, 1]
    return opacityAnimation
  }

  private func makeAnimation(duration: TimeInterval, repetitions: Float) -> CAAnimationGroup {
    let animationGroup = CAAnimationGroup()
    animationGroup.duration = duration
    animationGroup.repeatCount = repetitions
    animationGroup.timingFunction = .init(name: .default)
    animationGroup.animations = [scaleAnimation(duration: duration), createOpacityAnimation(duration: duration)]
    return animationGroup
  }
}
