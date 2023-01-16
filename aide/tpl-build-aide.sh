#!/bin/sh

export PCRE_VERSION="8.45"         # 2021-06-15
export MHASH_VERSION="0.9.9.9"     # 2008-12-08
export ACL_VERSION="2.3.1"         # 2021-03-16
export ATTR_VERSION="2.5.1"        # 2021-03-16
export E2FSPROGS_VERSION="1.46.5"  # 2021-12-30
export LIBCAP_VERSION="2.66"       # 2022-09-24
export ZLIB_VERSION="1.2.13"       # 2022-10-14

_requirements() {
	AIDE_VERSION=${BUILD_VERSION:-}
	[ -z "${AIDE_VERSION}" ] && _err "no aide version defined."
	BUILD_DIR=${BUILD_DIR:-$HOME/work}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		musl)
			export MUSL_ARCH="${BUILD_ARCH}"
			_build_musl_pcre "dep" || _err "pcre"
			_build_musl_mhash "dep" || _err "mhash"
			_build_musl_attr "dep" || _err "atr"
			_build_musl_acl "dep" "dep" || _err "acl"
			_build_musl_e2fsprogs "dep" || _err "e2fsprogs"
			_build_musl_libcap "dep" || _err "libcap"
			_build_musl_zlib "dep" || _err "zlib"
			_build_musl_aide "out" 
	esac
}

_requirements
_build
_done
