#!/bin/sh

_build_musl_opendoas() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="opendoas-${OPENDOAS_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "opendoas" "${OPENDOAS_VERSION}" "https://github.com/Duncaen/OpenDoas/releases/download/v${OPENDOAS_VERSION}/" "tar.gz"
	_msg "configuring ${_name}"
	CC='/bin/cc -static' CFLAGS='-fPIC' \
	./configure --prefix="${_out}" --without-pam --with-timestamp --enable-static
	_msg "building ${_name}"
	LDFLAGS="--static" make CC="/bin/cc -static" || _err "make"
	_msg "installing ${_name}"
	mkdir -p "${_out}"
	printf 'permit nopass keepenv setenv { PATH } root as root\n' > "${_out}/doas.conf"
	cp ../sudo "${_out}/sudo"
	chmod a+x "${_out}/sudo"
	cp doas "${_out}/doas"
        file "${_out}/doas"
        ls -al "${_out}/doas"
	exit 0
}
