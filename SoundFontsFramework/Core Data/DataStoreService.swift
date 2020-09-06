import Foundation
import CoreData
import SoundFontInfoLib

public final class DataStoreService {

    let stack: SoundFontCoreData

    public init(stack: SoundFontCoreData) {
        self.stack = stack
    }
}

extension DataStoreService {

    public func add(soundFontInfo: SoundFontInfo, path: URL) {
        let _ = SoundFontEntity(context: stack.mainContext, config: soundFontInfo)
        stack.saveMainContext()
    }

    public func delete(_ entity: SoundFontEntity) {
        stack.mainContext.delete(entity)
        stack.saveMainContext()
    }

    public func getSoundFonts() -> [SoundFontEntity]? {
        do {
            return try SoundFontEntity.sortedFetchRequest.execute()
        }
        catch let error as NSError {
            print("Fetch error: \(error) description: \(error.userInfo)")
        }

        return nil
    }
}
