#!/usr/bin/env bash

# Usage:
# ./mp4_to_circle_gif.sh output.gif [size] [fps]

set -e

INPUT="$1"
OUTPUT="$2"
SIZE="${3:-480}"   # default 480px
FPS="${4:-15}"     # default 15 fps

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "Usage: $0 input.mp4 output.gif [size] [fps]"
  exit 1
fi

PALETTE=$(mktemp /tmp/palette.XXXX.png)

FILTER="fps=${FPS},scale=${SIZE}:-1:flags=lanczos,\
crop='min(iw,ih)':'min(iw,ih)',\
format=rgba,\
geq=lum='p(X,Y)':a='if(lte((X-W/2)^2+(Y-H/2)^2,(W/2)^2),255,0)'"

echo "Generating palette..."
ffmpeg -y -i "$INPUT" -filter_complex "${FILTER},palettegen=reserve_transparent=1" "$PALETTE"

echo "Creating circular GIF..."
ffmpeg -y -i "$INPUT" -i "$PALETTE" -filter_complex \
"${FILTER}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
-loop 0 "$OUTPUT"

rm -f "$PALETTE"

echo "Done: $OUTPUT"
