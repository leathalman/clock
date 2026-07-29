#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")" && pwd)"
cd "$project_root"

swift build -c release

bundle_path="$project_root/UtcMenuBar.app"
rm -rf "$bundle_path"
mkdir -p "$bundle_path/Contents/MacOS"
cp ".build/release/UtcMenuBar" "$bundle_path/Contents/MacOS/UtcMenuBar"
cp "Resources/Info.plist" "$bundle_path/Contents/Info.plist"
codesign --force --sign - --timestamp=none "$bundle_path"

echo "Built $bundle_path"
