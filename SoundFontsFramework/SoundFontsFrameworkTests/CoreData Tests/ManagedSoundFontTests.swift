// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

class ManagedSoundFontTests: XCTestCase {

    func testVisibility() {
        doWhenCoreDataReady(#function) { testHarness, context in
            let app = ManagedAppState.get(context: context)
            XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 0)
            ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
            ManagedSoundFont(in: context, config: CoreDataTestData.sf2)
            XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 2)
            let fetched: [ManagedSoundFont]? = testHarness.fetchEntities()
            fetched![0].setVisible(false)
            XCTAssertTrue(context.saveOrRollback())
            XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 1)

            fetched![0].setVisible(true)
            XCTAssertTrue(context.saveOrRollback())
            XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 2)
        }
    }

    func testSoundFontKind() {
        doWhenCoreDataReady(#function) { testHarness, context in
            let app = ManagedAppState.get(context: context)
            XCTAssertEqual(ManagedSoundFont.countRows(in: context, tag: app.allTag), 0)
            let sf1 = ManagedSoundFont(in: context, config: CoreDataTestData.sf1)
            sf1.setBookmark(Bookmark(url: URL(fileURLWithPath: "/a/b/c"), name: "foo.sf2"))
            sf1.setDisplayName("bookmark")
            guard case let SoundFontKind.reference(bookmark) = sf1.kind else {
                XCTFail("expected bookmark resource")
                return
            }

            XCTAssertEqual(bookmark.name, "foo.sf2")
            XCTAssertEqual(bookmark.original, URL(fileURLWithPath: "/a/b/c"))

            let sf2 = ManagedSoundFont(in: context, config: CoreDataTestData.sf2)
            sf2.setBundleUrl(URL(fileURLWithPath: "/x/y/z.sf2"))
            sf2.setDisplayName("bundle resource")
            guard case let SoundFontKind.builtin(resource) = sf2.kind else {
                XCTFail("expected bundle resource")
                return
            }

            XCTAssertEqual(resource, URL(fileURLWithPath: "/x/y/z.sf2"))

            let sf3 = ManagedSoundFont(in: context, config: CoreDataTestData.sf3)
            sf3.setFileName("fileName.sf2")
            sf3.setDisplayName("private file")
            guard case let SoundFontKind.installed(fileName) = sf3.kind else {
                XCTFail("expected file resource")
                return
            }

            XCTAssertEqual(fileName, "fileName.sf2")
        }
    }


}
