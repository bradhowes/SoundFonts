//
//  main.swift
//  sf2dump
//
//  Created by Brad Howes on 6/14/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

import Foundation
import SoundFontInfoLib

struct ConsoleIO {
    enum OutputType {
        case error
        case standard
    }

    static func print(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard: Swift.print("\(message)")
        case .error: fputs("Error: \(message)\n", stderr)
        }
    }

    static func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
        print("""
usage: \(executableName) FILE
Dump out all tags in a SF2 file
"""
        )
    }
}

func getSoundFontInfo(data: Data) -> SoundFontInfo? {
    return data.withUnsafeBytes { (body) -> SoundFontInfo? in
        let wrapper = SoundFontParse(body.baseAddress, data.count)
        return wrapper
    }
}

func run() {
    let argc = CommandLine.argc
    print(argc)
    print(CommandLine.arguments)

    let path = "/Users/howes/src/soundFonts/SoundFontsFramework/Resources/SoundFonts/FreeFont.sf2"
    let url = URL(fileURLWithPath: path)
    guard let data = try? Data(contentsOf: url) else {
        ConsoleIO.print("*** failed to open file \(path)", to: .error)
        return
    }

    guard let sfi = getSoundFontInfo(data: data) else {
        ConsoleIO.print("*** invalid SF2 file", to: .error)
        return
    }

    SoundFontDump(sfi)
}

run()
