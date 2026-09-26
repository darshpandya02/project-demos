#!/usr/bin/env python3
"""Build the before/after gallery for the image-processing-application demo.

Writes one script of image-processing-application commands per sample image,
runs each through the app's text mode (`java Main -text`, command `run FILE`),
and records which command produced which output file in a manifest that the
site reads. The images are produced by the Java program; this script only
writes its input scripts and lists the files it saved.

usage: gallery.py CLASSES_DIR SAMPLES_DIR OUT_DIR MANIFEST_JSON
"""
import json
import pathlib
import shutil
import subprocess
import sys

# (output id, label, commands, name of the result to save).
# "{i}" is the loaded image name and "{o}" the default output name.
O = "{o}"
OPS = [
    ("red-component", "red-component", ["red-component {i} {o}"], O),
    ("green-component", "green-component", ["green-component {i} {o}"], O),
    ("blue-component", "blue-component", ["blue-component {i} {o}"], O),
    ("value-component", "value-component", ["value-component {i} {o}"], O),
    ("luma-component", "luma-component", ["luma-component {i} {o}"], O),
    ("intensity-component", "intensity-component", ["intensity-component {i} {o}"], O),
    ("horizontal-flip", "horizontal-flip", ["horizontal-flip {i} {o}"], O),
    ("vertical-flip", "vertical-flip", ["vertical-flip {i} {o}"], O),
    ("brighten", "brighten 50", ["brighten 50 {i} {o}"], O),
    ("darken", "brighten -50", ["brighten -50 {i} {o}"], O),
    ("rgb-split-r", "rgb-split (red)", ["rgb-split {i} {i}-r {i}-g {i}-b"], "{i}-r"),
    ("rgb-split-g", "rgb-split (green)", [], "{i}-g"),
    ("rgb-split-b", "rgb-split (blue)", [], "{i}-b"),
    ("rgb-combine", "rgb-combine (red + green of the flipped image + blue)",
     ["horizontal-flip {i} {i}-hf",
      "rgb-split {i}-hf {i}-hf-r {i}-hf-g {i}-hf-b",
      "rgb-combine {o} {i}-r {i}-hf-g {i}-b"], O),
    ("blur", "blur", ["blur {i} {o}"], O),
    ("sharpen", "sharpen", ["sharpen {i} {o}"], O),
    ("sepia", "sepia", ["sepia {i} {o}"], O),
    ("histogram", "histogram", ["histogram {i} {o}"], O),
    ("color-correct", "color-correct", ["color-correct {i} {o}"], O),
    ("levels-adjust", "levels-adjust 30 128 220", ["levels-adjust 30 128 220 {i} {o}"], O),
    ("compress-50", "compress 50", ["compress 50 {i} {o}"], O),
    ("compress-90", "compress 90", ["compress 90 {i} {o}"], O),
    ("compress-98", "compress 98", ["compress 98 {i} {o}"], O),
    ("blur-split", "blur, split 50", ["blur {i} {o} split 50"], O),
    ("sepia-split", "sepia, split 50", ["sepia {i} {o} split 50"], O),
    ("luma-split", "luma-component, split 50", ["luma-component {i} {o} split 50"], O),
    ("levels-split", "levels-adjust 30 128 220, split 50",
     ["levels-adjust 30 128 220 {i} {o} split 50"], O),
]


def main():
    classes, samples, out_dir, manifest_path = map(pathlib.Path, sys.argv[1:5])
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {"operations": [{"id": op_id, "label": label} for op_id, label, _, _ in OPS],
                "images": []}
    for src in sorted(samples.glob("*.jpg")):
        name = src.stem
        img_out = out_dir / name
        img_out.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, img_out / "original.jpg")
        # paths in the script are relative to OUT_DIR, where java runs
        lines = [f"load {name}/original.jpg {name}"]
        entries = []
        for op_id, label, cmds, save_name in OPS:
            fmt = dict(i=name, o=f"{name}-{op_id}")
            shown = [c.format(**fmt) for c in cmds]
            save = f"save {name}/{op_id}.jpg {save_name.format(**fmt)}"
            lines += shown + [save]
            entries.append({"id": op_id, "commands": shown + [save], "file": f"{name}/{op_id}.jpg"})
        script = img_out / "script.txt"
        script.write_text("\n".join(lines) + "\n")
        res = subprocess.run(["java", "-Djava.awt.headless=true", "-cp", str(classes.resolve()), "Main", "-text"],
                             input=f"run {name}/script.txt\nquit\n", text=True, capture_output=True,
                             cwd=out_dir)
        (img_out / "run.log").write_text(res.stdout + res.stderr)
        missing = [e["file"] for e in entries if not (out_dir / e["file"]).is_file()]
        if res.returncode != 0 or "Error" in res.stderr or missing:
            sys.exit(f"{name}: exit {res.returncode}, missing {missing}\n{res.stderr[-2000:]}")
        manifest["images"].append({"name": name, "original": f"{name}/original.jpg", "outputs": entries})
        print(f"{name}: {len(entries)} outputs")
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
