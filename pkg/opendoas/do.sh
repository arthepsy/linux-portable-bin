#!/bin/sh

_NAME="opendoas"
_VERSION="6.8.2"  # 2022-01-26

_cdir=$(cd -- "$(dirname "$0")" && pwd)
# shellcheck source=/dev/null
. "${_cdir}/../../core/common-do.sh"

_PKGS="make bison file"

_pkg_main "$@"

exit 0
