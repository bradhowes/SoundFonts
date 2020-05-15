// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public class EnvelopeViewController: UIViewController {
    @IBOutlet weak var envelopeView: EnvelopeView!
}

extension EnvelopeViewController: EnvelopeViewManager {

    public func addTarget(_ event: UpperViewSwipingEvent, target: Any, action: Selector) {
    }
}

extension EnvelopeViewController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
    }
}
