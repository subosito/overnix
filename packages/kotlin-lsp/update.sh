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
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

declare -A PLATFORMS=(
  ["x86_64-linux"]="linux-x64"
  ["aarch64-linux"]="linux-aarch64"
  ["x86_64-darwin"]="mac-x64"
  ["aarch64-darwin"]="mac-aarch64"
)

# Fetch all platform hashes in parallel using unpacked archive hashes that
# match pkgs.fetchzip expectations. Force the target system so we can resolve
# all platform outputs, not just the current host system.
for nix_system in "${!PLATFORMS[@]}"; do
  suffix="${PLATFORMS[$nix_system]}"
  (
    url="$CDN/$latest_version/kotlin-lsp-$latest_version-$suffix.zip"
    hash=$(
      nix \
        --system "$nix_system" \
        store prefetch-file \
        --json \
        --unpack \
        "$url" \
        | jq -r '.hash'
    )
    if [[ -z "$hash" || "$hash" == "null" ]]; then
      echo "Error: failed to prefetch unpacked hash for $nix_system ($suffix)" >&2
      exit 1
    fi
    printf '%s\n' "$hash" > "$TMPDIR/$nix_system"
  ) &
done
wait

# Update version and each platform hash within its own source block.
sed -i "s|version = \"$current_version\"|version = \"$latest_version\"|" "$PKG_FILE"

for nix_system in "${!PLATFORMS[@]}"; do
  hash=$(cat "$TMPDIR/$nix_system")
  echo "  $nix_system: $hash"
  sed -i "/\"$nix_system\" = {/,/};/ s|hash = \"sha256-[^\"]*\"|hash = \"$hash\"|" "$PKG_FILE"
done

echo "Updated kotlin-lsp: $current_version -> $latest_version"
