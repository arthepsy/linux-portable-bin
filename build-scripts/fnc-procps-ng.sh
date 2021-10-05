#!/bin/sh

# shellcheck disable=SC2120
_build_musl_procps_ng() {  # 1 - output, 2 - dependencies
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_dep="dep"; [ -n "$2" ] && _dep="$2"; _dep="${BUILD_DIR}/${_dep}"
	_name="procps-ng-${PROCPS_NG_VERSION}"
        _cd "${BUILD_DIR}"
	_msg "downloading ${_name}"
        if [ "${PROCPS_NG_VERSION}" = "head" ]; then
                git clone --depth=1 "https://gitlab.com/procps-ng/procps" "procps-ng-head" || _err "git"
                _cd "procps-ng-head"
        else
                git clone --depth=1 --branch "v${PROCPS_NG_VERSION}" "https://gitlab.com/procps-ng/procps" "procps-ng-v${PROCPS_NG_VERSION}" || _err "git"
                _cd "procps-ng-v${PROCPS_NG_VERSION}"
        fi
	_msg "autogen ${_name}"
	./autogen.sh || _err "autogen"
	_msg "configuring ${_name}"
        CC='gcc -static' CFLAGS='-fPIC' \
        CPPFLAGS="-I${_dep}/include -I${_dep}/include/ncurses" \
        LDFLAGS="--static -L${_dep}/lib" \
	./configure --host "${MUSL_ARCH}" --prefix="${_out}" --disable-shared --enable-static || _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
	"${_out}/bin/ps" -V
}
