#!/bin/sh

_build_musl_attr() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="attr-${ATTR_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "attr" "${ATTR_VERSION}" "http://download.savannah.nongnu.org/releases/attr/" "tar.gz"
	_msg "configuring ${_name}"
	./configure \
		--prefix="${_out}" \
		--host="$(_get_configure_host)" \
		--disable-shared \
		--enable-static \
		CC="/bin/cc -static" \
		CFLAGS="-fPIC" \
		|| _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
}
