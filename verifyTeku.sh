#!/bin/bash
# Verifies teku.rb points at the latest Teku tag and its sha256 matches the artifact.
# Usage: ./verifyTeku.sh [path/to/teku.rb]
set -euo pipefail
FORMULA=${1:-teku.rb}
TEMP=$(mktemp -d)
trap 'rm -rf "${TEMP}"' EXIT

URL=$(sed -n 's/^  url "\(.*\)"$/\1/p' "${FORMULA}")
SHA=$(sed -n 's/^  sha256 "\(.*\)"$/\1/p' "${FORMULA}")
VERSION=$(sed -n 's#.*/versions/\([^/]*\)/teku-\1\.zip$#\1#p' <<<"${URL}")
[[ -n "${URL}" && -n "${SHA}" && -n "${VERSION}" ]] || { echo "Could not parse url/sha256/version from ${FORMULA}"; exit 1; }

# GitHub release is still a draft when the homebrew PR is opened, so use tags, not releases.
LATEST=$(git ls-remote --tags https://github.com/consensys/teku.git \
  | sed -n 's#.*refs/tags/\([0-9][0-9.]*\)$#\1#p' | sort -V | tail -1)
echo "Formula version: ${VERSION}, latest Teku tag: ${LATEST}"
[[ "${VERSION}" == "${LATEST}" ]] || { echo "FAIL: formula version ${VERSION} != latest tag ${LATEST}"; exit 1; }

echo "Downloading ${URL}..."
curl -sS -o "${TEMP}/teku.zip" -L --fail "${URL}"
ACTUAL=$(shasum -a 256 "${TEMP}/teku.zip" | cut -d ' ' -f 1)
echo "Formula sha256: ${SHA}, actual sha256: ${ACTUAL}"
[[ "${SHA}" == "${ACTUAL}" ]] || { echo "FAIL: sha256 mismatch"; exit 1; }

echo "OK: ${FORMULA} matches Teku ${VERSION}"
