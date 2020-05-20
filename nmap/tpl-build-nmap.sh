#!/bin/sh

export ZLIB_VERSION="1.2.11"     # 2017-01-15
export OPENSSL_VERSION="1.1.1g"  # 2020-03-31

_requirements() {
	NMAP_VERSION=${BUILD_VERSION:-}
	[ -z "${NMAP_VERSION}" ] && _err "no nmap version defined."
	NMAP_OPT=${BUILD_OPT:-}
	for _cmd in sed make; do
		command -v "${_cmd}" >/dev/null 2>&1 || _err "${_cmd} not available."
	done
	# TODO: flex/bison (nmap 7.80)
	BUILD_DIR=${BUILD_DIR:-$HOME/build}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		musl)
			export MUSL_ARCH="${BUILD_ARCH}"
			_build_musl_zlib "dep"
			if _has_opt "${NMAP_OPT}" "bad-ssl"; then
				export OPENSSL_VERSION="1.0.2-bad"
			fi
			if _has_opt "${NMAP_OPT}" "weak-ssl"; then
				export OPENSSL_OPT="zlib weak-ssl"
			else
				export OPENSSL_OPT="zlib"
			fi
			_build_musl_openssl "dep"
			_build_musl_nmap
			;;
		*) _err "unknown build type: ${BUILD_TYPE}" ;;
	esac
}

_requirements
_build
_done

