#!/bin/bash
# Fix Deckset slide formatting
# Usage: ./scripts/fix-slides.sh <file.md>

if [ -z "$1" ]; then
    echo "Usage: $0 <markdown-file>"
    echo "Example: $0 hour-1-beginner.md"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found"
    exit 1
fi

# Add empty line before --- if missing
awk '
BEGIN { prev = "" }
{
  if ($0 == "---" && prev != "") {
    print ""
  }
  print $0
  prev = $0
}
' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

echo "Fixed slide breaks in $FILE"

# Count slides
SLIDE_COUNT=$(grep -c '\[\.footer: Slide' "$FILE")
echo "Total slides: $SLIDE_COUNT"
