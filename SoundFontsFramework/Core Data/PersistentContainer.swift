// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData

public final class PersistentContainer: NSPersistentContainer {
    convenience init() { self.init(name: "SoundFonts") }
}
