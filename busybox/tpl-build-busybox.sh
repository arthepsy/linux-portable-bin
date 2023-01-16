#!/bin/sh

_requirements() {
	BUSYBOX_VERSION=${BUILD_VERSION:-}
	[ -z "${BUSYBOX_VERSION}" ] && _err "no busybox version defined."
	BUILD_DIR=${BUILD_DIR:-$HOME/work}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		musl)
			_build_musl_busybox
	esac
}

_requirements
_build
_done
