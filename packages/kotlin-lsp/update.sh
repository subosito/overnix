#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_FILE="$SCRIPT_DIR/default.nix"

current_version=$(grep 'version = ' "$PKG_FILE" | head -1 | sed 's/.*"\(.*\)".*/\1/')

echo "Fetching latest release from GitHub..."
latest_version=$(curl -sf https://api.github.com/repos/Kotlin/kotlin-lsp/releases?per_page=1 \
  | jq -r '.[0].name' \
  | sed 's/^v//')

if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
  echo "Error: failed to fetch latest version"
  exit 1
fi

echo "Current version: $current_version"
echo "Latest version:  $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
  echo "Already up to date."
  exit 0
fi

CDN="https://download-cdn.jetbrains.com/kotlin-lsp"

declare -A PLATFORMS=(
  ["x86_64-linux"]="linux-x64"
  ["aarch64-linux"]="linux-aarch64"
  ["x86_64-darwin"]="mac-x64"
  ["aarch64-darwin"]="mac-aarch64"
)

fetch_sri_hash() {
  local platform_suffix="$1"
  local sha256_url="$CDN/$latest_version/kotlin-lsp-$latest_version-$platform_suffix.zip.sha256"
  local hex_hash

  hex_hash=$(curl -sf "$sha256_url" | awk '{print $1}')
  if [[ -z "$hex_hash" ]]; then
    echo "Error: failed to fetch hash for $platform_suffix" >&2
    exit 1
  fi

  nix hash convert --hash-algo sha256 --to sri "sha256:$hex_hash"
}

declare -A HASHES

for nix_system in "${!PLATFORMS[@]}"; do
  suffix="${PLATFORMS[$nix_system]}"
  echo "Fetching hash for $nix_system ($suffix)..."
  HASHES[$nix_system]=$(fetch_sri_hash "$suffix")
  echo "  ${HASHES[$nix_system]}"
done

echo "Updating $PKG_FILE..."

sed -i "s|version = \"$current_version\"|version = \"$latest_version\"|" "$PKG_FILE"

for nix_system in "${!PLATFORMS[@]}"; do
  old_pattern="\"$nix_system\""
  # Replace the hash on the line matching this system
  sed -i "/$old_pattern/s|hash = \"sha256-[^\"]*\"|hash = \"${HASHES[$nix_system]}\"|" "$PKG_FILE"
done

echo "Updated kotlin-lsp: $current_version -> $latest_version"
