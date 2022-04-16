#!/bin/bash

# Toggles read-only status of the README.md files found in a project. When enabled, the README.md files will be
# rendered as HTML. When unlocked, they are shown as raw markdown text and they can be edited.

FORCE=""
case "${1}" in
    unlock) FORCE="U";;
    lock) FORCE="L";;
    *) FORCE="";
esac

for DIR in *.xcodeproj; do
    if [[ -f "${DIR}/.xcodesamplecode.plist" ]]; then
        if [[ "${FORCE:-U}" = "U" ]]; then
            mv "${DIR}/.xcodesamplecode.plist" "${DIR}/dot_xcodesamplecode.plist"
            echo "-- unlocking ${DIR} markdowns"
        fi
    elif [[ -f "${DIR}/dot_xcodesamplecode.plist" ]]; then
        if [[ "${FORCE:-L}" = "L" ]]; then
            mv "${DIR}/dot_xcodesamplecode.plist" "${DIR}/.xcodesamplecode.plist"
            echo "-- locking ${DIR} markdowns"
        fi
    fi
done
