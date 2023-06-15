#!/usr/bin/env python3

'''Manipulates the versionings values of an Xcode project. There are two version values that can be manipulated:

- the marketing version (eg. 1.2.3)
- the project version (eg.123123)

The marketing version consists of three integers: major, minor, and patch. Incrementing one resets to zero the
ones that follow.

The project version can be anything, but for the App Store there can only be one build per unique project
version. Therefore, the value used here will be the date in YYYYMMDDHHmm format.

The script edits three kinds of files:

- project.pbxproj -- the project file for a collection of targets. If more than one is found (in a workspace),
  then they will all be edited as long as they have the same marketing version
- storyboard and xib -- locates any UI elements with a userLabel of "APP_VERSION" and either a text or title
  attribute. Updates the text/title attribute to hold the marketing version prefixed with a 'v' (eg. v1.2.3)
- Info.plist -- updates any audio unit component version values with the 32-bit version of the marketing value
  (major * 65536 + minor * 256 + patch). So 1.2.3 = 65051

'''

import argparse
import os
import re
import sys
from datetime import datetime
import subprocess
import tempfile
from typing import Callable, List, NamedTuple, NoReturn, Tuple


Path = str
ProjectVersion = str
PathPredicate = Callable[[Path], bool]
PathList = List[Path]


class MarketingVersion(NamedTuple):
    '''Holds the current immutable marketing version. Provides methods to create new values.
    '''
    major: int
    minor: int
    patch: int

    @classmethod
    def fromTuple(cls, value: Tuple[str]) -> 'MarketingVersion':
        return cls(int(value[0]), int(value[1]), int(value[2]))

    @classmethod
    def fromString(cls, value: str) -> 'MarketingVersion':
        return MarketingVersion.fromTuple(value.split('.'))

    def __str__(self):
        return f"{self.major}.{self.minor}.{self.patch}"

    def asInt(self):
        return self.major * 65536 + self.minor * 256 + self.patch

    def bumpMajor(self) -> 'MarketingVersion':
        return MarketingVersion(self.major + 1, 0, 0)

    def bumpMinor(self) -> 'MarketingVersion':
        return MarketingVersion(self.major, self.minor + 1, 0)

    def bumpPatch(self) -> 'MarketingVersion':
        return MarketingVersion(self.major, self.minor, self.patch + 1)


def errorAndExit(*args) -> NoReturn:
    print('**', *args)
    sys.exit(1)


def error(*args) -> NoReturn:
    print('**', *args)


def log(*args) -> None:
    print('--', *args)


def saveFile(path: Path, contents: str) -> None:
    '''Write the contents to a file at the given path.
    '''
    with open(path, 'w') as fd:
        fd.write(contents)


def getAndBackupFile(path: Path) -> str:
    '''Read the contents from a file at the given path and make a backup of the file with the extension '.old'
    '''
    with open(path, 'r') as fd:
        contents = fd.read()
    saveFile(path + '.old', contents)
    return contents


def locateFiles(cond: PathPredicate) -> PathList:
    '''Visit all files and directories in the current directory. Returns the collection of all files where the
 given `cond` returned `True`.
    '''
    found = []
    for dirname, dirnames, filenames in os.walk('.'):
        for exclude in ['DerivedData', '.build']:
            if exclude in dirnames:
                dirnames.remove(exclude)
        for path in filenames:
            if cond(path):
                found.append(os.path.join(dirname, path))
    return found


def locateProjectFiles() -> PathList:
    def cond(path):
        return path == 'project.pbxproj'
    return locateFiles(cond)


def getCurrentMarketingVersion(projectFiles: PathList) -> MarketingVersion:
    '''Visit all project files, compare MARKETING_VERSION values to make sure they all match, and return one.
    '''
    pattern = re.compile(r'MARKETING_VERSION = ([0-9]+)\.([0-9]+)\.([0-9]+)')
    version = None
    for file in projectFiles:
        with open(file, 'r') as fd:
            contents = fd.read()
        versions = pattern.findall(contents)
        if version is None:
            version = versions[0]
            versions = versions[1:]
        for v in versions:
            if v != version:
                log(f'{file} has mismatched version: {v} - expected: {version}')
    if version is None:
        errorAndExit('no MARKETING_VERSION found')
    return MarketingVersion.fromTuple(version)


def getNewProjectVersion() -> ProjectVersion:
    return datetime.utcnow().strftime('%Y%m%d%H%M%S')


