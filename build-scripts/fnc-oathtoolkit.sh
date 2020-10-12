#!/bin/sh

# shellcheck disable=SC2120
_build_musl_oath_toolkit() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_fetch_and_extract "oath-toolkit" "${OATH_TOOLKIT_VERSION}" "http://download.savannah.nongnu.org/releases/oath-toolkit/"
	# patch for more recent gcc
	patch -p1 < "../patch-oath-toolkit-2.6.2-gcc7" || _err "failed to patch."
	CC='gcc -static' CFLAGS='-fPIC' \
	./configure --host "${MUSL_ARCH}" --prefix="${_out}" --disable-shared --enable-static || _err "configure"
	# patch to really link statically
	# shellcheck disable=SC2016
	find ./ -type f -name 'Makefile' -exec sed -i'' 's#CCLD = $(CC)#CCLD = gcc -all-static#g' {} \;
	make || _err "make"
	make install || _err "make install"
	"${_out}/bin/oathtool" -V
}
