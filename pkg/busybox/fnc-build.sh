#!/bin/sh

_build() {
	BUSYBOX_VERSION=${BUILD_VERSION:-}
	[ -z "${BUSYBOX_VERSION}" ] && _err "no busybox version defined."

	case "${BUILD_TYPE}" in
		musl)
			_build_musl_busybox
	esac
}

