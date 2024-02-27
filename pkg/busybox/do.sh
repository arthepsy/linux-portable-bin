#!/bin/sh

_NAME="busybox"
_VERSION="1.35.0"  # 2021-12-30
_VERSION="1.36.0"  # 2023-01-03
_VERSION="1.36.1"  # 2023-05-19

_cdir=$(cd -- "$(dirname "$0")" && pwd)
# shellcheck source=/dev/null
. "${_cdir}/../../core/common-do.sh"

_PKGS="make sed musl-dev gcc git patch file"

_pkg_main "$@"

exit 0
