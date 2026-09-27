#!/usr/bin/env bash
# Session: TaskManager (macOS) Swift Testing suite and the app bundle build.
# Run from the root of a taskmanager-swift checkout. Only the Command Line Tools
# are installed (no Xcode), which is why scripts/test.sh adds framework paths.
set -u
source "$(dirname "$0")/lib.sh"
PROMPT_DIR="taskmanager-swift"
clear

note "toolchain: Swift from the Command Line Tools, no Xcode"
run 'swift --version 2>&1 | head -1; xcode-select -p'

note "the Swift Testing suites (per-test start lines left out)"
run 'scripts/test.sh 2>&1 | grep -vE "started\.$|^\[[0-9]+/[0-9]+\]"'

note "build the universal .app (ad-hoc signed only) and the zip on the release page"
run 'scripts/package.sh 2>&1 | grep -vE "^\[[0-9]+/[0-9]+\]|Compiling|Building"'
run 'lipo -info dist/TaskManager.app/Contents/MacOS/TaskManager'
run 'spctl --assess --type execute dist/TaskManager.app 2>&1 || true'
