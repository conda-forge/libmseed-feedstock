#!/bin/bash
set -euxo pipefail

# Upstream's libmseed.map only exports "lmp_systemtime" from the lmp_*
# group, but lmp_fseek64/lmp_ftell64/lmp_nanosleep/lmp_strncasecmp are also
# public API (declared extern in libmseed.h) and used directly by consumers
# like EarthScope's dataselect. Broaden the pattern to match, consistent
# with how every other symbol group in the map is wildcarded.
# -i.bak (with suffix) is used because BSD sed (macOS) requires an argument
# after -i, while GNU sed (Linux) accepts either form.
sed -i.bak 's/lmp_systemtime;/lmp_*;/' libmseed.map
rm -f libmseed.map.bak

# conda-forge's default Linux LDFLAGS include -Wl,--as-needed. Upstream's
# top-level Makefile places LDLIBS (-lcurl, from curl-config) *before* the
# object files on the shared-library link line, so --as-needed drops
# libcurl entirely: nothing "needs" it yet at that point in the command.
# That leaves curl_multi_fdset and friends (used internally for URL-based
# reads) unresolved at runtime. Force libcurl to stay linked regardless of
# link-line order. macOS's ld64 doesn't have this flag (or the underlying
# --as-needed behavior), so only apply this on Linux.
if [[ "$(uname -s)" == "Linux" ]]; then
  export LDFLAGS="${LDFLAGS} -Wl,--no-as-needed"
fi

# Build shared library with URL support (requires libcurl)
make shared CFLAGS="${CFLAGS} -DLIBMSEED_URL"
make install PREFIX="${PREFIX}"

# Upstream's install target only ships libmseed.h, but mseedformat.h is a
# public header too (used directly by e.g. EarthScope's dataselect).
cp mseedformat.h "${PREFIX}/include/"
