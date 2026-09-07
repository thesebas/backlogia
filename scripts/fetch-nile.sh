#!/usr/bin/env bash
# Fetch nile (unofficial Amazon Games client) into vendor/nile.
#
# Upstream cannot be built as a package: its pyproject.toml fails setuptools
# flat-layout discovery (assets/, bin/) and its dynamic version needs git
# tags. This script checks out a pinned tag and applies a two-line packaging
# patch so uv can build it as a path dependency (see pyproject.toml).
#
# Source: https://github.com/imLinguin/nile
# Pin:    tag v1.2.0 = 1ed408ab51709e294034be7b1662288da840ff7f
# Re-pin: update NILE_TAG/NILE_SHA below, rm -rf vendor/nile, re-run this.
set -euo pipefail

NILE_TAG="v1.2.0"
NILE_SHA="1ed408ab51709e294034be7b1662288da840ff7f"
DEST="$(cd "$(dirname "$0")/.." && pwd)/vendor/nile"

if [ -d "$DEST" ]; then
    sha="$(git -C "$DEST" rev-parse HEAD 2>/dev/null || true)"
    if [ "$sha" = "$NILE_SHA" ]; then
        echo "nile already fetched ($NILE_TAG)"
    else
        echo "vendor/nile is at '${sha:-unknown}', expected $NILE_SHA" >&2
        echo "rm -rf vendor/nile and re-run this script to re-fetch" >&2
        exit 1
    fi
else
    git clone --depth 1 --branch "$NILE_TAG" \
        https://github.com/imLinguin/nile.git "$DEST"
    sha="$(git -C "$DEST" rev-parse HEAD)"
    [ "$sha" = "$NILE_SHA" ] || {
        echo "fetched $sha but expected $NILE_SHA" >&2
        exit 1
    }
fi

cd "$DEST"
# Patch 1: static version (setuptools-scm attr import fails in build isolation)
sed -i.bak 's/^dynamic = \["version"\]/version = "1.2.0"/' pyproject.toml
rm -f pyproject.toml.bak
# Patch 2: explicit package discovery (flat layout breaks auto-discovery)
grep -q 'tool.setuptools.packages.find' pyproject.toml || cat >> pyproject.toml <<'EOF'

[tool.setuptools.packages.find]
include = ["nile*"]
EOF
