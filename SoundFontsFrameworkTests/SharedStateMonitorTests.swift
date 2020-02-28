// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class SharedStateMonitorTests: XCTestCase {

    func testMonitoring() {
        let appExp = expectation(description: "app")
        let appMon: (SharedStateMonitor.StateChange)->Void = { stateChange in
            if stateChange == .soundFonts { appExp.fulfill() }
        }
        let app = SharedStateMonitor(changer: .application)
        app.block = appMon

        let au3Exp = expectation(description: "au3")
        let au3Mon: (SharedStateMonitor.StateChange)->Void = { stateChange in
            if stateChange == .favorites { au3Exp.fulfill() }
        }
        let au3 = SharedStateMonitor(changer: .audioUnit)
        au3.block = au3Mon

        app.notifyFavoritesChanged()
        au3.notifySoundFontsChanged()

        wait(for: [appExp, au3Exp], timeout: 10.0)
    }
}
