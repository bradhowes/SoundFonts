//
//  NotifierToken.swift
//  SoundFonts
//
//  Created by Brad Howes on 1/3/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import Foundation

final class NotifierToken {
    private let cancellationClosure: () -> Void
    
    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }
    
    func cancel() {
        cancellationClosure()
    }
}
