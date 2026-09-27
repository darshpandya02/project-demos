import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { defineConfig } from "vite";

const root = import.meta.dirname;
const page = (p) => resolve(root, p);

const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

// Replaces <!-- commands:NAME.sh --> with the commands and notes of that
// recording script, so the listing on each page is exactly what was run.
function commandListing(script) {
  const src = readFileSync(resolve(root, "recording", script), "utf8");
  const out = [];
  for (const m of src.matchAll(/^(?:run '([\s\S]*?)'|note "(.*?)")$/gm)) {
    if (m[1] !== undefined) out.push(`<span class="p">$ </span>${esc(m[1])}`);
    else out.push(`<span class="c"># ${esc(m[2])}</span>`);
  }
  return `<pre class="cmds">${out.join("\n")}</pre>`;
}

const injectCommands = {
  name: "inject-recording-commands",
  transformIndexHtml(html) {
    return html.replace(/<!-- commands:([\w.-]+) -->/g, (_, s) => commandListing(s));
  },
};

export default defineConfig({
  plugins: [injectCommands],
  build: {
    rollupOptions: {
      input: {
        index: page("index.html"),
        raft: page("raft/index.html"),
        factory: page("robot-factory/index.html"),
        image: page("image-processing/index.html"),
        meditrack: page("meditrack/index.html"),
        dsl: page("data-structures/index.html"),
        taskmaster: page("taskmaster/index.html"),
        taskmanagerSwift: page("taskmanager-swift/index.html"),
      },
    },
  },
});
