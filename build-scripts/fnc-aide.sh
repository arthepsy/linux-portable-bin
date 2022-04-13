#!/bin/sh

# shellcheck disable=SC2120
_build_musl_aide() {  # 1 - output, 2 - dependencies
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_dep="dep"; [ -n "$2" ] && _dep="$2"; _dep="${BUILD_DIR}/${_dep}"
	_name="aide-${AIDE_VERSION}"
        _cd "${BUILD_DIR}"
	_msg "downloading ${_name}"
        if [ "${AIDE_VERSION}" = "head" ]; then
                git clone --depth=1 "https://github/aide/aide" "aide-head" || _err "git"
                _cd "aide-head"
        else
		_fetch_and_extract "aide" "${AIDE_VERSION}" "https://github.com/aide/aide/releases/download/v${AIDE_VERSION}/" "tar.gz"
        fi
	_msg "configuring ${_name}"
	./configure \
		--prefix="${_out}" \
		--host="$(_get_configure_host)" \
		--disable-shared \
		--enable-static \
		--sysconfdir=/etc/aide \
		--with-posix-acl \
		--with-xattr \
		--with-capabilities \
		--with-e2fsattrs \
		CC="/bin/cc -static" \
		CFLAGS="-fPIC -I/${_dep}/include" \
		LDFLAGS="-L/${_dep}/lib" \
		|| _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
	"${_out}/bin/aide" -v
}
