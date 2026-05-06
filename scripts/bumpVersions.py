#!/usr/bin/env python3

'''Manipulates the version values of an Xcode project.

There are two version values that can be manipulated:

- the marketing version (eg. 1.2.3)
- the project version (eg.123123)

The marketing version consists of three integers: major, minor, and patch. Incrementing one resets to zero the
ones that follow.

The project version can be anything, but for the App Store there can only be one build per unique project
version. Therefore, the value used here will be the date in YYYYMMDDHHmm format.

The script edits three kinds of files:

- LaunchScreen.storyboard -- locates any UI elements with a userLabel of "APP_VERSION" and either a text or title
  attribute. Updates the text/title attribute to hold the marketing version prefixed with a 'v' (eg. v1.2.3)
- Common.xcconfig -- updates the CURRENT_PROJECT_VERSION and MARKETING_VERSION values
'''

import argparse
import os
import re
import sys
from datetime import datetime
from typing import Callable, List, NamedTuple, NoReturn, Optional, Tuple


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
    def fromTuple(cls, value: Tuple[str, str, str]) -> 'MarketingVersion':
        return cls(int(value[0]), int(value[1]), int(value[2]))

    @classmethod
    def fromString(cls, value: str) -> 'MarketingVersion':
        bits = value.split('.')
        return MarketingVersion.fromTuple((bits[0], bits[1], bits[2]))

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


def error(*args) -> None:
    print('**', *args)


def log(*args) -> None:
    print('--', *args)


def contentsChanged(path: Path, contents: str) -> Optional[str]:
    '''
    Determine if the given contents differs from the contents at the given path. If so, return the original's content.
    '''
    original = getFileContents(path)
    return original if original != contents else None

def saveFileContents(path: Path, contents: str) -> None:
    '''
    Write the contents to a file at the given path.

    Only writes if there was a change made to the contents of the file, creating a backup of the original contents with a
    '.old' suffix first.
    '''
    original = contentsChanged(path, contents)
    if original is not None:
        with open(path + '.old', 'w') as fd:
            fd.write(original)
        with open(path, 'w') as fd:
            fd.write(contents)

def getFileContents(path: Path) -> str:
    '''
    Read the contents from a file at the given path and make a backup of the file with the extension '.old'
    '''
    with open(path, 'r') as fd:
        contents = fd.read()
    return contents


def locateFiles(cond: PathPredicate) -> PathList:
    '''Visit all files and directories in the current directory. Returns the collection of all files where the
 given `cond` returned `True`.
    '''
    found = []
    for root, dirs, files in os.walk('.'):
        for exclude in ['DerivedData', '.build', '.workspace']:
            drops = [d for d in dirs if exclude in d]
            for drop in drops:
                dirs.remove(drop)
        for path in files:
            if cond(path):
                found.append(os.path.join(root, path))
    return found


def locateConfigFiles() -> PathList:
    def cond(path: Path) -> bool:
        return os.path.splitext(path)[-1] == '.xcconfig'
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
    return datetime.now().strftime('%Y%m%d%H%M%S')


def updateConfigContents(contents: str, marketingVersion: MarketingVersion, projectVersion: ProjectVersion) -> str:
    contents = re.sub(
        r'(MARKETING_VERSION =) +([0-9]+\.[0-9]+\.[0-9]+)',
        f'\\1 {marketingVersion}',
        contents
    )
    return re.sub(
        r'(CURRENT_PROJECT_VERSION =) +([0-9]+)',
        f'\\1 {projectVersion}',
        contents
    )


def updateConfigFiles(configFiles: PathList, marketingVersion: MarketingVersion, projectVersion: ProjectVersion) -> None:
    for path in configFiles:
        log(f"processing config file '{path}'")
        contents = getFileContents(path)
        contents = updateConfigContents(contents, marketingVersion, projectVersion)
        saveFileContents(path, contents)


def locateUIFiles() -> PathList:
    def cond(path: str) -> bool:
        return os.path.splitext(path)[-1] in ['.storyboard', '.xib']
    return locateFiles(cond)


