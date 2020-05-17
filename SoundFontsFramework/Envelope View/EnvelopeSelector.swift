// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

enum EnvelopeSelected: Int {
    case env1 = 1
    case env2 = 2
    case both = 3
}

protocol EnvelopeSelectorDelegate: class {
    func selectionChanged(value: EnvelopeSelected)
}

class EnvelopeSelector: NSObject {

    private let activeLabelColor = UIColor.systemTeal
    private let activeBackgroundColor = UIColor.clear
    private let inactiveLabelColor = UIColor.darkGray
    private let inactiveBackgroundColor = UIColor.clear

    private let env1: UIButton
    private let env2: UIButton
    private let both: UIButton

    weak var delegate: EnvelopeSelectorDelegate?
    var selected: EnvelopeSelected = .env1

    init(env1: UIButton, env2: UIButton, both: UIButton) {
        self.env1 = env1
        self.env2 = env2
        self.both = both
        super.init()

        env1.addTarget(self, action: #selector(selectOption), for: .touchUpInside)
        env2.addTarget(self, action: #selector(selectOption), for: .touchUpInside)
        both.addTarget(self, action: #selector(selectOption), for: .touchUpInside)
    }

    @objc private func selectOption(_ sender: UIButton) {
        guard let selected = EnvelopeSelected(rawValue: sender.tag) else { return }
        let updates: [UIButton] = {
            switch selected {
            case .env1: return [self.env1, self.env2, self.both]
            case .env2: return [self.env2, self.env1, self.both]
            case .both: return [self.both, self.env1, self.env2]
            }
        }()

        updates[0].setTitleColor(activeLabelColor, for: .normal)
        updates[0].backgroundColor = activeBackgroundColor
        updates[1].setTitleColor(inactiveLabelColor, for: .normal)
        updates[1].backgroundColor = inactiveBackgroundColor
        updates[2].setTitleColor(inactiveLabelColor, for: .normal)
        updates[2].backgroundColor = inactiveBackgroundColor

        delegate?.selectionChanged(value: selected)
    }
}
