import PlaygroundSupport
import Foundation

let url = URL(fileURLWithPath: "Users/howes/src/Mine/SoundFonts/SoundFontsFramework/Resources/SoundFonts/FreeFont.sf2")
let data = Data(contentsOf: url)

let file = FileHandle(forReadingAtPath: url.path)!
file.seekToEnd()
