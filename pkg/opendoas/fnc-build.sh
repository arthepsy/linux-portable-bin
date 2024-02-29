#!/bin/sh

_build() {
	OPENDOAS_VERSION=${BUILD_VERSION:-}
	[ -z "${OPENDOAS_VERSION}" ] && _err "no opendoas version defined."

	case "${BUILD_TYPE}" in
		musl) 
			_build_musl_opendoas ;;
		dockcross-manylinux*)
			LIBXCRYPT_VERSION="4.4.36"  # 2023-07-05
			_build_dockcross_manylinux_opendoas ;;
	esac
}

