#!/bin/sh

# shellcheck disable=SC2120
_build_glibc_libpcap() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_fetch_and_extract "libpcap" "${LIBPCAP_VERSION}" "https://www.tcpdump.org/release/"
	case "${LIBPCAP_VERSION}" in
		1.9.*)
			find ./ -type f -name '*.c' -exec sed -i'' 's#sscanf(#oldglibc_sscanf(#g' {} \;
			find ./ -type f -name '*.c' -exec sed -i'' 's#fscanf(#oldglibc_fscanf(#g' {} \;
			;;
		*) ;;
	esac
	case "${BUILD_ARCH}" in
		*x86) _arch="x86" ;;
		*x64) _arch="x64" ;;
		*) _err "unknown arch: ${BUILD_ARCH}" ;;
	esac
	case "${LIBPCAP_VERSION}" in
		1.9.*)
			cp "../patch-fix-glibc.${_arch}.h" "fix-glibc.h" || _err "missing fix-glibc.h"
			cat "../patch-link_glibc_2.5.${_arch}.h" >> "fix-glibc.h" || _err "missing link_glibc_2.5.h"
			;;
		*)
			touch "fix-glibc.h"
			cat "../patch-link_glibc_2.7.${_arch}.h" >> "fix-glibc.h" || _err "missing link_glibc_2.7.h"
			;;
	esac
	./configure --prefix="${_out}" || _err "configure"
	make CFLAGS="-D_GNU_SOURCE --include fix-glibc.h" || _err "make"
	make install || _err "make install"
	strip --strip-all "${_out}/lib/libpcap.so" 2>/dev/null >/dev/null
	objdump -T "${_out}/lib/libpcap.so" | grep GLIBC
	objdump -T "${_out}/lib/libpcap.so" | grep GLIBC | awk '{ print $5 }' | sort -u
}
