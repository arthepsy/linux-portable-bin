#!/bin/sh

export GOLANG_VERSION="1.19.5"  # 2022-08-02

_requirements() {
	GO_GRAFT_VERSION=${BUILD_VERSION:-}
	[ -z "${GO_GRAFT_VERSION}" ] && _err "no go-graft version defined."
	BUILD_DIR=${BUILD_DIR:-$HOME/work}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		musl*)
			export MUSL_ARCH="${BUILD_ARCH}"
			_build_musl_go_graft
	esac
}

_requirements
_build
_done
