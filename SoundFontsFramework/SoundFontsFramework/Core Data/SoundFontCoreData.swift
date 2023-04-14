// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData

final class SoundFontCoreData: CoreDataStack<PersistentContainer> {

  convenience init() {
    self.init(container: PersistentContainer(modelName: "SoundFonts"))
  }
}
