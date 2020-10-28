#!/bin/sh

_requirements() {
	PROXYCHAINS_NG_VERSION=${BUILD_VERSION:-}
	[ -z "${PROXYCHAINS_NG_VERSION}" ] && _err "no proxychains-n version defined."
	BUILD_DIR=${BUILD_DIR:-$HOME/work}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		dockcross)
			_build_glibc_proxychains_ng
	esac
}

_requirements
_build
_done
