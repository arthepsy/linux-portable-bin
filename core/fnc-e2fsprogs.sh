#!/bin/sh

_build_musl_e2fsprogs() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="e2fsprogs-${E2FSPROGS_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "e2fsprogs" "${E2FSPROGS_VERSION}" "https://sourceforge.net/projects/e2fsprogs/files/e2fsprogs/v${E2FSPROGS_VERSION}/" "tar.gz"
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
	_msg "pre-install-fix ${_name}"
	mkdir -p ${_out}/etc
	mkdir -p ${_out}/bin
	mkdir -p ${_out}/sbin
	mkdir -p ${_out}/lib
	mkdir -p ${_out}/lib/et
	mkdir -p ${_out}/lib/pkgconfig
	mkdir -p ${_out}/include/et
	mkdir -p ${_out}/include/ss
	mkdir -p ${_out}/include/e2p
	mkdir -p ${_out}/include/uuid
	mkdir -p ${_out}/include/blkid
	mkdir -p ${_out}/include/ext2fs
	mkdir -p ${_out}/share/et
	mkdir -p ${_out}/share/ss
	mkdir -p ${_out}/share/man/man1
	mkdir -p ${_out}/share/man/man3
	mkdir -p ${_out}/share/man/man5
	mkdir -p ${_out}/share/man/man8
	_msg "installing ${_name}"
	make install || _err "make install"
}
