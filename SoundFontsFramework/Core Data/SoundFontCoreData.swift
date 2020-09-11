// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData

public final class SoundFontCoreData : CoreDataStack<PersistentContainer> {

    public convenience init() {
        self.init(container: PersistentContainer(modelName: "SoundFonts"))
    }
}
