#!/bin/sh

_requirements() {
	GRAFTCP_VERSION=${BUILD_VERSION:-}
	[ -z "${GRAFTCP_VERSION}" ] && _err "no graftcp version defined."
	BUILD_DIR=${BUILD_DIR:-$HOME/work}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		musl)
			export MUSL_ARCH="${BUILD_ARCH}"
			_build_musl_graftcp
	esac
}

_requirements
_build
_done
