#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")" && pwd)"
cd "$project_root"

swift build -c release

bundle_path="$project_root/UtcMenuBar.app"
rm -rf "$bundle_path"
mkdir -p "$bundle_path/Contents/MacOS" "$bundle_path/Contents/Resources/UTCClock.iconset"
cp ".build/release/UtcMenuBar" "$bundle_path/Contents/MacOS/UtcMenuBar"
cp "Resources/Info.plist" "$bundle_path/Contents/Info.plist"
iconset_path="$bundle_path/Contents/Resources/UTCClock.iconset"
for size in 16 32 128 256 512; do
  sips --resampleHeightWidth "$size" "$size" "Assets/UTCClock.png" --out "$iconset_path/icon_${size}x${size}.png" >/dev/null
  doubled_size=$((size * 2))
  sips --resampleHeightWidth "$doubled_size" "$doubled_size" "Assets/UTCClock.png" --out "$iconset_path/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil --convert icns "$iconset_path" --output "$bundle_path/Contents/Resources/UTCClock.icns"
rm -rf "$iconset_path"
codesign --force --sign - --timestamp=none "$bundle_path"

echo "Built $bundle_path"
