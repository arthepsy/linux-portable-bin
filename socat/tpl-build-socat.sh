#!/bin/sh
#set -o pipefail

export NCURSES_VERSION="6.2"     # 2020-02-12
export READLINE_VERSION="8.1"    # 2020-12-07
export ZLIB_VERSION="1.2.11"     # 2017-01-15
export OPENSSL_VERSION="1.1.1l"  # 2021-08-23

_requirements() {
	SOCAT_VERSION=${BUILD_VERSION:-}
	[ -z "${SOCAT_VERSION}" ] && _err "no socat version defined."
	SOCAT_OPT=${BUILD_OPT:-}
	for _cmd in sed make perl tar; do
		command -v "${_cmd}" >/dev/null 2>&1 || _err "${_cmd} not available."
	done
	BUILD_DIR=${BUILD_DIR:-$HOME/build}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		musl)
			export MUSL_ARCH="${BUILD_ARCH}"
			_build_musl_ncurses "dep" || _err "ncurses"
			_build_musl_readline "dep" || _err "readline"
			_build_musl_tcp_wrappers "dep" || _err "tcp_wrappers"
			if _has_opt "${SOCAT_OPT}" "ssl" || _has_opt "${SOCAT_OPT}" "weak-ssl"; then
				_build_musl_zlib "dep" || _err "zlib"
				export OPENSSL_OPT=${OPENSSL_OPT:-zlib}
				_build_musl_openssl "dep" || _err "openssl"
			fi
			_build_musl_socat || _err "socat"
			;;
		*) _err "unknown build type: ${BUILD_TYPE}" ;;
	esac
}

_requirements
_build
_done