def updateProjectContents(contents: str, marketingVersion: MarketingVersion, projectVersion: ProjectVersion) -> str:
    contents = re.sub(r'(MARKETING_VERSION =) ([0-9]+\.[0-9]+\.[0-9]+);',
                      f'\\1 {marketingVersion};',
                      contents)
    return re.sub(r'(CURRENT_PROJECT_VERSION =) ([0-9]*);',
                  f'\\1 {projectVersion};',
                  contents)


def updateProjectFiles(projectFiles: PathList, marketingVersion: MarketingVersion,
                       projectVersion: ProjectVersion) -> None:
    for path in projectFiles:
        log(f"processing project file '{path}'")
        contents = getAndBackupFile(path)
        contents = updateProjectContents(contents, marketingVersion, projectVersion)
        saveFile(path, contents)


def locateUIFiles() -> PathList:
    def cond(path):
        return os.path.splitext(path)[-1] in ['.storyboard', '.xib']
    return locateFiles(cond)


def updateUIContents(contents: str, marketingVersion: MarketingVersion) -> str:
    contents1 = re.sub(r'(text|title)="[^\"]*"(.*userLabel="APP_VERSION")', f'\\1="v{marketingVersion}"\\2', contents)
    contents2 = re.sub(r'(userLabel="APP_VERSION".*(text|title))="[^\"]*"', f'\\1="v{marketingVersion}"', contents1)
    return contents2


def updateUIFiles(uiFiles: PathList, marketingVersion: MarketingVersion):
    for path in uiFiles:
        log(f"processing UI file '{path}'")
        contents = getAndBackupFile(path)
        contents = updateUIContents(contents, marketingVersion)
        saveFile(path, contents)


def runPlistBuddy(path, setArg) -> None:
    log(f"processing info file '{path}'")
    status = subprocess.run(['/usr/libexec/PlistBuddy', path, '-c', setArg], stdout=subprocess.PIPE,
                            universal_newlines=True)
    if status.returncode != 0:
        error('failed to process', path, setArg)


def locateInfoFiles() -> PathList:
    def cond(path):
        return path == 'Info.plist'
    return locateFiles(cond)


def updateInfoFiles(infoFiles: PathList, marketingVersion: MarketingVersion) -> None:
    componentVersion = marketingVersion.asInt()
    setArg = f'Set :NSExtension:NSExtensionAttributes:AudioComponents:0:version {componentVersion}'
    for path in infoFiles:
        if open(path).read().find('<key>AudioComponents</key>') == -1:
            continue
        runPlistBuddy(path, setArg)


def main(args):
    parser = argparse.ArgumentParser(prog=args[0])
    parser.add_argument('-d', '--dir', help='change to DIR to process')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-1', '--major', action='store_true', help='bump major version')
    group.add_argument('-2', '--minor', action='store_true', help='bump minor version')
    group.add_argument('-3', '--patch', action='store_true', help='bump patch version')
    group.add_argument('-b', '--build', action='store_true', help='set the build version')
    group.add_argument('-s', '--set', help='set the version')
    parsed = parser.parse_args(args[1:])

    if parsed.dir:
        os.chdir(parsed.dir)

    projectFiles = locateProjectFiles()
    marketingVersion = getCurrentMarketingVersion(projectFiles)
    log(f"current marketingVersion: {marketingVersion}")
    projectVersion = getNewProjectVersion()
    log(f"new projectVersion: {projectVersion}")

    if parsed.set:
        marketingVersion = MarketingVersion.fromString(parsed.set)
    elif parsed.major:
        marketingVersion = marketingVersion.bumpMajor()
    elif parsed.minor:
        marketingVersion = marketingVersion.bumpMinor()
    elif parsed.patch:
        marketingVersion = marketingVersion.bumpPatch()

    log(f"new marketingVersion: {marketingVersion}")
    log(f"new projectVersion: {projectVersion}")
    updateProjectFiles(projectFiles, marketingVersion, projectVersion)
    updateUIFiles(locateUIFiles(), marketingVersion)
    updateInfoFiles(locateInfoFiles(), marketingVersion)


if __name__ == '__main__':
    main(sys.argv)


# --- Unit Tests ---
# % python3 -m unittest bumpVersions.py

import unittest


