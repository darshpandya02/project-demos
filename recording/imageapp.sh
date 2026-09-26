#!/usr/bin/env bash
# Session: image-processing-application, headless through its text mode.
# Run from an empty working directory; the source is cloned from GitHub.
# Needs a JDK on PATH (Homebrew openjdk@17 here).
set -u
source "$(dirname "$0")/lib.sh"

rm -rf image-processing-application
clear

PROMPT_DIR="work"
note "fresh clone and compile with javac (no build tool; the app uses only the JDK)"
run 'git clone -q https://github.com/darshpandya02/image-processing-application && cd image-processing-application/image-processing-application'
PROMPT_DIR="image-processing-application"
run 'java -version 2>&1 | head -n 1'
run 'ls src/*/ && wc -l $(find src -name "*.java") | tail -n 1'
run 'javac -d build $(find src -name "*.java") && find build -name "*.class" | wc -l'

note "help lists every command the controller understands"
run 'echo help | java -cp build Main -text | fold -s -w 108 | head -n 24'
note "Main -text starts the text controller (no Swing window). It reads commands from stdin;"
note "\"run FILE\" executes a script of the same commands. This script uses the sample in res/."
run 'mkdir -p out && cat > out/demo.txt <<"EOF"
load res/input.png landscape
sepia landscape landscape-sepia
luma-component landscape landscape-luma
blur landscape landscape-blur
sharpen landscape landscape-sharpen
brighten 60 landscape landscape-bright
horizontal-flip landscape landscape-hflip
rgb-split landscape landscape-r landscape-g landscape-b
histogram landscape landscape-hist
color-correct landscape landscape-cc
levels-adjust 20 128 230 landscape landscape-levels
compress 90 landscape landscape-c90
sepia landscape landscape-sepia-split split 50
save out/sepia.png landscape-sepia
save out/luma.jpg landscape-luma
save out/blur.png landscape-blur
save out/sharpen.png landscape-sharpen
save out/bright.jpg landscape-bright
save out/hflip.png landscape-hflip
save out/red.png landscape-r
save out/histogram.png landscape-hist
save out/color-correct.png landscape-cc
save out/levels.png landscape-levels
save out/compress90.png landscape-c90
save out/sepia-split.ppm landscape-sepia-split
EOF'
run 'wc -l out/demo.txt'
run 'time (echo "run out/demo.txt" | java -cp build Main -text)'
run 'ls -l out/ | grep -v demo.txt'
run 'file out/histogram.png out/luma.jpg; head -c 40 out/sepia-split.ppm | head -n 3'

note "the repository ships its own script covering every operation on PNG, JPG and PPM input"
run 'grep -c . res/commands.txt; cut -d" " -f1 res/commands.txt | sort | uniq -c | sort -rn | column -c 100'
run 'time (echo "run res/commands.txt" | java -cp build Main -text)'
run 'git status --short --untracked-files=all res | wc -l; ls res/a5 | column -c 100'

note "errors are reported and the session keeps going"
run 'printf "load res/does-not-exist.png x\nsepia missing y\nload res/input.png ok\n" | java -cp build Main -text'
sleep 2
