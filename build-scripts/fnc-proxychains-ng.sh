#!/bin/sh

# shellcheck disable=SC2120
_build_glibc_proxychains_ng() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	command -v git >/dev/null 2>&1 || _err "git not available."
	_cd "${BUILD_DIR}"
	if [ "${PROXYCHAINS_NG_VERSION}" = "head" ]; then
		git clone --depth=1 "https://github.com/rofl0r/proxychains-ng.git" "proxychains-ng-head" || _err "git"
		_cd "proxychains-ng-head"
	else
		git clone --depth=1 --branch "v${PROXYCHAINS_NG_VERSION}" "https://github.com/rofl0r/proxychains-ng.git" "proxychains-v${PROXYCHAINS_NG_VERSION}" || _err "git"
		_cd "proxychains-v${PROXYCHAINS_NG_VERSION}"
	fi
	# NOTE: headers for older glibc
	case "${BUILD_ARCH}" in
		*x86) _arch="x86" ;;
		*x64) _arch="x64" ;;
		*) _err "unknown arch: ${BUILD_ARCH}" ;;
	esac
	_fn="../patch-link_glibc_2.9.${_arch}.h"
	cat "${_fn}" > "fix-glibc.h" || _err "missing ${_fn}" 
	./configure \
		--prefix="${_out}" \
		--ignore-cve || _err "configure"
	make USER_CFLAGS="-include fix-glibc.h" || _err "make"
	make install || _err "make install"
	cp "./src/proxychains.conf" "${_out}"
	for _dir in "${_out}/bin" "${_out}/lib"; do
		find "${_dir}" -type f -exec sh -c '
			echo "$1"
			strip --strip-all "$1" 2>/dev/null >/dev/null
			file "$1"
			objdump -T "$1" | grep GLIBC | awk "{ print $2 }" | sort -u
		' sh {} '$5' \;
	done
}
