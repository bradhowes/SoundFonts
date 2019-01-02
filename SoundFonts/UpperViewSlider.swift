//
//  LayoutManager.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/22/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

/**
 Instances know how to slide themselves around horizontally.
 */
final class UpperViewSlider: CustomStringConvertible {
    
    let view: UIView
    let leading: NSLayoutConstraint
    let trailing: NSLayoutConstraint

    var description: String {
        return "UpperViewSlider(\(view.restorationIdentifier ?? "NA")"
    }
    
    init(view: UIView) {
        guard let constraints = view.superview?.constraints else { preconditionFailure("missing constraints in superview") }
        self.view = view

        var found = Array<(NSLayoutConstraint)?>(repeating: nil, count: 2)
        constraints.forEach {
            if $0.firstItem === view {
                switch $0.firstAttribute {
                case .leading: found[0] = $0
                case .trailing: found[1] = $0
                default: break
                }
            }
        }

        guard found.allSatisfy({ $0 != nil }) else { preconditionFailure("missing one or more constraints")}
        self.leading = found[0]!
        self.trailing = found[1]!
    }

    /**
     Slide the view in the direction managed by the given constraints. Uses CoreAnimation to show the
     view sliding in/out
     
     - parameter state: indicates if the view is sliding into view (true) or sliding out of view (false)
     - parameter a: the constraint for left or top
     - parameter b: the constraint for right or bottom
     - parameter constant: the value that will be used to animate over
     */
    private func slide(from: NSLayoutConstraint, to: NSLayoutConstraint, offset: CGFloat) {
        let slidingIn = view.isHidden

        if slidingIn {
            to.constant = offset
            from.constant = offset
            view.superview?.layoutIfNeeded()
            self.view.isHidden = false
        }

        UIView.animate(withDuration: 0.25,
                       animations: {
                        if slidingIn {
                            to.constant = 0
                            from.constant = 0
                        }
                        else {
                            to.constant = -offset
                            from.constant = -offset
                        }
                        self.view.superview?.layoutIfNeeded()
        },
                       completion: { _ in
                        self.view.superview?.layoutIfNeeded()
                        self.view.isHidden = !slidingIn
        })
    }
    
    /**
     Slide the view to the left.
     */
    func slideLeft() {
        slide(from: trailing, to: leading, offset: view.frame.size.width)
    }
    
    /**
     Slide the view to the right.
     */
    func slideRight() {
        slide(from: leading, to: trailing, offset: -view.frame.size.width)
    }
}
