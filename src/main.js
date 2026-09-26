import "@fontsource/jetbrains-mono/400.css";
import "@fontsource/jetbrains-mono/600.css";
import "asciinema-player/dist/bundle/asciinema-player.css";
import "./style.css";
import * as AsciinemaPlayer from "asciinema-player";

// Every <div class="player" data-cast="..."> becomes an asciinema player.
// The .cast files are plain asciicast v2 recordings served from /casts.
for (const el of document.querySelectorAll(".player[data-cast]")) {
  const player = AsciinemaPlayer.create(el.dataset.cast, el, {
    theme: "midnight",
    fit: "width",
    idleTimeLimit: Number(el.dataset.idle || 2),
    poster: el.dataset.poster || "npt:0:4",
    terminalFontFamily: '"JetBrains Mono", ui-monospace, Menlo, monospace',
    terminalLineHeight: 1.25,
  });
  el.player = player;
}

// Before/after gallery on the image-processing page.
const gallery = document.getElementById("gallery");
if (gallery) renderGallery(gallery);

async function renderGallery(root) {
  const res = await fetch("/gallery/manifest.json");
  const manifest = await res.json();
  const credits = JSON.parse(document.getElementById("credits").textContent);
  const labels = Object.fromEntries(manifest.operations.map((o) => [o.id, o.label]));

  const controls = root.querySelector(".gallery-controls");
  const source = root.querySelector(".source");
  const grid = root.querySelector(".grid");

  const show = (name) => {
    const image = manifest.images.find((i) => i.name === name);
    const credit = credits[name];
    for (const b of controls.querySelectorAll("button")) {
      b.setAttribute("aria-pressed", String(b.dataset.name === name));
    }
    source.innerHTML = credit.html;
    grid.replaceChildren(
      figure(`/gallery/${image.original}`, "original (input)", [`load ${name}/original.jpg ${name}`], true),
      ...image.outputs.map((o) => figure(`/gallery/${o.file}`, labels[o.id], o.commands)),
    );
  };

  for (const image of manifest.images) {
    const b = document.createElement("button");
    b.type = "button";
    b.dataset.name = image.name;
    b.textContent = credits[image.name].title;
    b.addEventListener("click", () => show(image.name));
    controls.append(b);
  }
  show(manifest.images[0].name);
}

function figure(src, label, commands, original = false) {
  const f = document.createElement("figure");
  if (original) f.className = "original";
  const img = document.createElement("img");
  img.src = src;
  img.alt = label;
  img.loading = "lazy";
  img.decoding = "async";
  const cap = document.createElement("figcaption");
  const l = document.createElement("span");
  l.className = "label";
  l.textContent = label;
  const code = document.createElement("code");
  code.textContent = commands.join("\n");
  cap.append(l, code);
  f.append(img, cap);
  return f;
}
