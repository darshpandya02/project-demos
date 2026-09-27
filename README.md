# project-demos

Recorded terminal demos of four of my command-line, desktop and library projects, a
recorded browser walkthrough of one web app, and two native task manager apps (an Android
emulator screen recording and a macOS window screenshot sequence), served as a static site:
https://project-demos-gamma.vercel.app

| Page | Project |
|---|---|
| [/raft/](https://project-demos-gamma.vercel.app/raft/) | [raft-cluster-monitor](https://github.com/darshpandya02/raft-cluster-monitor): Raft in C++20. A 5-node cluster, leader failover and fault injection |
| [/robot-factory/](https://project-demos-gamma.vercel.app/robot-factory/) | [BSDS PA3](https://github.com/darshpandya02/BSDS/tree/main/PA3/factory_src): a primary-backup robot factory over TCP |
| [/image-processing/](https://project-demos-gamma.vercel.app/image-processing/) | [image-processing-application](https://github.com/darshpandya02/image-processing-application): a Java image editor, plus a before/after gallery |
| [/meditrack/](https://project-demos-gamma.vercel.app/meditrack/) | [meditrack](https://github.com/darshpandya02/meditrack): ASP.NET Core medical inventory. Browser walkthrough video, screenshots, and the test suite on PostgreSQL |
| [/data-structures/](https://project-demos-gamma.vercel.app/data-structures/) | [cpp-data-structures](https://github.com/darshpandya02/cpp-data-structures): a header-only C++20 library, its tests under sanitizers, an AVL/hash map demo and benchmarks |
| [/taskmaster/](https://project-demos-gamma.vercel.app/taskmaster/) | [taskmaster-android](https://github.com/darshpandya02/taskmaster-android): a Kotlin Android task manager. Emulator screen recording, screenshots, unit/Room/WorkManager/Espresso test runs, APK download |
| [/taskmanager-swift/](https://project-demos-gamma.vercel.app/taskmanager-swift/) | [taskmanager-swift](https://github.com/darshpandya02/taskmanager-swift): a macOS task manager in SwiftUI + AppKit on Core Data. Window screenshot sequence, Swift Testing run, app download |

Nothing runs on a server. The players replay asciicast v2 recordings in `public/casts/`
using a bundled [asciinema-player](https://github.com/asciinema/asciinema-player), and the
gallery in `public/gallery/` holds images the Java program saved.

## How the recordings were made

Each session is a bash script in `recording/`. The script prints every command and then
runs it, and `asciinema rec` records the script's output:

```sh
asciinema rec --cols 110 --rows 32 -i 2 -c "bash recording/raft.sh" public/casts/raft.cast
```

- `raft.sh` runs from a raft-cluster-monitor checkout.
- `factory.sh`, `imageapp.sh` and `dsl.sh` run from an empty directory and clone their repository from GitHub.
- `gallery.py CLASSES SAMPLES public/gallery public/gallery/manifest.json` feeds one script
  per sample image to the image app's text mode. For each image it keeps the generated
  `script.txt` and the program's `run.log`.
- `meditrack.sh` runs from a meditrack checkout with a local PostgreSQL 17. The walkthrough video in
  `public/meditrack/` was recorded by that repository's `scripts/walkthrough.py` (Playwright) and
  converted to MP4 with ffmpeg.
- `taskmaster.sh` runs from a taskmaster-android checkout with an Android 14 emulator booted. The
  video in `public/taskmaster/` was recorded with `adb shell screenrecord` while that repository's
  `scripts/demo.py` drove the release APK, and re-encoded at 2x speed with ffmpeg. The screenshots
  come from `adb exec-out screencap` in the same run.
- `taskmanager-swift.sh` runs from a taskmanager-swift checkout. Screen recording permission is not
  granted on this Mac, so the video in `public/taskmanager-swift/` is not a screen recording: the
  app's `--demo-capture` mode saved a PNG of its own window after each scripted step, and ffmpeg
  joined the frames.
- `castinfo.py` prints the raw and idle-limited length of a recording.
- `verify.py BASE_URL` checks in headless Chromium that each player loads and plays and
  that every gallery image loads.

The recordings were made on 2026-09-26 on a MacBook Air (Apple M5, 24 GB, macOS 26.5.2)
with Apple clang 21, OpenJDK 17 and Swift 6.3.3. The recorded output is unedited.

## Develop

```sh
npm install
npm run dev      # local server
npm run build    # static output in dist/
```

The command listings on each page are filled in at build time from the `run` and `note`
lines of the matching recording script (see `vite.config.js`).

Sample image credits are listed on the image-processing page. Three are public domain
images from Wikimedia Commons, and one is the sample that ships with the image-processing
repository.
