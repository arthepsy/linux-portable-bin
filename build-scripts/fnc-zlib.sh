#!/bin/sh

_build_musl_zlib() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="zlib-${ZLIB_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "zlib" "${ZLIB_VERSION}" "https://www.zlib.net/"
	_msg "configuring ${_name}"
	CC='gcc -static' CFLAGS='-fPIC' \
	./configure --prefix="${_out}" --static || _err "configure"
	_msg "building ${_name}"
	make libz.a || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
}
