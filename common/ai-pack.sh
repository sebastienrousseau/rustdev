#!/usr/bin/env bash
# langdev ai-pack — Bundle repository context into token-efficient XML/Markdown for AI prompts.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Generates structured context packets from workspace source files, respecting .gitignore.
set -euo pipefail

FORMAT="xml"
OUTPUT=""
MAX_BYTES=200000

usage() {
  cat << 'EOF'
Usage: ai-pack [OPTIONS] [PATHS...]

Options:
  -f, --format <xml|markdown> Output format (default: xml)
  -o, --output <file>         Write to output file (default: stdout)
  -m, --max-size <bytes>      Max file size to include in bytes (default: 200000)
  -h, --help                  Show this help message
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -f|--format) FORMAT="$2"; shift 2 ;;
    -o|--output) OUTPUT="$2"; shift 2 ;;
    -m|--max-size) MAX_BYTES="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) break ;;
  esac
done

# --- Test seam (inert in production) ----------------------------------------
if [ -n "${LANGDEV_TEST:-}" ]; then
  printf 'AI_PACK_RAN format=%s output=%s\n' "$FORMAT" "${OUTPUT:-stdout}"
  exit 0
fi

generate_xml() {
  echo "<workspace>"
  git ls-files 2>/dev/null | while read -r f; do
    if [ -f "$f" ]; then
      local size
      size=$(wc -c < "$f" 2>/dev/null || echo 0)
      if [ "$size" -lt "$MAX_BYTES" ] && [ "$size" -gt 0 ]; then
        echo "  <file path=\"$f\">"
        cat "$f" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
        echo "  </file>"
      fi
    fi
  done
  echo "</workspace>"
}

generate_markdown() {
  echo "# Workspace Code Context"
  echo ""
  git ls-files 2>/dev/null | while read -r f; do
    if [ -f "$f" ]; then
      local size
      size=$(wc -c < "$f" 2>/dev/null || echo 0)
      if [ "$size" -lt "$MAX_BYTES" ] && [ "$size" -gt 0 ]; then
        echo "## File: \`$f\`"
        echo '```'
        cat "$f"
        echo '```'
        echo ""
      fi
    fi
  done
}

if [ -n "$OUTPUT" ]; then
  if [ "$FORMAT" = "markdown" ]; then
    generate_markdown > "$OUTPUT"
  else
    generate_xml > "$OUTPUT"
  fi
  echo "Packed workspace context into $OUTPUT"
else
  if [ "$FORMAT" = "markdown" ]; then
    generate_markdown
  else
    generate_xml
  fi
fi
