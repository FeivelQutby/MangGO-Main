#!/usr/bin/env bash
#
# Converts a trained YOLO11 checkpoint into a Core ML model that Apple's Vision
# framework recognises as an object detector.
#
# Must run on macOS — coremltools cannot produce a usable model elsewhere.
#
#   ./export_coreml.sh path/to/best.pt

set -euo pipefail

WEIGHTS="${1:-best.pt}"
OUTPUT_NAME="MangoDefect"
DEST="$(cd "$(dirname "$0")/.." && pwd)/MangGO/MangGO/Core/Vision/Resources"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "error: must run on macOS" >&2
  exit 1
fi

if [[ ! -f "$WEIGHTS" ]]; then
  echo "error: weights not found: $WEIGHTS" >&2
  exit 1
fi

python3 -m pip install --quiet --upgrade ultralytics coremltools

# nms=True embeds the non-max-suppression pipeline. Without it Vision returns
# raw MultiArrays instead of VNRecognizedObjectObservation and the Swift side
# gets nothing back.
yolo export model="$WEIGHTS" format=coreml nms=True imgsz=640

EXPORTED="${WEIGHTS%.pt}.mlpackage"

if [[ ! -d "$EXPORTED" ]]; then
  echo "error: export produced no .mlpackage" >&2
  exit 1
fi

mkdir -p "$DEST"
rm -rf "${DEST:?}/${OUTPUT_NAME}.mlpackage"
mv "$EXPORTED" "${DEST}/${OUTPUT_NAME}.mlpackage"

echo "installed → ${DEST}/${OUTPUT_NAME}.mlpackage"
echo
echo "Next: open the .mlpackage in Xcode and confirm the Metadata tab reports"
echo "an Object Detector with Confidence and Coordinates outputs."
