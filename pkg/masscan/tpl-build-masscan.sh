#!/bin/sh

export LIBPCAP_VERSION="1.10.1"  # 20201-06-09
#export LIBPCAP_VERSION="1.10.0"  # 2020-12-29
#export LIBPCAP_VERSION="1.9.1"   # 2019-09-03

_requirements() {
	MASSCAN_VERSION=${BUILD_VERSION:-}
	[ -z "${MASSCAN_VERSION}" ] && _err "no masscan version defined."
	#MASSCAP_OPT=${BUILD_OPT:-}
	for _cmd in sed make; do
		command -v "${_cmd}" >/dev/null 2>&1 || _err "${_cmd} not available."
	done
	BUILD_DIR=${BUILD_DIR:-$HOME/work}
	mkdir -p -- "${BUILD_DIR}/dep" "${BUILD_DIR}/out"
}

_build() {
	case "${BUILD_TYPE}" in
		dockcross)
			_build_glibc_libpcap "dep"
			_build_glibc_masscan
			cp "${BUILD_DIR}/dep/lib/libpcap.so" "${BUILD_DIR}/out/bin/masscan.pcap.so"
			;;
		*) _err "unknown build type: ${BUILD_TYPE}" ;;
	esac
}

_requirements
_build
_done

