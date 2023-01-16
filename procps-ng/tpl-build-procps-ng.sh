#!/bin/sh

export NCURSES_VERSION="6.4"     # 2022-12-31

_requirements() {
	PROCPS_NG_VERSION=${BUILD_VERSION:-}
	[ -z "${PROCPS_NG_VERSION}" ] && _err "no procps-ng version defined."
	BUILD_DIR=${BUILD_DIR:-$HOME/work}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		musl)
			export MUSL_ARCH="${BUILD_ARCH}"
			_build_musl_ncurses "dep" || _err "ncurses"
			_build_musl_procps_ng
	esac
}

_requirements
_build
_done
