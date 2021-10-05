#!/bin/sh

_build_musl_readline() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="readline-${READLINE_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "readline" "${READLINE_VERSION}" "https://ftp.gnu.org/pub/gnu/readline/"
	_msg "configuring ${_name}"
	CC='gcc -static' CFLAGS='-fPIC' \
	CPPFLAGS="-I${BUILD_DIR}/dep/include" \
	LDFLAGS="-L${BUILD_DIR}/dep/lib" \
	./configure --host "${MUSL_ARCH}" --prefix="${_out}" --disable-shared --enable-static || _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
}
