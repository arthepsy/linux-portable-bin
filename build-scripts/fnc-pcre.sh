#!/bin/sh

_build_musl_pcre() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="pcre-${PCRE_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "pcre" "${PCRE_VERSION}" "https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/" "tar.bz2"
	_msg "configuring ${_name}"
	./configure \
		--prefix="${_out}" \
		--host="$(_get_configure_host)" \
		--enable-unicode-properties \
		--enable-pcre16 \
		--enable-pcre32 \
		CC="/bin/cc -static" \
		CFLAGS="-fPIC" \
		|| _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
}
