#!/bin/sh
#set -o pipefail

export ZLIB_VERSION="1.2.11"  # 2017-01-15

_requirements() {
	OPENSSL_VERSION=${BUILD_VERSION:-}
	[ -z "${OPENSSL_VERSION}" ] && _err "no openssl version defined."
	OPENSSL_OPT=${BUILD_OPT:-}
	for _cmd in sed make perl; do
		command -v "${_cmd}" >/dev/null 2>&1 || _err "${_cmd} not available."
	done
	BUILD_DIR=${BUILD_DIR:-$HOME/build}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}


_build() {
	case "${BUILD_TYPE}" in
		musl)
			export MUSL_ARCH="${BUILD_ARCH}"
			if _has_opt "${OPENSSL_OPT}" "zlib"; then
				_build_musl_zlib "dep"
			fi
			_build_musl_openssl
			;;
		*) _err "unknown build type: ${BUILD_TYPE}" ;;
	esac
}

_requirements
_build
_done

