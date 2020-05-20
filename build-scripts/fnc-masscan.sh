#!/bin/sh

# shellcheck disable=SC2120
_build_glibc_masscan() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	command -v git >/dev/null 2>&1 || _err "git not available."
	_cd "${BUILD_DIR}"
	if [ "${MASSCAN_VERSION}" = "head" ]; then
		git clone --depth=1 "https://github.com/robertdavidgraham/masscan.git" "masscan-head" || _err "git"
		_cd "masscan-head"
        else
		git clone -b "${MASSCAN_VERSION}" --single-branch --depth=1 "https://github.com/robertdavidgraham/masscan.git" "masscan-${MASSCAN_VERSION}" || _err "git"
		_cd "masscan-${MASSCAN_VERSION}"
        fi
	# NOTE: load libpcap (masscan.pcap.so) from current directory
	find ./ -type f -name '*.c' -exec sed -i'' 's#"libpcap.so",#"./masscan.pcap.so","libpcap.so",#g' {} \;
	# NOTE: headers for older glibc
        case "${BUILD_ARCH}" in
                *x86) _arch="x86" ;;
                *x64) _arch="x64" ;;
                *) _err "unknown arch: ${BUILD_ARCH}" ;;
        esac
        cat "../patch-link_glibc_2.5.${_arch}.h" > "fix-glibc.h" || _err "missing link_glibc_2.5.h"
	# NOTE: fix CPU_COUNT reference (available since glibc 2.6)
	sed -i'' 's# CPU_COUNT# OLDGLIBC_CPU_COUNT#g' "./src/pixie-threads.c" || _err "sed"
	_tmp="tmp.$$"
	printf '#define _GNU_SOURCE\n#include "oldglibc_cpucount.h"\n' > "${_tmp}"
	tail -n +2 "./src/pixie-threads.c" >> "${_tmp}"
	mv "${_tmp}" "./src/pixie-threads.c"
	cat "../patch-oldglibc_cpucount.h" > "./src/oldglibc_cpucount.h" || _err "missing oldglibc_cpucount.h"
	make CC="$CC" CFLAGS="-include fix-glibc.h" || _err "make"
	strip --strip-all "./bin/masscan" 2>/dev/null >/dev/null
	objdump -T "./bin/masscan" | grep GLIBC
	objdump -T "./bin/masscan" | grep GLIBC | awk '{ print $5 }' | sort -u
	mkdir -p "${_out}/bin" || _err "mkdir"
	chmod 755 "./bin/masscan"
	cp "./bin/masscan" "${_out}/bin/masscan" || _err "cp"
}

