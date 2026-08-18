#!/bin/bash
set -euxo pipefail

# Build shared library with URL support (requires libcurl)
make shared CFLAGS="${CFLAGS} -DLIBMSEED_URL"
make install PREFIX="${PREFIX}"

# Upstream's install target only ships libmseed.h, but mseedformat.h is a
# public header too (used directly by e.g. EarthScope's dataselect).
cp mseedformat.h "${PREFIX}/include/"
