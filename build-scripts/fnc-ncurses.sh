#!/bin/sh

_build_musl_ncurses() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_fetch_and_extract "ncurses" "${NCURSES_VERSION}" "https://ftp.gnu.org/pub/gnu/ncurses/"
	CC='gcc -static' CFLAGS='-fPIC' \
	CXX='g++ -static' CXXFLAGS='-fPIC' \
	./configure --prefix="${_out}" --disable-shared --enable-static || _err "configure"
	make || _err "make"
	make install || _err "make install"
}
