#!/bin/sh

_NAME="opendoas"
_VERSION="6.8.2"  # 2022-01-26

_OPTS="static|shared"

_cdir=$(cd -- "$(dirname "$0")" && pwd)
# shellcheck source=/dev/null
. "${_cdir}/../../core/common-do.sh"

_PKGS="make bison file"

_pkg_post_opts() {
	_OPT="${_OPT:-static}"
	if [ "${_OPT}" = "shared" ]; then
		_BACKEND="dockcross-manylinux2014"
		_PKGS="${_PKGS} byacc"
	fi
}

_pkg_main "$@"

exit 0