class Tests(unittest.TestCase):

    def test_bumpMajor(self):
        self.assertEqual(MarketingVersion(2, 0, 0), MarketingVersion(1, 2, 3).bumpMajor())

    def test_bumpMinor(self):
        self.assertEqual(MarketingVersion(1, 3, 0), MarketingVersion(1, 2, 3).bumpMinor())

    def test_bumpPatch(self):
        self.assertEqual(MarketingVersion(1, 2, 4), MarketingVersion(1, 2, 3).bumpPatch())

    def test_getNewProjectVersion(self):
        value = getNewProjectVersion()
        self.assertEqual(len(value), 14)

    def test_locateFiles(self):
        def cond(path):
            return path == 'bumpVersions.py'
        self.assertEqual(1, len(locateFiles(cond)))

    def test_locateProjectFiles(self):
        self.assertEqual(1, len(locateProjectFiles()))

    def test_locateUIFiles(self):
        self.assertTrue(len(locateUIFiles()) > 0)

    def test_locateInfoFiles(self):
        self.assertTrue(len(locateInfoFiles()) > 0)

    def test_MarketingVersionFromString(self):
        self.assertEqual(MarketingVersion(1, 2, 4), MarketingVersion.fromString('1.2.4'))

    def test_marketingVersionToString(self):
        self.assertEqual('1.2.4', str(MarketingVersion(1, 2, 4)))

    def test_getComponentVersion(self):
        self.assertEqual(65536, MarketingVersion(1, 0, 0).asInt())
        self.assertEqual(65537, MarketingVersion(1, 0, 1).asInt())
        self.assertEqual(65537 + 256, MarketingVersion(1, 1, 1).asInt())
        self.assertEqual(795192, MarketingVersion(12, 34, 56).asInt())

    def test_updateProjectContents(self):
        marketingVersion = str(MarketingVersion(1, 2, 3))
        projectVersion = getNewProjectVersion()
        contents = 'one MARKETING_VERSION = 9.8.7; one\ntwo CURRENT_PROJECT_VERSION = 123123; two'
        self.assertEqual(f'one MARKETING_VERSION = 1.2.3; one\ntwo CURRENT_PROJECT_VERSION = {projectVersion}; two',
                         updateProjectContents(contents, marketingVersion, projectVersion))

    def test_updateUIContents(self):
        marketingVersion = str(MarketingVersion(1, 2, 3))
        contents = 'foo userLabel="APP_VERSION" text="blah" blah'
        self.assertEqual(f'foo userLabel="APP_VERSION" text="v{marketingVersion}" blah',
                         updateUIContents(contents, marketingVersion))
        contents = 'foo userLabel="APP_VERSION" title="blah" blah'
        self.assertEqual(f'foo userLabel="APP_VERSION" title="v{marketingVersion}" blah',
                         updateUIContents(contents, marketingVersion))
        contents = 'foo text="BLAH" between userLabel="APP_VERSION" silly'
        self.assertEqual(f'foo text="v{marketingVersion}" between userLabel="APP_VERSION" silly',
                         updateUIContents(contents, marketingVersion))
        contents = '<textFieldCell key="cell" lineBreakMode="clipping" title="v3.0.0" id="p30-Bk-a8R" userLabel="APP_VERSION">'
        self.assertEqual(f'<textFieldCell key="cell" lineBreakMode="clipping" title="v{marketingVersion}" id="p30-Bk-a8R" userLabel="APP_VERSION">',
                         updateUIContents(contents, marketingVersion))

    def test_UpdateInfoFile(self):
        contents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionAttributes</key>
		<dict>
			<key>AudioComponents</key>
			<array>
				<dict>
					<key>tags</key>
					<array>
						<string>Effects</string>
					</array>
					<key>type</key>
					<string>$(AU_COMPONENT_TYPE)</string>
					<key>version</key>
					<real>65538</real>
				</dict>
			</array>
		</dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.AudioUnit-UI</string>
	</dict>
</dict>
</plist>
'''
        fd, path = tempfile.mkstemp(text=True)
        marketingVersion = MarketingVersion(1, 2, 3)
        with os.fdopen(fd) as _:
            with open(path, 'w') as fd:
                fd.write(contents)
            updateInfoFiles([path], marketingVersion)
            with open(path, 'r') as fd:
                updated = fd.read()
        self.assertNotEqual(contents, updated)
        componentVersion = marketingVersion.asInt()
        self.assertEqual(updated.find(f'<real>{componentVersion}</real>'), 523)
