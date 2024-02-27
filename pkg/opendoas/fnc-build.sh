#!/bin/sh

_build() {
	OPENDOAS_VERSION=${BUILD_VERSION:-}
	[ -z "${OPENDOAS_VERSION}" ] && _err "no opendoas version defined."

	case "${BUILD_TYPE}" in
		musl)
			_build_musl_opendoas
	esac
}

