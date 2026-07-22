#!/usr/bin/awk -f
# Verify that closing-brace comments in Alloy config files match their opening component.
#
# Every top-level Alloy config component is written with a comment on its closing
# brace naming the component, e.g.:
#
#     prometheus.relabel "my_relabel" {
#       ...
#     } // prometheus.relabel "my_relabel"
#
# This flags any closing brace whose trailing `// ...` comment does not match the
# declaration that opened the block. A descriptive suffix is allowed, so
# `} // prometheus.relabel "dev_null" (dead-end, drops all metrics)` is accepted.
#
# Usage:
#     awk -f check-alloy-closures.awk file.alloy [file2.alloy ...]
#     ./check-alloy-closures.awk file.alloy [file2.alloy ...]
#
# Exits non-zero if any mismatch is found.

function trim(s)      { gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); return s }
function normalize(s) { gsub(/[ \t]+/, " ", s); return trim(s) }

# Count the files given (FNR==1 would skip empty files, which awk reads no records from).
BEGIN { for (k = 1; k < ARGC; k++) if (ARGV[k] !~ /=/) filecount++ }

FNR == 1 { top = 0 }   # reset the brace stack at the start of each file

{
  line = $0
  n = length(line)

  # Phase 1: separate code from a trailing `//` comment, respecting strings.
  code = ""; comment = ""; hascomment = 0
  instr = 0; esc = 0; i = 1
  while (i <= n) {
    c = substr(line, i, 1)
    if (instr) {
      code = code c
      if (esc)             { esc = 0 }
      else if (c == "\\")  { esc = 1 }
      else if (c == "\"")  { instr = 0 }
      i++; continue
    }
    if (c == "\"")                                 { instr = 1; code = code c; i++; continue }
    if (c == "/" && substr(line, i + 1, 1) == "/") { comment = substr(line, i + 2); hascomment = 1; break }
    code = code c; i++
  }

  # Phase 2: walk the code, tracking brace depth and the opener of each block.
  clen = length(code)
  instr = 0; esc = 0; seg = ""
  lastopener = ""; lastopenline = -1; haveclose = 0
  j = 1
  while (j <= clen) {
    c = substr(code, j, 1)
    if (instr) {
      seg = seg c
      if (esc)             { esc = 0 }
      else if (c == "\\")  { esc = 1 }
      else if (c == "\"")  { instr = 0 }
      j++; continue
    }
    if (c == "\"")     { instr = 1; seg = seg c; j++; continue }
    if (c == "{") {
      top++
      stack_text[top] = trim(seg)
      stack_line[top] = FNR
      seg = ""
    } else if (c == "}") {
      if (top > 0) { lastopener = stack_text[top]; lastopenline = stack_line[top]; top-- }
      else         { lastopener = "<unmatched>"; lastopenline = -1 }
      haveclose = 1
      seg = ""
    } else {
      seg = seg c
    }
    j++
  }

  # Phase 3: a closing-brace comment is only meaningful when the code ends in `}`.
  tcode = trim(code)
  if (hascomment && haveclose && tcode ~ /\}$/) {
    if (lastopenline != FNR) {   # skip blocks that open and close on one line
      op = normalize(lastopener)
      cm = normalize(comment)
      # Accept an exact match, or the opener followed by a descriptive suffix.
      if (cm != op && index(cm, op " ") != 1) {
        printf "%s:%d: closing comment \"// %s\" does not match opening component \"%s\" (opened on line %d)\n", FILENAME, FNR, cm, op, lastopenline
        mismatches++
      }
    }
  }
}

END {
  if (mismatches > 0) {
    printf "\nFAIL: %d closing-brace comment mismatch(es) found across %d .alloy file(s).\n", mismatches, filecount > "/dev/stderr"
    exit 1
  }
  printf "OK: checked %d .alloy file(s), all closing-brace comments match.\n", filecount
}
