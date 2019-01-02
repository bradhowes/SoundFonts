//
//  ControllerConfiguration.swift
//  SoundFonts
//
//  Created by Brad Howes on 1/1/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import Foundation

/**
 Protocol for UIViewControllers that require connections to other UIViewControllers at startup time.
 */
protocol ControllerConfiguration {
    /**
     Establish connections with other entities in the application.
    
     - parameter context: collection of known UIViewControllers and their protocol facades.
     */
    func establishConnections(_ context: RunContext)
}
