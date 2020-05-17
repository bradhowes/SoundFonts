// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Simple UIView collection manager that can cycle through cells, showing them one at a time.
 */
public struct SlidingViewManager {

    private var views = [ViewSlider]()
    public private(set) var active: Int = 0

    init(active: Int) {
        self.active = active
    }
    
    public mutating func add(view: UIView) {
        views.append(ViewSlider(view: view))
    }

    /**
     Show the next view by sliding the existing / next views to the left.
     */
    public mutating func slideNextHorizontally() {
        transition(activate: active + 1, method: ViewSlider.slideLeft)
    }

    /**
     Show the previous view by sliding the existing / previous views to the right.
     */
    public mutating func slidePrevHorizontally() {
        transition(activate: active - 1, method: ViewSlider.slideRight)
    }
}

extension SlidingViewManager {

    /**
     Slide two views, the old one slides out while the new one slides it.
     
     - parameter activate: the index for the view to slide in and make current
     - parameter method: the sliding method to invoke to do the sliding
     */
    private mutating func transition(activate: Int, method: (_ : ViewSlider) -> () -> Void ) {
        let index: Int = {
            if activate < 0 { return activate + views.count }
            else if activate >= views.count { return activate - views.count }
            else { return activate }
        }()

        if index == active { return }
        method(views[active])()
        active = index
        method(views[active])()
    }

}
