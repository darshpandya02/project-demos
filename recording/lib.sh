# Shared helpers for the demo sessions. Each script is run under
# `asciinema rec -c`, so everything printed here ends up in the recording.
#
# run CMD...   prints a shell prompt plus the command text, then evaluates
#              exactly that text with bash. Output is whatever the program
#              prints; nothing is filtered or rewritten.
# note TEXT    prints a comment line (dim) so the viewer knows what comes next.

PROMPT_DIR=${PROMPT_DIR:-~}   # shown like zsh %c: last path component only

run() {
  printf '\033[32mdarsh@mac\033[0m:\033[34m%s\033[0m$ %s\n' "$PROMPT_DIR" "$*"
  sleep 0.8
  eval "$*"
  sleep 2
}

note() {
  printf '\033[2m# %s\033[0m\n' "$*"
  sleep 2
}
