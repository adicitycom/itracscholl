#!/usr/bin/env bash
# Generate mipmap icon Android untuk SATU flavor sekolah, dari file
# schools/<id>/icon.png (sumber, sebaiknya 1024x1024 px, PNG, tanpa alpha
# transparan penuh supaya tidak aneh di launcher lama).
#
# Dipakai otomatis oleh GitHub Actions sebelum build tiap flavor.
# Bisa juga dijalankan manual: bash tool/generate_icons.sh itracscholl

set -euo pipefail

SCHOOL_ID="$1"
SRC_ICON="schools/${SCHOOL_ID}/icon.png"

if [ ! -f "$SRC_ICON" ]; then
  echo "ERROR: tidak ada $SRC_ICON" >&2
  exit 1
fi

declare -A SIZES=(
  [mdpi]=48
  [hdpi]=72
  [xhdpi]=96
  [xxhdpi]=144
  [xxxhdpi]=192
)

for density in "${!SIZES[@]}"; do
  size="${SIZES[$density]}"
  outdir="android/app/src/${SCHOOL_ID}/res/mipmap-${density}"
  mkdir -p "$outdir"
  convert "$SRC_ICON" -resize "${size}x${size}" "${outdir}/ic_launcher.png"
done

echo "Icon untuk '${SCHOOL_ID}' selesai dibuat di android/app/src/${SCHOOL_ID}/res/"
