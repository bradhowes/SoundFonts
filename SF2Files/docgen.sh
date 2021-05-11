#!/bin/bash

set -x

rm -rf ./docs/*

JAZZY=$(type -p jazzy)

${JAZZY} --sdk iphoneos \
         --min-acl internal \
         --swift-build-tool xcodebuild \
         -b -workspace,../SoundFonts.xcworkspace,-scheme,SF2Files \
         -m SF2Files --module-version 2.3.8
