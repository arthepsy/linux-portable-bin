#!/bin/sh

_build_musl_libcap() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="libcap-${LIBCAP_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "libcap" "${LIBCAP_VERSION}" "https://mirrors.edge.kernel.org/pub/linux/libs/security/linux-privs/libcap2/" "tar.gz"
	_msg "building ${_name}"
	make \
		BUILD_CC="/usr/bin/cc" \
		CC="/bin/cc -static" \
		CFLAGS="-fPIC" \
		prefix="${_out}" \
		LIBDIR="${_out}/lib" \
		|| _err "make"
	_msg "installing ${_name}"
	make \
		BUILD_CC="/usr/bin/cc" \
		CC="/bin/cc -static" \
		CFLAGS="-fPIC" \
		prefix="${_out}" \
		LIBDIR="${_out}/lib" \
		install \
		|| _err "make install"
}
