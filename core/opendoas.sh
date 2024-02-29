#!/bin/sh

_build_musl_opendoas() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="opendoas-${OPENDOAS_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "opendoas" "${OPENDOAS_VERSION}" "https://github.com/Duncaen/OpenDoas/releases/download/v${OPENDOAS_VERSION}/" "tar.gz"
	_msg "configuring ${_name}"
	CC='/bin/cc -static' CFLAGS='-fPIC' \
	./configure --prefix="${_out}" --without-pam --with-timestamp --enable-static || _err "configure"
	_msg "building ${_name}"
	LDFLAGS="--static" make CC="/bin/cc -static" || _err "make"
	_msg "installing ${_name}"
	mkdir -p "${_out}"
	printf 'permit nopass keepenv setenv { PATH } root as root\n' > "${_out}/doas.conf"
	cp ../sudo "${_out}/sudo"
	chmod a+x "${_out}/sudo"
	cp doas "${_out}/doas"
	ls -al "${_out}/doas"
	file "${_out}/doas"
	exit 0
}

_build_dockcross_manylinux_opendoas() {  # 1 - output
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_name="libxcrypt-${LIBXCRYPT_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "libxcrypt" "${LIBXCRYPT_VERSION}" "https://github.com/besser82/libxcrypt/releases/download/v${LIBXCRYPT_VERSION}/" "tar.xz"
	_msg "configuring ${_name}"
	CFLAGS='-fPIC' \
	./configure || _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_tmp="${BUILD_DIR}/tmp"
	mkdir -p "${_tmp}"
	cp ./.libs/libcrypt.a "${_tmp}" || _err "cp"
	cd -- "${_tmp}" || _err "cannot cd to ${_tmp}"
	ar x libcrypt.a || _err "ar"
	ld -r -o crypt.o *.o || _err "ld"

	cd -- "${BUILD_DIR}" || _err "cannot cd to ${BUILD_DIR}"
	_name="opendoas-${OPENDOAS_VERSION}"
	_msg "downloading ${_name}"
	_fetch_and_extract "opendoas" "${OPENDOAS_VERSION}" "https://github.com/Duncaen/OpenDoas/releases/download/v${OPENDOAS_VERSION}/" "tar.gz"
	_msg "configuring ${_name}"
	CFLAGS='-fPIC' \
	./configure --prefix="${_out}" --without-pam --with-timestamp || _err "configure"
	_msg "patching ${_name}"
	sed -i.bak -e 's#LDLIBS +=	-lcrypt##' config.mk
	diff config.mk.bak config.mk && _err "patch1"
	sed -i.bak -e 's#${CC} ${CFLAGS} $^ -o $@ ${LDFLAGS} ${LDLIBS}#${CC} ${CFLAGS} $^ crypt.o -o $@ ${LDFLAGS} ${LDLIBS}#' GNUmakefile 
	diff GNUmakefile.bak GNUmakefile && _err "patch2"
	cp "${_tmp}/crypt.o" . || _err "cp"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	mkdir -p "${_out}"
	printf 'permit nopass keepenv setenv { PATH } root as root\n' > "${_out}/doas.conf"
	cp ../sudo "${_out}/sudo"
	chmod a+x "${_out}/sudo"
	cp doas "${_out}/doas"
	ls -al "${_out}/doas"
	file "${_out}/doas"
	ldd "${_out}/doas"
	exit 0
}

