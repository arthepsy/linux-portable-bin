#!/bin/sh

# shellcheck disable=SC2120
_build_musl_oath_toolkit() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="oath-toolkit-${OATH_TOOLKIT_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "oath-toolkit" "${OATH_TOOLKIT_VERSION}" "http://download.savannah.nongnu.org/releases/oath-toolkit/"
	_msg "patching1 ${_name}"
	# patch for more recent gcc
	patch -p1 < "../patch-oath-toolkit-2.6.2-gcc7" || _err "failed to patch."
	_msg "configuring ${_name}"
	CC='gcc -static' CFLAGS='-fPIC' \
	./configure --host "${MUSL_ARCH}" --prefix="${_out}" --disable-shared --enable-static || _err "configure"
	# patch to really link statically
	_msg "patching2 ${_name}"
	# shellcheck disable=SC2016
	find ./ -type f -name 'Makefile' -exec sed -i'' 's#CCLD = $(CC)#CCLD = gcc -all-static#g' {} \;
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
	"${_out}/bin/oathtool" -V
}
