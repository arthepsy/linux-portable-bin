#!/bin/sh

# shellcheck disable=SC2120
_build_musl_procps_ng() {  # 1 - output, 2 - dependencies
	_out="out"; [ -n "$1" ] && _out="$1"; _out="${BUILD_DIR}/${_out}"
	_dep="dep"; [ -n "$2" ] && _dep="$2"; _dep="${BUILD_DIR}/${_dep}"
	_name="procps-ng-${PROCPS_NG_VERSION}"
	case "${PROCPS_NG_VERSION}" in
		4.0.*|head)
			_msg "upgrade musl (qsort_* since musl-1.2.2-r7)"
			if grep -q '/v3.14/' /etc/apk/repositories; then
				echo 'https://dl-cdn.alpinelinux.org/alpine/v3.15/main' > /etc/apk/repositories
				echo 'https://dl-cdn.alpinelinux.org/alpine/v3.15/community' >> /etc/apk/repositories
				apk upgrade musl
			fi
			;;
		*) ;;
	esac
        _cd "${BUILD_DIR}"
	_msg "downloading ${_name}"
        if [ "${PROCPS_NG_VERSION}" = "head" ]; then
                git clone --depth=1 "https://gitlab.com/procps-ng/procps" "procps-ng-head" || _err "git"
                _cd "procps-ng-head"
        else
                git clone --depth=1 --branch "v${PROCPS_NG_VERSION}" "https://gitlab.com/procps-ng/procps" "procps-ng-v${PROCPS_NG_VERSION}" || _err "git"
                _cd "procps-ng-v${PROCPS_NG_VERSION}"
        fi
	case "${PROCPS_NG_VERSION}" in
		3.3.17)
			_msg "patching ${_name}"
			patch -p0 < "../patch-v3.3.17-w.c" || _err "failed to patch."
			;;
		4.0.0)
			_msg "patching ${_name}"
			patch -p0 < "../patch-v4.0.0-w.c" || _err "failed to patch."
			;;
		4.0.1|4.0.2|head)
			_msg "patching ${_name}"
			_cd src
			patch -p0 < "../../patch-v4.0.0-w.c" || _err "failed to patch."
			_cd ..
			;;
		*) ;;
	esac
	_msg "autogen ${_name}"
	./autogen.sh || _err "autogen"
	_msg "configuring ${_name}"
        CC='/bin/cc -static' CFLAGS='-fPIC' \
        CPPFLAGS="-I${_dep}/include -I${_dep}/include/ncurses" \
        LDFLAGS="--static -L${_dep}/lib" \
	PKG_CONFIG_PATH="${_dep}/lib/pkgconfig" \
	./configure --host "${MUSL_ARCH}" --prefix="${_out}" --disable-shared --enable-static || _err "configure"
	_msg "building ${_name}"
	make || _err "make"
	_msg "installing ${_name}"
	make install || _err "make install"
	file "${_out}/bin/ps"
	"${_out}/bin/ps" -V
}
