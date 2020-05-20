#!/bin/sh

_build_musl_zlib() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_fetch_and_extract "zlib" "${ZLIB_VERSION}" "https://www.zlib.net/"
	CC='gcc -static' CFLAGS='-fPIC' \
	./configure --prefix="${_out}" --static || _err "configure"
	make libz.a || _err "make"
	make install || _err "make install"
}
