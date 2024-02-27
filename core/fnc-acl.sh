#!/bin/sh

_build_musl_acl() {  # 1 - output, 2 - dependencies
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_dep="dep"; [ -n "$2" ] && _dep="$2"; _dep="${BUILD_DIR}/${_dep}"
	_name="acl-${ACL_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "acl" "${ACL_VERSION}" "http://download.savannah.nongnu.org/releases/acl/" "tar.gz"
	_msg "configuring ${_name}"
	./configure \
		--prefix="${_out}" \
		--host="$(_get_configure_host)" \
		--disable-shared \
		--enable-static \
		CC="/bin/cc -static" \
		CFLAGS="-fPIC -I${_dep}/include" \
		LDFLAGS="-L${_dep}/lib" \
		|| _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
}