def updateUIContents(contents: str, marketingVersion: MarketingVersion, projectVersion: ProjectVersion) -> str:
    contents1 = re.sub(r'(text|title)="[^\"]*"(.*userLabel="APP_VERSION")', f'\\1="v{marketingVersion} ({projectVersion})"\\2', contents)
    contents2 = re.sub(r'(userLabel="APP_VERSION".*(text|title))="[^\"]*"', f'\\1="v{marketingVersion} ({projectVersion})"', contents1)
    return contents2


def updateUIFiles(uiFiles: PathList, marketingVersion: MarketingVersion, projectVersion: ProjectVersion):
    for path in uiFiles:
        log(f"processing UI file '{path}'")
        contents = getFileContents(path)
        contents = updateUIContents(contents, marketingVersion, projectVersion)
        saveFileContents(path, contents)


def main(args):
    parser = argparse.ArgumentParser(prog=args[0])
    parser.add_argument('-d', '--dir', help='change to DIR to process')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-1', '--major', action='store_true', help='bump major version')
    group.add_argument('-2', '--minor', action='store_true', help='bump minor version')
    group.add_argument('-3', '--patch', action='store_true', help='bump patch version')
    group.add_argument('-b', '--build', action='store_true', help='update build version')
    group.add_argument('-s', '--set', help='set the version')
    parsed = parser.parse_args(args[1:])

    if parsed.dir:
        os.chdir(parsed.dir)

    configFiles = locateConfigFiles()
    marketingVersion = getCurrentMarketingVersion(configFiles)
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

    updateConfigFiles(configFiles, marketingVersion, projectVersion)
    updateUIFiles(locateUIFiles(), marketingVersion, projectVersion)


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

    def test_locateUIFiles(self):
        self.assertTrue(len(locateUIFiles()) > 0)

    def test_MarketingVersionFromString(self):
        self.assertEqual(MarketingVersion(1, 2, 4), MarketingVersion.fromString('1.2.4'))

    def test_marketingVersionToString(self):
        self.assertEqual('1.2.4', str(MarketingVersion(1, 2, 4)))

    def test_getComponentVersion(self):
        self.assertEqual(65536, MarketingVersion(1, 0, 0).asInt())
        self.assertEqual(65537, MarketingVersion(1, 0, 1).asInt())
        self.assertEqual(65537 + 256, MarketingVersion(1, 1, 1).asInt())
        self.assertEqual(795192, MarketingVersion(12, 34, 56).asInt())

    def test_updateUIContents(self):
        marketingVersion = MarketingVersion(1, 2, 3)
        projectVersion = ProjectVersion("20260506101923")
        contents = 'foo userLabel="APP_VERSION" text="blah" blah'
        self.assertEqual(f'foo userLabel="APP_VERSION" text="v{marketingVersion} ({projectVersion})" blah',
                         updateUIContents(contents, marketingVersion, projectVersion))
        contents = 'foo userLabel="APP_VERSION" title="blah" blah'
        self.assertEqual(f'foo userLabel="APP_VERSION" title="v{marketingVersion} ({projectVersion})" blah',
                         updateUIContents(contents, marketingVersion, projectVersion))
        contents = 'foo text="BLAH" between userLabel="APP_VERSION" silly'
        self.assertEqual(f'foo text="v{marketingVersion} ({projectVersion})" between userLabel="APP_VERSION" silly',
                         updateUIContents(contents, marketingVersion, projectVersion))
        contents = '<textFieldCell key="cell" lineBreakMode="clipping" title="v3.0.0" id="p30-Bk-a8R" userLabel="APP_VERSION">'
        self.assertEqual(f'<textFieldCell key="cell" lineBreakMode="clipping" title="v{marketingVersion} ({projectVersion})" id="p30-Bk-a8R" userLabel="APP_VERSION">',
                         updateUIContents(contents, marketingVersion, projectVersion))
