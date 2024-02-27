#!/bin/sh

_requirements() {
	OATH_TOOLKIT_VERSION=${BUILD_VERSION:-}
	[ -z "${OATH_TOOLKIT_VERSION}" ] && _err "no oath-toolkit version defined."
	BUILD_DIR=${BUILD_DIR:-$HOME/work}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		musl)
			export MUSL_ARCH="${BUILD_ARCH}"
			_build_musl_oath_toolkit
	esac
}

_requirements
_build
_done
