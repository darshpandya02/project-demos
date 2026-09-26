#!/usr/bin/env bash
# Session: cpp-data-structures. Build, unit tests, sanitizers, leak check,
# the dsl-demo tour and a short benchmark run.
# Run from an empty working directory; the source is cloned from GitHub.
set -u
source "$(dirname "$0")/lib.sh"

rm -rf cpp-data-structures
clear

PROMPT_DIR="work"
note "fresh clone of the header-only C++20 library (the only vendored dependency is doctest)"
run 'git clone -q https://github.com/darshpandya02/cpp-data-structures && cd cpp-data-structures'
PROMPT_DIR="cpp-data-structures"
run 'ls include/dsl tests'

note "build and run the unit tests (64 doctest cases, randomized checks against the std:: containers)"
run 'make -j8 build/tests build/dsl-demo build/bench'
run 'build/tests'

note "the same tests under AddressSanitizer + UndefinedBehaviorSanitizer, then ThreadSanitizer"
note "(tail keeps doctest's summary; the build lines are hidden)"
run 'make -j8 asan 2>&1 | tail -n 3'
run 'make -j8 tsan 2>&1 | tail -n 3'

note "leak check: LeakSanitizer is not available on Apple silicon, so use macOS leaks(1)"
run 'leaks --atExit -- build/tests --no-intro 2>&1 | grep -E "Status|leaks for"'

note "dsl-demo: AVL tree shape after each insert (30 and 50 rotate once, 25 needs a double rotation)"
run 'build/dsl-demo avl 10 20 30 40 50 25'
note "sorted input: the plain BST degenerates into a list, the AVL tree stays at height 14"
run 'build/dsl-demo sorted 10000'
note "hash map (Robin Hood open addressing): every rehash, probe lengths, backward-shift erase"
run 'build/dsl-demo hashmap 1000'
run 'build/dsl-demo containers'

note "short benchmark run vs the standard containers (-O2, n = 1k and 100k, ns per element)"
run 'build/bench --quick 2>/dev/null'
sleep 2
