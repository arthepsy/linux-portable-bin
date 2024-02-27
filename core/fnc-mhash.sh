#!/bin/sh

_build_musl_mhash() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="mhash-${MHASH_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "mhash" "${MHASH_VERSION}" "https://sourceforge.net/projects/mhash/files/mhash/${MHASH_VERSION}/" "tar.bz2"
	_msg "configuring ${_name}"
	ac_cv_func_malloc_0_nonnull=yes ./configure \
		--prefix="${_out}" \
		--host="$(_get_configure_host)" \
		--disable-shared \
		--enable-static \
		--with-gnu-ld \
		CC="/bin/cc -static" \
		CFLAGS="-fPIC" \
		|| _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "patch ${_name}"
	sed -i'' 's#define VERSION #define mhash_VERSION #g' "./include/mutils/mhash_config.h" || _err "sed"
	_msg "installing ${_name}"
	make install || _err "make install"
}
