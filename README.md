# project-demos

Recorded terminal demos of three of my command-line and desktop projects, served as a
static site: https://project-demos.vercel.app

| Page | Project |
|---|---|
| [/raft/](https://project-demos.vercel.app/raft/) | [raft-cluster-monitor](https://github.com/darshpandya02/raft-cluster-monitor): Raft in C++20. A 5-node cluster, leader failover and fault injection |
| [/robot-factory/](https://project-demos.vercel.app/robot-factory/) | [BSDS PA3](https://github.com/darshpandya02/BSDS/tree/main/PA3/factory_src): a primary-backup robot factory over TCP |
| [/image-processing/](https://project-demos.vercel.app/image-processing/) | [image-processing-application](https://github.com/darshpandya02/image-processing-application): a Java image editor, plus a before/after gallery |

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
- `factory.sh` and `imageapp.sh` run from an empty directory and clone their repository from GitHub.
- `gallery.py CLASSES SAMPLES public/gallery public/gallery/manifest.json` feeds one script
  per sample image to the image app's text mode. For each image it keeps the generated
  `script.txt` and the program's `run.log`.
- `castinfo.py` prints the raw and idle-limited length of a recording.
- `verify.py BASE_URL` checks in headless Chromium that each player loads and plays and
  that every gallery image loads.

The recordings were made on 2026-09-26 on a MacBook Air (Apple M5, 24 GB, macOS 26.5.2)
with Apple clang 21 and OpenJDK 17. The recorded output is unedited.

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
